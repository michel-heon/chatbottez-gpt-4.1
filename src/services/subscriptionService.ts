import { logger } from '../utils/logger';

export interface Subscription {
  id: string;
  marketplaceSubscriptionId: string;
  tenantId: string;
  planId: string;
  status: 'PendingFulfillmentStart' | 'Subscribed' | 'Suspended' | 'Unsubscribed';
  activatedAt?: Date;
  updatedAt: Date;
  quantityIncluded: number;
  dimension: string;
  overageEnabled: boolean;
}

export interface CreateSubscriptionRequest {
  marketplaceSubscriptionId: string;
  tenantId: string;
  planId: string;
  status: string;
  quantityIncluded: number;
  dimension: string;
  overageEnabled?: boolean;
}

export interface UpdateSubscriptionRequest {
  planId?: string;
  status?: string;
  activatedAt?: Date;
  updatedAt?: Date;
  quantityIncluded?: number;
  overageEnabled?: boolean;
}

export interface UsageEvent {
  id: string;
  subscriptionId: string;
  eventId: string;
  dimension: string;
  quantity: number;
  timestamp: Date;
  status: 'pending' | 'sent' | 'failed';
  retryCount: number;
  createdAt: Date;
  sentAt?: Date;
}

/**
 * Service for managing subscriptions and usage tracking
 * In a production environment, this would use a real database
 */
export class SubscriptionService {
  private subscriptions: Map<string, Subscription> = new Map();
  private usageEvents: Map<string, UsageEvent> = new Map();

  constructor() {
    // Initialize with some mock data for development
    if (process.env.NODE_ENV === 'development') {
      this.initializeMockData();
    }
  }

  /**
   * Creates or updates a subscription
   */
  async createOrUpdateSubscription(request: CreateSubscriptionRequest): Promise<Subscription> {
    try {
      const existing = await this.getByMarketplaceId(request.marketplaceSubscriptionId);
      
      if (existing) {
        // Update existing subscription
        return await this.updateSubscription(existing.id, {
          planId: request.planId,
          status: request.status,
          quantityIncluded: request.quantityIncluded,
          updatedAt: new Date()
        });
      } else {
        // Create new subscription
        const subscription: Subscription = {
          id: this.generateId(),
          marketplaceSubscriptionId: request.marketplaceSubscriptionId,
          tenantId: request.tenantId,
          planId: request.planId,
          status: request.status as any,
          updatedAt: new Date(),
          quantityIncluded: request.quantityIncluded,
          dimension: request.dimension,
          overageEnabled: request.overageEnabled || false
        };

        this.subscriptions.set(subscription.id, subscription);
        
        logger.info('Subscription created', {
          subscriptionId: subscription.id,
          marketplaceSubscriptionId: subscription.marketplaceSubscriptionId,
          tenantId: subscription.tenantId
        });

        return subscription;
      }
    } catch (error) {
      logger.error('Error creating/updating subscription', { error: error.message, request });
      throw error;
    }
  }

  /**
   * Gets a subscription by marketplace subscription ID
   */
  async getByMarketplaceId(marketplaceSubscriptionId: string): Promise<Subscription | null> {
    try {
      for (const subscription of this.subscriptions.values()) {
        if (subscription.marketplaceSubscriptionId === marketplaceSubscriptionId) {
          return subscription;
        }
      }
      return null;
    } catch (error) {
      logger.error('Error getting subscription by marketplace ID', { error: error.message, marketplaceSubscriptionId });
      throw error;
    }
  }

  /**
   * Gets a subscription by tenant ID
   */
  async getByTenantId(tenantId: string): Promise<Subscription | null> {
    try {
      for (const subscription of this.subscriptions.values()) {
        if (subscription.tenantId === tenantId && subscription.status === 'Subscribed') {
          return subscription;
        }
      }
      return null;
    } catch (error) {
      logger.error('Error getting subscription by tenant ID', { error: error.message, tenantId });
      throw error;
    }
  }

  /**
   * Gets a subscription by ID
   */
  async getById(id: string): Promise<Subscription | null> {
    try {
      return this.subscriptions.get(id) || null;
    } catch (error) {
      logger.error('Error getting subscription by ID', { error: error.message, id });
      throw error;
    }
  }

  /**
   * Updates a subscription
   */
  async updateSubscription(id: string, updates: UpdateSubscriptionRequest): Promise<Subscription> {
    try {
      const subscription = this.subscriptions.get(id);
      if (!subscription) {
        throw new Error(`Subscription not found: ${id}`);
      }

      const updatedSubscription: Subscription = {
        ...subscription,
        ...updates,
        updatedAt: new Date(),
        status: (updates.status as Subscription['status']) || subscription.status
      };

      this.subscriptions.set(id, updatedSubscription);

      logger.info('Subscription updated', {
        subscriptionId: id,
        updates
      });

      return updatedSubscription;
    } catch (error) {
      logger.error('Error updating subscription', { error: error.message, id, updates });
      throw error;
    }
  }

  /**
   * Gets usage count for a subscription within a time period
   */
  async getUsageForPeriod(subscriptionId: string, startDate: Date, endDate: Date): Promise<number> {
    try {
      let totalUsage = 0;

      for (const event of this.usageEvents.values()) {
        if (event.subscriptionId === subscriptionId &&
            event.timestamp >= startDate &&
            event.timestamp < endDate &&
            event.status === 'sent') {
          totalUsage += event.quantity;
        }
      }

      return totalUsage;
    } catch (error) {
      logger.error('Error getting usage for period', { 
        error: error.message, 
        subscriptionId, 
        startDate, 
        endDate 
      });
      throw error;
    }
  }

  /**
   * Records a usage event
   */
  async recordUsageEvent(
    subscriptionId: string,
    dimension: string,
    quantity: number,
    timestamp: Date = new Date()
  ): Promise<UsageEvent> {
    try {
      const subscription = await this.getById(subscriptionId);
      if (!subscription) {
        throw new Error(`Subscription not found: ${subscriptionId}`);
      }

      const usageEvent: UsageEvent = {
        id: this.generateId(),
        subscriptionId,
        eventId: this.generateEventId(),
        dimension,
        quantity,
        timestamp,
        status: 'pending',
        retryCount: 0,
        createdAt: new Date()
      };

      this.usageEvents.set(usageEvent.id, usageEvent);

      logger.info('Usage event recorded', {
        eventId: usageEvent.id,
        subscriptionId,
        dimension,
        quantity
      });

      return usageEvent;
    } catch (error) {
      logger.error('Error recording usage event', { 
        error: error.message, 
        subscriptionId, 
        dimension, 
        quantity 
      });
      throw error;
    }
  }

  /**
   * Updates a usage event status
   */
  async updateUsageEventStatus(
    eventId: string, 
    status: 'sent' | 'failed', 
    sentAt?: Date
  ): Promise<UsageEvent> {
    try {
      const event = this.usageEvents.get(eventId);
      if (!event) {
        throw new Error(`Usage event not found: ${eventId}`);
      }

      const updatedEvent: UsageEvent = {
        ...event,
        status,
        sentAt: sentAt || new Date(),
        retryCount: status === 'failed' ? event.retryCount + 1 : event.retryCount
      };

      this.usageEvents.set(eventId, updatedEvent);

      logger.info('Usage event status updated', {
        eventId,
        status,
        retryCount: updatedEvent.retryCount
      });

      return updatedEvent;
    } catch (error) {
      logger.error('Error updating usage event status', { 
        error: error.message, 
        eventId, 
        status 
      });
      throw error;
    }
  }

  /**
   * Gets pending usage events for retry
   */
  async getPendingUsageEvents(maxRetries: number = 5): Promise<UsageEvent[]> {
    try {
      const pendingEvents: UsageEvent[] = [];

      for (const event of this.usageEvents.values()) {
        if ((event.status === 'pending' || event.status === 'failed') && 
            event.retryCount < maxRetries) {
          pendingEvents.push(event);
        }
      }

      return pendingEvents;
    } catch (error) {
      logger.error('Error getting pending usage events', { error: error.message });
      throw error;
    }
  }

  /**
   * Gets all subscriptions
   */
  async getAllSubscriptions(): Promise<Subscription[]> {
    try {
      return Array.from(this.subscriptions.values());
    } catch (error) {
      logger.error('Error getting all subscriptions', { error: error.message });
      throw error;
    }
  }

  private generateId(): string {
    return `sub_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private generateEventId(): string {
    return `evt_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private initializeMockData(): void {
    // Create a mock subscription for development
    const mockSubscription: Subscription = {
      id: 'sub_mock_123',
      marketplaceSubscriptionId: 'msft-sub-123-456-789',
      tenantId: 'tenant-123-456',
      planId: 'basic-plan',
      status: 'Subscribed',
      activatedAt: new Date(),
      updatedAt: new Date(),
      quantityIncluded: 300,
      dimension: 'question',
      overageEnabled: false
    };

    this.subscriptions.set(mockSubscription.id, mockSubscription);

    logger.info('Mock subscription data initialized for development', {
      subscriptionId: mockSubscription.id,
      marketplaceSubscriptionId: mockSubscription.marketplaceSubscriptionId
    });
  }
}
