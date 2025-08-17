// Import required packages
import express from "express";
import { v4 as uuidv4 } from 'uuid';

// This bot's adapter
import adapter from "./adapter";

// This bot's main dialog.
import app from "./app/app";

// Marketplace and quota management
import { MarketplaceFulfillmentController } from "./marketplace/fulfillmentController";
import { QuotaUsageMiddleware } from "./middleware/quotaUsage";
import { marketplaceWebhookAuthMiddleware, apimAuthMiddleware } from "./utils/auth";
import { logger } from "./utils/logger";
import { AuditLogger } from "./utils/auditLogger";

// Create express application.
const expressApp = express();
expressApp.use(express.json());

// Add request ID middleware
expressApp.use((req, res, next) => {
  req.requestId = uuidv4();
  res.setHeader('x-request-id', req.requestId);
  next();
});

// Initialize services
const fulfillmentController = new MarketplaceFulfillmentController();
const quotaMiddleware = new QuotaUsageMiddleware({
  enabled: process.env.NODE_ENV !== 'development' || process.env.ENABLE_QUOTA === 'true',
  skipPaths: ['/marketplace', '/health', '/status']
});
const auditLogger = new AuditLogger();

// Health check endpoint
expressApp.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Marketplace webhook endpoints
expressApp.post('/marketplace/resolve', 
  marketplaceWebhookAuthMiddleware(),
  async (req, res) => {
    await fulfillmentController.resolve(req, res);
  }
);

expressApp.post('/marketplace/:subscriptionId/activate',
  marketplaceWebhookAuthMiddleware(), 
  async (req, res) => {
    await fulfillmentController.activate(req, res);
  }
);

expressApp.post('/marketplace/:subscriptionId/update',
  marketplaceWebhookAuthMiddleware(),
  async (req, res) => {
    await fulfillmentController.update(req, res);
  }
);

expressApp.post('/marketplace/:subscriptionId/deactivate',
  marketplaceWebhookAuthMiddleware(),
  async (req, res) => {
    await fulfillmentController.deactivate(req, res);
  }
);

// Apply quota middleware to bot endpoints
expressApp.use('/api/messages', quotaMiddleware.middleware());

// Listen for incoming bot requests.
expressApp.post("/api/messages", async (req, res) => {
  const requestId = req.requestId;
  
  try {
    logger.info('Processing bot message', { requestId });
    
    // Route received a request to adapter for processing
    await adapter.process(req, res as any, async (context) => {
      // Check quota for Teams context
      const quotaAllowed = await quotaMiddleware.processTeamsBotQuota(context);
      
      if (!quotaAllowed) {
        logger.warn('Bot message blocked by quota', { requestId });
        return; // Quota middleware already sent error message to user
      }
      
      // Dispatch to application for routing
      await app.run(context);
      
      // Log successful processing
      await auditLogger.log({
        action: 'bot.message.processed',
        tenantId: context.activity?.conversation?.tenantId,
        userId: context.activity?.from?.id,
        requestId,
        result: 'success'
      });
    });
    
  } catch (error) {
    logger.error('Error processing bot message', { error: error.message, requestId });
    
    await auditLogger.log({
      action: 'bot.message.error',
      requestId,
      result: 'error',
      details: { error: error.message }
    });
    
    // Don't expose internal errors to clients
    if (!res.headersSent) {
      res.status(500).json({ error: 'Internal server error' });
    }
  }
});

// Error handling middleware
expressApp.use((error: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  logger.error('Unhandled express error', { 
    error: error.message, 
    stack: error.stack,
    requestId: req.requestId 
  });
  
  if (!res.headersSent) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

const server = expressApp.listen(process.env.port || process.env.PORT || 3978, () => {
  console.log(`\nAgent started, ${expressApp.name} listening to`, server.address());
  logger.info('Microsoft 365 Agent with Quota Management started', {
    port: process.env.port || process.env.PORT || 3978,
    quotaEnabled: quotaMiddleware ? 'true' : 'false',
    environment: process.env.NODE_ENV || 'development'
  });
});
