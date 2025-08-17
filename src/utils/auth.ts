import { Request } from 'express';
import * as jwt from 'jsonwebtoken';
import { logger } from './logger';
import { getErrorMessage } from './errorHandler';

/**
 * Validates Microsoft Marketplace webhook signatures
 * @param req Express request object
 * @returns boolean indicating if the webhook is valid
 */
export function validateMarketplaceWebhook(req: Request): boolean {
  try {
    // In a real implementation, Microsoft would send a JWT token
    // in the Authorization header that needs to be validated
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      logger.warn('Missing or invalid authorization header in marketplace webhook');
      return false;
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix
    
    // For development/testing, you might want to skip validation
    if (process.env.NODE_ENV === 'development' && process.env.SKIP_WEBHOOK_VALIDATION === 'true') {
      logger.debug('Skipping webhook validation in development mode');
      return true;
    }

    // Validate JWT token
    const jwtSecret = process.env.JWT_SECRET_KEY;
    if (!jwtSecret) {
      logger.error('JWT_SECRET_KEY not configured for webhook validation');
      return false;
    }

    try {
      jwt.verify(token, jwtSecret);
      return true;
    } catch (jwtError) {
      logger.warn('Invalid JWT token in marketplace webhook', { error: getErrorMessage(jwtError) });
      return false;
    }

  } catch (error) {
    logger.error('Error validating marketplace webhook', { error: getErrorMessage(error) });
    return false;
  }
}

/**
 * Validates API subscription key from APIM
 * @param req Express request object
 * @returns boolean indicating if the subscription key is valid
 */
export function validateApimSubscriptionKey(req: Request): boolean {
  try {
    const subscriptionKey = req.headers['ocp-apim-subscription-key'] || req.headers['x-subscription-key'];
    
    if (!subscriptionKey) {
      logger.warn('Missing APIM subscription key');
      return false;
    }

    // In development, you might want to skip validation
    if (process.env.NODE_ENV === 'development' && process.env.SKIP_APIM_VALIDATION === 'true') {
      logger.debug('Skipping APIM validation in development mode');
      return true;
    }

    const expectedKey = process.env.APIM_SUBSCRIPTION_KEY;
    if (!expectedKey) {
      logger.error('APIM_SUBSCRIPTION_KEY not configured');
      return false;
    }

    return subscriptionKey === expectedKey;

  } catch (error) {
    logger.error('Error validating APIM subscription key', { error: getErrorMessage(error) });
    return false;
  }
}

/**
 * Extracts and validates tenant information from request
 * @param req Express request object
 * @returns Tenant ID if valid, null otherwise
 */
export function extractTenantId(req: Request): string | null {
  try {
    // Try to extract from various sources
    let tenantId = req.headers['x-tenant-id'] as string;
    
    if (!tenantId) {
      // Try to extract from JWT token if present
      const authHeader = req.headers.authorization;
      if (authHeader && authHeader.startsWith('Bearer ')) {
        const token = authHeader.substring(7);
        try {
          const decoded = jwt.decode(token) as any;
          tenantId = decoded?.tid || decoded?.tenantId;
        } catch {
          // Token decode failed, continue
        }
      }
    }

    if (!tenantId) {
      // Try to extract from query parameters
      tenantId = req.query.tenantId as string;
    }

    return tenantId || null;

  } catch (error) {
    logger.error('Error extracting tenant ID', { error: getErrorMessage(error) });
    return null;
  }
}

/**
 * Extracts user ID from request
 * @param req Express request object
 * @returns User ID if found, null otherwise
 */
export function extractUserId(req: Request): string | null {
  try {
    // Try to extract from headers
    let userId = req.headers['x-user-id'] as string;
    
    if (!userId) {
      // Try to extract from JWT token
      const authHeader = req.headers.authorization;
      if (authHeader && authHeader.startsWith('Bearer ')) {
        const token = authHeader.substring(7);
        try {
          const decoded = jwt.decode(token) as any;
          userId = decoded?.sub || decoded?.userId || decoded?.oid;
        } catch {
          // Token decode failed, continue
        }
      }
    }

    if (!userId) {
      // Try to extract from query parameters
      userId = req.query.userId as string;
    }

    return userId || null;

  } catch (error) {
    logger.error('Error extracting user ID', { error: getErrorMessage(error) });
    return null;
  }
}

/**
 * Middleware to validate requests coming through APIM
 */
export function apimAuthMiddleware() {
  return (req: Request, res: any, next: any) => {
    if (!validateApimSubscriptionKey(req)) {
      return res.status(401).json({ error: 'Invalid or missing subscription key' });
    }
    next();
  };
}

/**
 * Middleware to validate marketplace webhook requests
 */
export function marketplaceWebhookAuthMiddleware() {
  return (req: Request, res: any, next: any) => {
    if (!validateMarketplaceWebhook(req)) {
      return res.status(401).json({ error: 'Invalid or missing webhook authentication' });
    }
    next();
  };
}
