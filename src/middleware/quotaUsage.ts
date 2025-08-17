import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { logger } from '../utils/logger';
import { SubscriptionService } from '../services/subscriptionService';
import { MarketplaceMeteringClient, UsageEvent } from '../marketplace/meteringClient';
import { AuditLogger } from '../utils/auditLogger';
import { TurnContext } from 'botbuilder';
import { getErrorMessage } from '../utils/errorHandler';

export interface QuotaMiddlewareOptions {
  enabled?: boolean;
  skipPaths?: string[];
  dimension?: string;
  includedQuotaPerMonth?: number;
  overageEnabled?: boolean;
}

export interface QuotaInfo {
  subscriptionId: string;
  tenantId: string;
  userId: string;
  remainingQuota: number;
  totalQuota: number;
  overageEnabled: boolean;
  resetDate: Date;
}

declare global {
  namespace Express {
    interface Request {
      quotaInfo?: QuotaInfo;
      requestId?: string;
    }
  }
}

export class QuotaUsageMiddleware {
  private subscriptionService: SubscriptionService;
  private meteringClient: MarketplaceMeteringClient;
  private auditLogger: AuditLogger;
  private options: Required<QuotaMiddlewareOptions>;

  constructor(options: QuotaMiddlewareOptions = {}) {
    this.subscriptionService = new SubscriptionService();
    this.meteringClient = new MarketplaceMeteringClient();
    this.auditLogger = new AuditLogger();
    
    this.options = {
      enabled: options.enabled ?? true,
      skipPaths: options.skipPaths ?? [],
      dimension: options.dimension ?? process.env.DIMENSION_NAME ?? 'question',
      includedQuotaPerMonth: options.includedQuotaPerMonth ?? parseInt(process.env.INCLUDED_QUOTA_PER_MONTH || '300'),
      overageEnabled: options.overageEnabled ?? (process.env.OVERAGE_ENABLED === 'true')
    };
  }

  /**
   * Express middleware for quota enforcement and usage tracking
   */
  middleware() {
    return async (req: Request, res: Response, next: NextFunction) => {
      // Skip if middleware is disabled
      if (!this.options.enabled) {
        return next();
      }

      // Skip certain paths
      if (this.options.skipPaths.some(path => req.path.startsWith(path))) {
        return next();
      }

      // Only process bot message endpoints that trigger AI questions
      if (!this.isQuestionEndpoint(req)) {
        return next();
      }

      const requestId = req.requestId || uuidv4();
      req.requestId = requestId;

      try {
        // Extract subscription and user information
        const quotaInfo = await this.extractQuotaInfo(req);
        if (!quotaInfo) {
          logger.warn('Unable to extract quota information', { requestId, path: req.path });
          return this.sendQuotaError(res, 'Unable to determine subscription information', 400);
        }

        req.quotaInfo = quotaInfo;

        // Check quota before processing
        const quotaCheck = await this.checkQuota(quotaInfo);
        if (!quotaCheck.allowed) {
          await this.auditLogger.log({
            action: 'quota.blocked',
            tenantId: quotaInfo.tenantId,
            userId: quotaInfo.userId,
            subscriptionId: quotaInfo.subscriptionId,
            requestId,
            result: 'blocked',
            details: {
              remainingQuota: quotaInfo.remainingQuota,
              reason: quotaCheck.reason || 'Quota exceeded'
            }
          });

          return this.sendQuotaExceededResponse(res, quotaInfo, quotaCheck.reason || 'Quota exceeded');
        }

        // Set quota headers
        this.setQuotaHeaders(res, quotaInfo);

        // Wrap the response to track successful completion
        this.wrapResponse(req, res, next);

      } catch (error) {
        logger.error('Error in quota middleware', { error: getErrorMessage(error), requestId });
        
        await this.auditLogger.log({
          action: 'quota.error',
          requestId,
          result: 'error',
          details: { error: getErrorMessage(error) }
        });

        // Continue processing even if quota check fails (fail open)
        next();
      }
    };
  }

  /**
   * Middleware specifically for Teams bot context
   */
  async processTeamsBotQuota(context: TurnContext): Promise<boolean> {
    if (!this.options.enabled) {
      return true;
    }

    const requestId = uuidv4();

    try {
      // Extract quota info from Teams context
      const quotaInfo = await this.extractQuotaInfoFromTeamsContext(context);
      if (!quotaInfo) {
        logger.warn('Unable to extract quota information from Teams context', { requestId });
        return true; // Fail open
      }

      // Check quota
      const quotaCheck = await this.checkQuota(quotaInfo);
      if (!quotaCheck.allowed) {
        await this.auditLogger.log({
          action: 'quota.blocked.teams',
          tenantId: quotaInfo.tenantId,
          userId: quotaInfo.userId,
          subscriptionId: quotaInfo.subscriptionId,
          requestId,
          result: 'blocked',
          details: {
            remainingQuota: quotaInfo.remainingQuota,
            reason: quotaCheck.reason || 'Quota exceeded'
          }
        });

        // Send quota exceeded message to user
        await context.sendActivity(this.getQuotaExceededMessage(quotaInfo));
        return false;
      }

      // If quota check passes, publish usage event after successful AI response
      setTimeout(async () => {
        try {
          await this.publishUsageEvent(quotaInfo, requestId);
        } catch (error) {
          logger.error('Failed to publish usage event for Teams bot', { error: getErrorMessage(error), requestId });
        }
      }, 0);

      return true;

    } catch (error) {
      logger.error('Error in Teams bot quota processing', { error: getErrorMessage(error), requestId });
      return true; // Fail open
    }
  }

  private async extractQuotaInfo(req: Request): Promise<QuotaInfo | null> {
    try {
      // Extract subscription ID from APIM header
      const subscriptionId = req.headers['x-apim-subscription-id'] as string;
      if (!subscriptionId) {
        return null;
      }

      // Get subscription from database
      const subscription = await this.subscriptionService.getByMarketplaceId(subscriptionId);
      if (!subscription) {
        return null;
      }

      // Extract user and tenant info
      const tenantId = subscription.tenantId;
      const userId = this.extractUserId(req);

      // Calculate remaining quota
      const currentMonth = new Date();
      currentMonth.setDate(1);
      currentMonth.setHours(0, 0, 0, 0);
      
      const nextMonth = new Date(currentMonth);
      nextMonth.setMonth(nextMonth.getMonth() + 1);

      const usageThisMonth = await this.subscriptionService.getUsageForPeriod(
        subscription.id,
        currentMonth,
        nextMonth
      );

      const remainingQuota = Math.max(0, subscription.quantityIncluded - usageThisMonth);

      return {
        subscriptionId: subscription.marketplaceSubscriptionId,
        tenantId,
        userId,
        remainingQuota,
        totalQuota: subscription.quantityIncluded,
        overageEnabled: subscription.overageEnabled || this.options.overageEnabled,
        resetDate: nextMonth
      };

    } catch (error) {
      logger.error('Error extracting quota info', { error: getErrorMessage(error) });
      return null;
    }
  }

  private async extractQuotaInfoFromTeamsContext(context: TurnContext): Promise<QuotaInfo | null> {
    try {
      // Extract tenant and user from Teams context
      const tenantId = context.activity?.conversation?.tenantId;
      const userId = context.activity?.from?.id;

      if (!tenantId || !userId) {
        return null;
      }

      // Get subscription for tenant
      const subscription = await this.subscriptionService.getByTenantId(tenantId);
      if (!subscription) {
        return null;
      }

      // Calculate remaining quota (same logic as above)
      const currentMonth = new Date();
      currentMonth.setDate(1);
      currentMonth.setHours(0, 0, 0, 0);
      
      const nextMonth = new Date(currentMonth);
      nextMonth.setMonth(nextMonth.getMonth() + 1);

      const usageThisMonth = await this.subscriptionService.getUsageForPeriod(
        subscription.id,
        currentMonth,
        nextMonth
      );

      const remainingQuota = Math.max(0, subscription.quantityIncluded - usageThisMonth);

      return {
        subscriptionId: subscription.marketplaceSubscriptionId,
        tenantId,
        userId,
        remainingQuota,
        totalQuota: subscription.quantityIncluded,
        overageEnabled: subscription.overageEnabled || this.options.overageEnabled,
        resetDate: nextMonth
      };

    } catch (error) {
      logger.error('Error extracting quota info from Teams context', { error: getErrorMessage(error) });
      return null;
    }
  }

  private async checkQuota(quotaInfo: QuotaInfo): Promise<{ allowed: boolean; reason?: string }> {
    // If overage is enabled, always allow
    if (quotaInfo.overageEnabled) {
      return { allowed: true };
    }

    // Check hard quota limit
    if (quotaInfo.remainingQuota <= 0) {
      return { 
        allowed: false, 
        reason: `Monthly quota of ${quotaInfo.totalQuota} questions exceeded. Quota resets on ${quotaInfo.resetDate.toDateString()}.`
      };
    }

    return { allowed: true };
  }

  private isQuestionEndpoint(req: Request): boolean {
    // Check if this is a bot message endpoint that would trigger an AI question
    return req.path === '/api/messages' && req.method === 'POST';
  }

  private extractUserId(req: Request): string {
    // Extract user ID from request (could be from JWT, header, etc.)
    return req.headers['x-user-id'] as string || 'unknown';
  }

  private setQuotaHeaders(res: Response, quotaInfo: QuotaInfo): void {
    res.setHeader('x-quota-remaining', quotaInfo.remainingQuota.toString());
    res.setHeader('x-quota-total', quotaInfo.totalQuota.toString());
    res.setHeader('x-quota-reset-date', quotaInfo.resetDate.toISOString());
    res.setHeader('x-overage-enabled', quotaInfo.overageEnabled.toString());
    
    // Add warning headers at thresholds
    const usagePercentage = ((quotaInfo.totalQuota - quotaInfo.remainingQuota) / quotaInfo.totalQuota) * 100;
    if (usagePercentage >= 90) {
      res.setHeader('x-quota-warning', 'critical');
    } else if (usagePercentage >= 80) {
      res.setHeader('x-quota-warning', 'high');
    }
  }

  private wrapResponse(req: Request, res: Response, next: NextFunction): void {
    const originalSend = res.send;
    const originalJson = res.json;

    // Track if response was successful
    let responseSent = false;

    res.send = function(data) {
      if (!responseSent && res.statusCode >= 200 && res.statusCode < 300 && req.quotaInfo) {
        responseSent = true;
        // Publish usage event asynchronously
        setTimeout(async () => {
          try {
            await (req as any).quotaMiddleware?.publishUsageEvent(req.quotaInfo, req.requestId);
          } catch (error) {
            logger.error('Failed to publish usage event', { error: getErrorMessage(error), requestId: req.requestId });
          }
        }, 0);
      }
      return originalSend.call(this, data);
    };

    res.json = function(data) {
      if (!responseSent && res.statusCode >= 200 && res.statusCode < 300 && req.quotaInfo) {
        responseSent = true;
        // Publish usage event asynchronously
        setTimeout(async () => {
          try {
            await (req as any).quotaMiddleware?.publishUsageEvent(req.quotaInfo, req.requestId);
          } catch (error) {
            logger.error('Failed to publish usage event', { error: getErrorMessage(error), requestId: req.requestId });
          }
        }, 0);
      }
      return originalJson.call(this, data);
    };

    // Store reference to middleware for async usage publishing
    (req as any).quotaMiddleware = this;

    next();
  }

  private sendQuotaExceededResponse(res: Response, quotaInfo: QuotaInfo, reason: string): void {
    res.status(429).json({
      error: 'Quota Exceeded',
      message: reason,
      details: {
        remainingQuota: quotaInfo.remainingQuota,
        totalQuota: quotaInfo.totalQuota,
        resetDate: quotaInfo.resetDate.toISOString(),
        overageEnabled: quotaInfo.overageEnabled
      }
    });
  }

  private sendQuotaError(res: Response, message: string, statusCode: number = 400): void {
    res.status(statusCode).json({
      error: 'Quota Error',
      message
    });
  }

  private getQuotaExceededMessage(quotaInfo: QuotaInfo): string {
    return `⚠️ **Quota Exceeded**\n\nYou have reached your monthly limit of ${quotaInfo.totalQuota} questions. Your quota will reset on ${quotaInfo.resetDate.toDateString()}.\n\nPlease contact your administrator to upgrade your plan or enable overage billing.`;
  }

  private async publishUsageEvent(quotaInfo: QuotaInfo, requestId: string): Promise<void> {
    try {
      const usageEvent: UsageEvent = {
        subscriptionId: quotaInfo.subscriptionId,
        dimension: this.options.dimension,
        quantity: 1,
        timestamp: new Date()
      };

      await this.meteringClient.publishUsageWithRetry(usageEvent);

      await this.auditLogger.log({
        action: 'quota.usage.published',
        tenantId: quotaInfo.tenantId,
        userId: quotaInfo.userId,
        subscriptionId: quotaInfo.subscriptionId,
        requestId,
        result: 'success',
        details: {
          dimension: this.options.dimension,
          quantity: 1
        }
      });

    } catch (error) {
      logger.error('Failed to publish usage event', { 
        error: getErrorMessage(error), 
        requestId,
        subscriptionId: quotaInfo.subscriptionId 
      });

      await this.auditLogger.log({
        action: 'quota.usage.failed',
        tenantId: quotaInfo.tenantId,
        userId: quotaInfo.userId,
        subscriptionId: quotaInfo.subscriptionId,
        requestId,
        result: 'error',
        details: { error: getErrorMessage(error) }
      });

      throw error;
    }
  }
}
