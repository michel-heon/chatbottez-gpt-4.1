import { MarketplaceMeteringClient, UsageEvent } from '../../src/marketplace/meteringClient';

// Mock the dependencies
jest.mock('../../src/utils/logger');
jest.mock('../../src/utils/auditLogger');

// Mock fetch
global.fetch = jest.fn();

describe('MarketplaceMeteringClient', () => {
  let meteringClient: MarketplaceMeteringClient;
  
  beforeEach(() => {
    meteringClient = new MarketplaceMeteringClient();
    jest.clearAllMocks();
    
    // Setup environment variables
    process.env.MARKETPLACE_API_BASE = 'https://test-marketplace.com';
    process.env.MARKETPLACE_API_KEY = 'test-api-key';
    process.env.MARKETPLACE_METERING_API_VERSION = '2018-08-31';
  });

  afterEach(() => {
    delete process.env.MARKETPLACE_API_BASE;
    delete process.env.MARKETPLACE_API_KEY;
    delete process.env.MARKETPLACE_METERING_API_VERSION;
  });

  describe('publishUsage', () => {
    it('should successfully publish usage event', async () => {
      // Arrange
      const usageEvent: UsageEvent = {
        subscriptionId: 'test-sub-123',
        dimension: 'question',
        quantity: 1,
        timestamp: new Date('2024-01-01T10:00:00Z')
      };

      const mockResponse = {
        usageEventId: 'usage-123',
        status: 'Accepted',
        messageTime: '2024-01-01T10:00:00Z',
        quantity: 1,
        dimension: 'question',
        effectiveStartTime: '2024-01-01T10:00:00Z',
        planId: 'basic-plan'
      };

      (fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        text: async () => JSON.stringify(mockResponse)
      });

      // Act
      const result = await meteringClient.publishUsage(usageEvent);

      // Assert
      expect(result).toEqual(mockResponse);
      expect(fetch).toHaveBeenCalledWith(
        'https://test-marketplace.com/api/usageEvent?api-version=2018-08-31',
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'Content-Type': 'application/json',
            'Authorization': 'Bearer test-api-key'
          }),
          body: JSON.stringify({
            subscriptionId: 'test-sub-123',
            dimension: 'question',
            quantity: 1,
            timestamp: new Date('2024-01-01T10:00:00Z')
          })
        })
      );
    });

    it('should handle API errors gracefully', async () => {
      // Arrange
      const usageEvent: UsageEvent = {
        subscriptionId: 'test-sub-123',
        dimension: 'question',
        quantity: 1,
        timestamp: new Date()
      };

      (fetch as jest.Mock).mockResolvedValueOnce({
        ok: false,
        status: 400,
        statusText: 'Bad Request',
        text: async () => JSON.stringify({ error: 'Invalid subscription' })
      });

      // Act & Assert
      await expect(meteringClient.publishUsage(usageEvent))
        .rejects
        .toThrow('Marketplace metering API failed: 400 Bad Request - Invalid subscription');
    });

    it('should handle network errors', async () => {
      // Arrange
      const usageEvent: UsageEvent = {
        subscriptionId: 'test-sub-123',
        dimension: 'question',
        quantity: 1,
        timestamp: new Date()
      };

      (fetch as jest.Mock).mockRejectedValueOnce(new Error('Network error'));

      // Act & Assert
      await expect(meteringClient.publishUsage(usageEvent))
        .rejects
        .toThrow('Network error');
    });
  });

  describe('publishUsageWithRetry', () => {
    it('should retry on failure and eventually succeed', async () => {
      // Arrange
      const usageEvent: UsageEvent = {
        subscriptionId: 'test-sub-123',
        dimension: 'question',
        quantity: 1,
        timestamp: new Date()
      };

      const mockResponse = {
        usageEventId: 'usage-123',
        status: 'Accepted',
        messageTime: '2024-01-01T10:00:00Z',
        quantity: 1,
        dimension: 'question',
        effectiveStartTime: '2024-01-01T10:00:00Z',
        planId: 'basic-plan'
      };

      // First two calls fail, third succeeds
      (fetch as jest.Mock)
        .mockRejectedValueOnce(new Error('Network error'))
        .mockRejectedValueOnce(new Error('Network error'))
        .mockResolvedValueOnce({
          ok: true,
          text: async () => JSON.stringify(mockResponse)
        });

      // Act
      const result = await meteringClient.publishUsageWithRetry(usageEvent, 3);

      // Assert
      expect(result).toEqual(mockResponse);
      expect(fetch).toHaveBeenCalledTimes(3);
    });

    it('should fail after max retries', async () => {
      // Arrange
      const usageEvent: UsageEvent = {
        subscriptionId: 'test-sub-123',
        dimension: 'question',
        quantity: 1,
        timestamp: new Date()
      };

      (fetch as jest.Mock).mockRejectedValue(new Error('Network error'));

      // Act & Assert
      await expect(meteringClient.publishUsageWithRetry(usageEvent, 2))
        .rejects
        .toThrow('Network error');
      
      expect(fetch).toHaveBeenCalledTimes(3); // Initial call + 2 retries
    });
  });

  describe('publishUsageBatch', () => {
    it('should process multiple usage events', async () => {
      // Arrange
      const usageEvents: UsageEvent[] = [
        {
          subscriptionId: 'test-sub-123',
          dimension: 'question',
          quantity: 1,
          timestamp: new Date()
        },
        {
          subscriptionId: 'test-sub-456',
          dimension: 'question',
          quantity: 1,
          timestamp: new Date()
        }
      ];

      const mockResponse = {
        usageEventId: 'usage-123',
        status: 'Accepted',
        messageTime: '2024-01-01T10:00:00Z',
        quantity: 1,
        dimension: 'question',
        effectiveStartTime: '2024-01-01T10:00:00Z',
        planId: 'basic-plan'
      };

      (fetch as jest.Mock).mockResolvedValue({
        ok: true,
        text: async () => JSON.stringify(mockResponse)
      });

      // Act
      const results = await meteringClient.publishUsageBatch(usageEvents);

      // Assert
      expect(results).toHaveLength(2);
      expect(fetch).toHaveBeenCalledTimes(2);
    });
  });

  describe('validateUsageEventTimestamp', () => {
    it('should validate recent timestamps', () => {
      // Arrange
      const recentTimestamp = new Date();

      // Act
      const isValid = MarketplaceMeteringClient.validateUsageEventTimestamp(recentTimestamp);

      // Assert
      expect(isValid).toBe(true);
    });

    it('should reject old timestamps', () => {
      // Arrange
      const oldTimestamp = new Date();
      oldTimestamp.setHours(oldTimestamp.getHours() - 25); // 25 hours ago

      // Act
      const isValid = MarketplaceMeteringClient.validateUsageEventTimestamp(oldTimestamp);

      // Assert
      expect(isValid).toBe(false);
    });
  });

  describe('createQuestionUsageEvent', () => {
    it('should create a question usage event', () => {
      // Arrange
      const subscriptionId = 'test-sub-123';
      const timestamp = new Date('2024-01-01T10:00:00Z');

      // Act
      const usageEvent = MarketplaceMeteringClient.createQuestionUsageEvent(subscriptionId, timestamp);

      // Assert
      expect(usageEvent).toEqual({
        subscriptionId: 'test-sub-123',
        dimension: 'question',
        quantity: 1,
        timestamp
      });
    });

    it('should use current time if no timestamp provided', () => {
      // Arrange
      const subscriptionId = 'test-sub-123';
      const beforeCall = new Date();

      // Act
      const usageEvent = MarketplaceMeteringClient.createQuestionUsageEvent(subscriptionId);

      // Assert
      const afterCall = new Date();
      expect(usageEvent.subscriptionId).toBe('test-sub-123');
      expect(usageEvent.dimension).toBe('question');
      expect(usageEvent.quantity).toBe(1);
      expect(usageEvent.timestamp.getTime()).toBeGreaterThanOrEqual(beforeCall.getTime());
      expect(usageEvent.timestamp.getTime()).toBeLessThanOrEqual(afterCall.getTime());
    });
  });
});
