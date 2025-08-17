import { logger } from './logger';

export interface AuditLogEntry {
  id?: string;
  timestamp?: Date;
  action: string;
  tenantId?: string;
  userId?: string;
  subscriptionId?: string;
  requestId?: string;
  result: 'success' | 'error' | 'blocked' | 'warning';
  details?: any;
  ipAddress?: string;
  userAgent?: string;
}

export class AuditLogger {
  private enabled: boolean;

  constructor() {
    this.enabled = process.env.AUDIT_LOG_ENABLED !== 'false';
  }

  /**
   * Logs an audit event
   * @param entry Audit log entry
   */
  async log(entry: AuditLogEntry): Promise<void> {
    if (!this.enabled) {
      return;
    }

    try {
      const auditEntry: AuditLogEntry = {
        ...entry,
        id: this.generateId(),
        timestamp: entry.timestamp || new Date()
      };

      // Log to console/Application Insights
      logger.info('AUDIT', {
        audit: auditEntry
      });

      // In production, you might want to store audit logs in a separate database
      // or send them to a specialized audit logging service
      if (process.env.NODE_ENV === 'production') {
        await this.persistAuditLog(auditEntry);
      }

    } catch (error) {
      logger.error('Failed to write audit log', { 
        error: error.message,
        originalEntry: entry 
      });
    }
  }

  /**
   * Logs a quota-related event
   */
  async logQuotaEvent(
    action: 'quota.check' | 'quota.exceeded' | 'quota.usage' | 'quota.reset',
    subscriptionId: string,
    tenantId: string,
    userId: string,
    details: any
  ): Promise<void> {
    await this.log({
      action,
      subscriptionId,
      tenantId,
      userId,
      result: action === 'quota.exceeded' ? 'blocked' : 'success',
      details
    });
  }

  /**
   * Logs a marketplace-related event
   */
  async logMarketplaceEvent(
    action: 'marketplace.resolve' | 'marketplace.activate' | 'marketplace.update' | 'marketplace.deactivate' | 'marketplace.usage',
    subscriptionId: string,
    tenantId?: string,
    result: 'success' | 'error' = 'success',
    details?: any
  ): Promise<void> {
    await this.log({
      action,
      subscriptionId,
      tenantId,
      result,
      details
    });
  }

  /**
   * Logs a security-related event
   */
  async logSecurityEvent(
    action: 'auth.failed' | 'auth.success' | 'webhook.invalid' | 'rate.limit',
    ipAddress?: string,
    userAgent?: string,
    details?: any
  ): Promise<void> {
    await this.log({
      action,
      result: action.includes('failed') || action.includes('invalid') ? 'error' : 'success',
      ipAddress,
      userAgent,
      details
    });
  }

  /**
   * Logs an API usage event
   */
  async logApiUsage(
    endpoint: string,
    method: string,
    statusCode: number,
    responseTime: number,
    subscriptionId?: string,
    tenantId?: string,
    userId?: string
  ): Promise<void> {
    await this.log({
      action: 'api.usage',
      subscriptionId,
      tenantId,
      userId,
      result: statusCode >= 200 && statusCode < 400 ? 'success' : 'error',
      details: {
        endpoint,
        method,
        statusCode,
        responseTime
      }
    });
  }

  private generateId(): string {
    return `audit_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private async persistAuditLog(entry: AuditLogEntry): Promise<void> {
    try {
      // In a production environment, you would:
      // 1. Store in a dedicated audit database
      // 2. Send to Azure Log Analytics
      // 3. Send to Application Insights as custom events
      // 4. Send to a SIEM system
      
      // Example: Store in database
      // await this.auditRepository.save(entry);
      
      // Example: Send to Application Insights
      // this.appInsightsClient.trackEvent('AuditEvent', entry);
      
      // Example: Send to Azure Log Analytics
      // await this.logAnalyticsClient.send(entry);
      
      // For now, just ensure it's properly logged
      logger.debug('Audit log persisted', { entryId: entry.id });

    } catch (error) {
      logger.error('Failed to persist audit log', { 
        error: error.message,
        entryId: entry.id 
      });
    }
  }

  /**
   * Creates a performance monitoring decorator for methods
   */
  static createPerformanceMonitor(className: string, methodName: string) {
    return function (target: any, propertyName: string, descriptor: PropertyDescriptor) {
      const method = descriptor.value;

      descriptor.value = async function (...args: any[]) {
        const start = Date.now();
        const auditLogger = new AuditLogger();
        
        try {
          const result = await method.apply(this, args);
          const duration = Date.now() - start;
          
          await auditLogger.log({
            action: `performance.${className}.${methodName}`,
            result: 'success',
            details: {
              duration,
              args: process.env.LOG_LEVEL === 'debug' ? args : undefined
            }
          });

          return result;
        } catch (error) {
          const duration = Date.now() - start;
          
          await auditLogger.log({
            action: `performance.${className}.${methodName}`,
            result: 'error',
            details: {
              duration,
              error: error.message,
              args: process.env.LOG_LEVEL === 'debug' ? args : undefined
            }
          });

          throw error;
        }
      };
    };
  }
}
