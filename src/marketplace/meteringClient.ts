import { v4 as uuidv4 } from 'uuid';
import { logger } from '../utils/logger';
import { AuditLogger } from '../utils/auditLogger';
import { getErrorMessage, toError } from '../utils/errorHandler';

export interface UsageEvent {
  subscriptionId: string;
  dimension: string;
  quantity: number;
  timestamp: Date;
  resourceId?: string;
  resourceUri?: string;
}

export interface PublishUsageRequest {
  subscriptionId: string;
  dimension: string;
  quantity: number;
  timestamp: Date;
  resourceId?: string;
  resourceUri?: string;
}

export interface PublishUsageResponse {
  usageEventId: string;
  status: 'Accepted' | 'Expired' | 'Duplicate' | 'Error';
  messageTime: string;
  resourceId?: string;
  resourceUri?: string;
  quantity: number;
  dimension: string;
  effectiveStartTime: string;
  planId: string;
}

export class MarketplaceMeteringClient {
  private auditLogger: AuditLogger;
  private readonly apiBase: string;
  private readonly apiKey: string;
  private readonly apiVersion: string;

  constructor() {
    this.auditLogger = new AuditLogger();
    this.apiBase = process.env.MARKETPLACE_API_BASE || 'https://marketplaceapi.microsoft.com';
    this.apiKey = process.env.MARKETPLACE_API_KEY || '';
    this.apiVersion = process.env.MARKETPLACE_METERING_API_VERSION || '2018-08-31';
  }

  /**
   * Publishes a usage event to Microsoft Marketplace Metered Billing API
   * @param usageEvent The usage event to publish
   * @returns Promise<PublishUsageResponse>
   */
  async publishUsage(usageEvent: UsageEvent): Promise<PublishUsageResponse> {
    const requestId = uuidv4();
    const eventId = uuidv4();

    try {
      logger.info('Publishing usage event to marketplace', {
        requestId,
        eventId,
        subscriptionId: usageEvent.subscriptionId,
        dimension: usageEvent.dimension,
        quantity: usageEvent.quantity
      });

      const requestBody: PublishUsageRequest = {
        subscriptionId: usageEvent.subscriptionId,
        dimension: usageEvent.dimension,
        quantity: usageEvent.quantity,
        timestamp: usageEvent.timestamp,
        resourceId: usageEvent.resourceId,
        resourceUri: usageEvent.resourceUri
      };

      const response = await this.makeApiCall(requestBody, requestId, eventId);

      await this.auditLogger.log({
        action: 'marketplace.usage.publish',
        subscriptionId: usageEvent.subscriptionId,
        requestId,
        result: 'success',
        details: {
          eventId,
          dimension: usageEvent.dimension,
          quantity: usageEvent.quantity,
          status: response.status,
          usageEventId: response.usageEventId
        }
      });

      logger.info('Usage event published successfully', {
        requestId,
        eventId,
        usageEventId: response.usageEventId,
        status: response.status
      });

      return response;

    } catch (error) {
      logger.error('Failed to publish usage event', {
        error: getErrorMessage(error),
        requestId,
        eventId,
        subscriptionId: usageEvent.subscriptionId
      });

      await this.auditLogger.log({
        action: 'marketplace.usage.publish',
        subscriptionId: usageEvent.subscriptionId,
        requestId,
        result: 'error',
        details: {
          eventId,
          error: getErrorMessage(error),
          dimension: usageEvent.dimension,
          quantity: usageEvent.quantity
        }
      });

      throw toError(error);
    }
  }

  /**
   * Publishes usage with automatic retry logic
   * @param usageEvent The usage event to publish
   * @param maxRetries Maximum number of retry attempts
   * @returns Promise<PublishUsageResponse>
   */
  async publishUsageWithRetry(usageEvent: UsageEvent, maxRetries: number = 5): Promise<PublishUsageResponse> {
    let lastError: Error | undefined;
    const initialDelay = parseInt(process.env.RETRY_INITIAL_DELAY_MS || '1000');
    const maxDelay = parseInt(process.env.RETRY_MAX_DELAY_MS || '30000');

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await this.publishUsage(usageEvent);
      } catch (error) {
        lastError = toError(error);
        
        if (attempt === maxRetries) {
          logger.error('All retry attempts exhausted for usage event', {
            subscriptionId: usageEvent.subscriptionId,
            attempt: attempt + 1,
            maxRetries: maxRetries + 1,
            error: getErrorMessage(error)
          });
          break;
        }

        // Calculate exponential backoff delay
        const delay = Math.min(initialDelay * Math.pow(2, attempt), maxDelay);
        
        logger.warn('Usage event publish failed, retrying', {
          subscriptionId: usageEvent.subscriptionId,
          attempt: attempt + 1,
          maxRetries: maxRetries + 1,
          delay,
          error: getErrorMessage(error)
        });

        await this.sleep(delay);
      }
    }

    throw lastError || new Error('Unknown error in retry logic');
  }

  /**
   * Batch publish multiple usage events
   * @param usageEvents Array of usage events to publish
   * @returns Promise<PublishUsageResponse[]>
   */
  async publishUsageBatch(usageEvents: UsageEvent[]): Promise<PublishUsageResponse[]> {
    const results: PublishUsageResponse[] = [];
    const batchId = uuidv4();

    logger.info('Publishing usage batch', {
      batchId,
      eventCount: usageEvents.length
    });

    // Process events sequentially to avoid rate limiting
    for (const event of usageEvents) {
      try {
        const result = await this.publishUsageWithRetry(event);
        results.push(result);
      } catch (error) {
        logger.error('Failed to publish usage event in batch', {
          batchId,
          subscriptionId: event.subscriptionId,
          error: getErrorMessage(error)
        });
        
        // Continue with other events even if one fails
        // The failed event should be stored for later retry
      }
    }

    logger.info('Usage batch processing completed', {
      batchId,
      total: usageEvents.length,
      successful: results.length,
      failed: usageEvents.length - results.length
    });

    return results;
  }

  private async makeApiCall(
    requestBody: PublishUsageRequest,
    requestId: string,
    eventId: string
  ): Promise<PublishUsageResponse> {
    const url = `${this.apiBase}/api/usageEvent?api-version=${this.apiVersion}`;
    
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`,
        'x-ms-requestid': requestId,
        'x-ms-correlationid': eventId
      },
      body: JSON.stringify(requestBody)
    });

    const responseText = await response.text();
    
    if (!response.ok) {
      let errorMessage = `Marketplace metering API failed: ${response.status} ${response.statusText}`;
      
      try {
        const errorData = JSON.parse(responseText);
        errorMessage += ` - ${errorData.message || errorData.error?.message || 'Unknown error'}`;
      } catch {
        errorMessage += ` - ${responseText}`;
      }
      
      throw new Error(errorMessage);
    }

    try {
      return JSON.parse(responseText);
    } catch (error) {
      throw new Error(`Invalid JSON response from marketplace API: ${responseText}`);
    }
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Validates if the usage event is within acceptable time window
   * Microsoft requires usage events to be within 24 hours
   */
  static validateUsageEventTimestamp(timestamp: Date): boolean {
    const now = new Date();
    const hoursDiff = Math.abs(now.getTime() - timestamp.getTime()) / (1000 * 60 * 60);
    return hoursDiff <= 24;
  }

  /**
   * Creates a usage event for a question
   */
  static createQuestionUsageEvent(subscriptionId: string, timestamp?: Date): UsageEvent {
    return {
      subscriptionId,
      dimension: process.env.DIMENSION_NAME || 'question',
      quantity: 1,
      timestamp: timestamp || new Date()
    };
  }
}
