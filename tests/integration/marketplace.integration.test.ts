import request from 'supertest';
import express from 'express';
import { MarketplaceFulfillmentController } from '../../src/marketplace/fulfillmentController';

// Mock dependencies
jest.mock('../../src/utils/logger');
jest.mock('../../src/utils/auditLogger');
jest.mock('../../src/services/subscriptionService');

describe('Marketplace Integration Tests', () => {
  let app: express.Application;
  let fulfillmentController: MarketplaceFulfillmentController;

  beforeEach(() => {
    app = express();
    app.use(express.json());
    fulfillmentController = new MarketplaceFulfillmentController();

    // Setup routes
    app.post('/marketplace/resolve', async (req, res) => {
      await fulfillmentController.resolve(req, res);
    });

    app.post('/marketplace/:subscriptionId/activate', async (req, res) => {
      await fulfillmentController.activate(req, res);
    });

    // Mock fetch for marketplace API calls
    global.fetch = jest.fn();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /marketplace/resolve', () => {
    it('should resolve marketplace token successfully', async () => {
      // Arrange
      const mockMarketplaceResponse = {
        id: 'test-subscription-123',
        subscriptionName: 'Test Subscription',
        offerId: 'test-offer',
        planId: 'basic-plan',
        quantity: 1,
        beneficiary: {
          tenantId: 'test-tenant-123',
          objectId: 'test-user-123'
        },
        purchaser: {
          tenantId: 'test-tenant-123',
          objectId: 'test-user-123'
        }
      };

      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => mockMarketplaceResponse
      });

      // Act
      const response = await request(app)
        .post('/marketplace/resolve')
        .set('Authorization', 'Bearer mock-jwt-token')
        .send({ token: 'mock-marketplace-token' });

      // Assert
      expect(response.status).toBe(200);
      expect(response.body).toEqual({
        subscriptionId: 'test-subscription-123',
        planId: 'basic-plan',
        quantity: 1,
        tenantId: 'test-tenant-123'
      });
    });

    it('should handle invalid tokens', async () => {
      // Act
      const response = await request(app)
        .post('/marketplace/resolve')
        .set('Authorization', 'Bearer mock-jwt-token')
        .send({}); // Missing token

      // Assert
      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Token is required');
    });
  });

  describe('POST /marketplace/:subscriptionId/activate', () => {
    it('should activate subscription successfully', async () => {
      // Arrange
      const subscriptionId = 'test-subscription-123';
      
      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => ({})
      });

      // Act
      const response = await request(app)
        .post(`/marketplace/${subscriptionId}/activate`)
        .set('Authorization', 'Bearer mock-jwt-token')
        .send({
          planId: 'basic-plan',
          quantity: 1
        });

      // Assert
      expect(response.status).toBe(200);
      expect(response.body.message).toBe('Subscription activated successfully');
    });
  });
});
