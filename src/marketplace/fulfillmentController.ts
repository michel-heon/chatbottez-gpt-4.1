import { Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { logger } from '../utils/logger';
import { SubscriptionService } from '../services/subscriptionService';
import { validateMarketplaceWebhook } from '../utils/auth';
import { AuditLogger } from '../utils/auditLogger';

export interface MarketplaceResolveRequest {
  token: string;
}

export interface MarketplaceSubscription {
  id: string;
  subscriptionName: string;
  offerId: string;
  planId: string;
  quantity: number;
  subscription: {
    id: string;
    publisherId: string;
    offerId: string;
    planId: string;
    quantity: number;
    subscription: any;
  };
  beneficiary: {
    tenantId: string;
    objectId: string;
  };
  purchaser: {
    tenantId: string;
    objectId: string;
  };
}

export interface ActivateSubscriptionRequest {
  planId: string;
  quantity: number;
}

export interface UpdateSubscriptionRequest {
  planId: string;
  quantity: number;
}

export class MarketplaceFulfillmentController {
  private subscriptionService: SubscriptionService;
  private auditLogger: AuditLogger;

  constructor() {
    this.subscriptionService = new SubscriptionService();
    this.auditLogger = new AuditLogger();
  }

  /**
   * POST /marketplace/resolve
   * Resolves the marketplace purchase identification token to get subscription details
   */
  async resolve(req: Request, res: Response): Promise<void> {
    const requestId = uuidv4();
    
    try {
      // Validate webhook signature
      if (!validateMarketplaceWebhook(req)) {
        logger.warn('Invalid marketplace webhook signature', { requestId });
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const { token } = req.body as MarketplaceResolveRequest;
      
      if (!token) {
        res.status(400).json({ error: 'Token is required' });
        return;
      }

      logger.info('Resolving marketplace token', { requestId, tokenPrefix: token.substring(0, 10) });

      // Call Microsoft Marketplace API to resolve token
      const subscription = await this.callMarketplaceResolveAPI(token);
      
      // Store or update subscription in database
      await this.subscriptionService.createOrUpdateSubscription({
        marketplaceSubscriptionId: subscription.id,
        tenantId: subscription.beneficiary.tenantId,
        planId: subscription.planId,
        status: 'PendingFulfillmentStart',
        quantityIncluded: process.env.INCLUDED_QUOTA_PER_MONTH ? parseInt(process.env.INCLUDED_QUOTA_PER_MONTH) : 300,
        dimension: process.env.DIMENSION_NAME || 'question'
      });

      await this.auditLogger.log({
        action: 'marketplace.resolve',
        tenantId: subscription.beneficiary.tenantId,
        subscriptionId: subscription.id,
        requestId,
        result: 'success',
        details: { planId: subscription.planId }
      });

      res.json({
        subscriptionId: subscription.id,
        planId: subscription.planId,
        quantity: subscription.quantity,
        tenantId: subscription.beneficiary.tenantId
      });

    } catch (error) {
      logger.error('Error resolving marketplace token', { error: error.message, requestId });
      
      await this.auditLogger.log({
        action: 'marketplace.resolve',
        requestId,
        result: 'error',
        details: { error: error.message }
      });

      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * POST /marketplace/activate
   * Activates a subscription
   */
  async activate(req: Request, res: Response): Promise<void> {
    const requestId = uuidv4();
    
    try {
      if (!validateMarketplaceWebhook(req)) {
        logger.warn('Invalid marketplace webhook signature', { requestId });
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const subscriptionId = req.params.subscriptionId;
      const { planId, quantity } = req.body as ActivateSubscriptionRequest;

      logger.info('Activating subscription', { requestId, subscriptionId, planId });

      // Get subscription from database
      const subscription = await this.subscriptionService.getByMarketplaceId(subscriptionId);
      if (!subscription) {
        res.status(404).json({ error: 'Subscription not found' });
        return;
      }

      // Call Microsoft Marketplace API to activate
      await this.callMarketplaceActivateAPI(subscriptionId, { planId, quantity });

      // Update subscription status
      await this.subscriptionService.updateSubscription(subscription.id, {
        status: 'Subscribed',
        planId,
        activatedAt: new Date()
      });

      await this.auditLogger.log({
        action: 'marketplace.activate',
        tenantId: subscription.tenantId,
        subscriptionId,
        requestId,
        result: 'success',
        details: { planId, quantity }
      });

      res.json({ message: 'Subscription activated successfully' });

    } catch (error) {
      logger.error('Error activating subscription', { error: error.message, requestId, subscriptionId: req.params.subscriptionId });
      
      await this.auditLogger.log({
        action: 'marketplace.activate',
        subscriptionId: req.params.subscriptionId,
        requestId,
        result: 'error',
        details: { error: error.message }
      });

      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * POST /marketplace/update
   * Updates a subscription (plan change, quantity change)
   */
  async update(req: Request, res: Response): Promise<void> {
    const requestId = uuidv4();
    
    try {
      if (!validateMarketplaceWebhook(req)) {
        logger.warn('Invalid marketplace webhook signature', { requestId });
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const subscriptionId = req.params.subscriptionId;
      const { planId, quantity } = req.body as UpdateSubscriptionRequest;

      logger.info('Updating subscription', { requestId, subscriptionId, planId, quantity });

      const subscription = await this.subscriptionService.getByMarketplaceId(subscriptionId);
      if (!subscription) {
        res.status(404).json({ error: 'Subscription not found' });
        return;
      }

      // Update subscription in database
      await this.subscriptionService.updateSubscription(subscription.id, {
        planId,
        updatedAt: new Date()
      });

      await this.auditLogger.log({
        action: 'marketplace.update',
        tenantId: subscription.tenantId,
        subscriptionId,
        requestId,
        result: 'success',
        details: { planId, quantity, previousPlanId: subscription.planId }
      });

      res.json({ message: 'Subscription updated successfully' });

    } catch (error) {
      logger.error('Error updating subscription', { error: error.message, requestId, subscriptionId: req.params.subscriptionId });
      
      await this.auditLogger.log({
        action: 'marketplace.update',
        subscriptionId: req.params.subscriptionId,
        requestId,
        result: 'error',
        details: { error: error.message }
      });

      res.status(500).json({ error: 'Internal server error' });
    }
  }

  /**
   * POST /marketplace/deactivate
   * Deactivates/cancels a subscription
   */
  async deactivate(req: Request, res: Response): Promise<void> {
    const requestId = uuidv4();
    
    try {
      if (!validateMarketplaceWebhook(req)) {
        logger.warn('Invalid marketplace webhook signature', { requestId });
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }

      const subscriptionId = req.params.subscriptionId;

      logger.info('Deactivating subscription', { requestId, subscriptionId });

      const subscription = await this.subscriptionService.getByMarketplaceId(subscriptionId);
      if (!subscription) {
        res.status(404).json({ error: 'Subscription not found' });
        return;
      }

      // Update subscription status
      await this.subscriptionService.updateSubscription(subscription.id, {
        status: 'Unsubscribed',
        updatedAt: new Date()
      });

      await this.auditLogger.log({
        action: 'marketplace.deactivate',
        tenantId: subscription.tenantId,
        subscriptionId,
        requestId,
        result: 'success'
      });

      res.json({ message: 'Subscription deactivated successfully' });

    } catch (error) {
      logger.error('Error deactivating subscription', { error: error.message, requestId, subscriptionId: req.params.subscriptionId });
      
      await this.auditLogger.log({
        action: 'marketplace.deactivate',
        subscriptionId: req.params.subscriptionId,
        requestId,
        result: 'error',
        details: { error: error.message }
      });

      res.status(500).json({ error: 'Internal server error' });
    }
  }

  private async callMarketplaceResolveAPI(token: string): Promise<MarketplaceSubscription> {
    const response = await fetch(`${process.env.MARKETPLACE_API_BASE}/api/saas/subscriptions/resolve?api-version=${process.env.MARKETPLACE_SUBSCRIPTION_API_VERSION}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.MARKETPLACE_API_KEY}`,
        'x-ms-marketplace-token': token
      }
    });

    if (!response.ok) {
      throw new Error(`Marketplace resolve API failed: ${response.status} ${response.statusText}`);
    }

    return await response.json();
  }

  private async callMarketplaceActivateAPI(subscriptionId: string, request: ActivateSubscriptionRequest): Promise<void> {
    const response = await fetch(`${process.env.MARKETPLACE_API_BASE}/api/saas/subscriptions/${subscriptionId}/activate?api-version=${process.env.MARKETPLACE_SUBSCRIPTION_API_VERSION}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.MARKETPLACE_API_KEY}`
      },
      body: JSON.stringify(request)
    });

    if (!response.ok) {
      throw new Error(`Marketplace activate API failed: ${response.status} ${response.statusText}`);
    }
  }
}
