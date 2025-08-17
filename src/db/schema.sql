-- Database schema for Microsoft Marketplace quota management

-- Table for storing subscription information
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    marketplace_subscription_id VARCHAR(255) UNIQUE NOT NULL,
    tenant_id VARCHAR(255) NOT NULL,
    plan_id VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('PendingFulfillmentStart', 'Subscribed', 'Suspended', 'Unsubscribed')),
    activated_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    quantity_included INTEGER DEFAULT 300,
    dimension VARCHAR(50) DEFAULT 'question',
    overage_enabled BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for storing usage events
CREATE TABLE usage_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE CASCADE,
    event_id VARCHAR(255) UNIQUE NOT NULL,
    dimension VARCHAR(50) NOT NULL,
    quantity INTEGER NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP,
    error_message TEXT
);

-- Table for audit logs
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action VARCHAR(100) NOT NULL,
    tenant_id VARCHAR(255),
    user_id VARCHAR(255),
    subscription_id VARCHAR(255),
    request_id VARCHAR(255),
    result VARCHAR(20) NOT NULL CHECK (result IN ('success', 'error', 'blocked', 'warning')),
    details JSONB,
    ip_address INET,
    user_agent TEXT
);

-- Indexes for performance
CREATE INDEX idx_subscriptions_marketplace_id ON subscriptions(marketplace_subscription_id);
CREATE INDEX idx_subscriptions_tenant_id ON subscriptions(tenant_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);

CREATE INDEX idx_usage_events_subscription_id ON usage_events(subscription_id);
CREATE INDEX idx_usage_events_timestamp ON usage_events(timestamp);
CREATE INDEX idx_usage_events_status ON usage_events(status);
CREATE INDEX idx_usage_events_retry_count ON usage_events(retry_count) WHERE status = 'failed';

CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_tenant_id ON audit_logs(tenant_id);
CREATE INDEX idx_audit_logs_subscription_id ON audit_logs(subscription_id);

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_subscriptions_updated_at 
    BEFORE UPDATE ON subscriptions 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Function to get current month usage for a subscription
CREATE OR REPLACE FUNCTION get_current_month_usage(sub_id UUID)
RETURNS INTEGER AS $$
DECLARE
    usage_count INTEGER;
BEGIN
    SELECT COALESCE(SUM(quantity), 0)
    INTO usage_count
    FROM usage_events
    WHERE subscription_id = sub_id
      AND status = 'sent'
      AND timestamp >= DATE_TRUNC('month', CURRENT_TIMESTAMP)
      AND timestamp < DATE_TRUNC('month', CURRENT_TIMESTAMP) + INTERVAL '1 month';
    
    RETURN usage_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get usage for a specific time period
CREATE OR REPLACE FUNCTION get_usage_for_period(sub_id UUID, start_date TIMESTAMP, end_date TIMESTAMP)
RETURNS INTEGER AS $$
DECLARE
    usage_count INTEGER;
BEGIN
    SELECT COALESCE(SUM(quantity), 0)
    INTO usage_count
    FROM usage_events
    WHERE subscription_id = sub_id
      AND status = 'sent'
      AND timestamp >= start_date
      AND timestamp < end_date;
    
    RETURN usage_count;
END;
$$ LANGUAGE plpgsql;

-- View for subscription summary with current usage
CREATE VIEW subscription_summary AS
SELECT 
    s.id,
    s.marketplace_subscription_id,
    s.tenant_id,
    s.plan_id,
    s.status,
    s.quantity_included,
    s.dimension,
    s.overage_enabled,
    s.activated_at,
    s.updated_at,
    get_current_month_usage(s.id) as current_month_usage,
    s.quantity_included - get_current_month_usage(s.id) as remaining_quota
FROM subscriptions s
WHERE s.status = 'Subscribed';

-- View for failed usage events that need retry
CREATE VIEW failed_usage_events AS
SELECT *
FROM usage_events
WHERE status = 'failed'
  AND retry_count < 5
ORDER BY created_at ASC;

-- View for audit log summary
CREATE VIEW audit_summary AS
SELECT 
    DATE_TRUNC('day', timestamp) as date,
    action,
    result,
    COUNT(*) as count
FROM audit_logs
WHERE timestamp >= CURRENT_TIMESTAMP - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', timestamp), action, result
ORDER BY date DESC, action;

-- Sample data for development (remove in production)
INSERT INTO subscriptions (
    marketplace_subscription_id,
    tenant_id,
    plan_id,
    status,
    activated_at,
    quantity_included,
    dimension,
    overage_enabled
) VALUES (
    'msft-sub-dev-123',
    'tenant-dev-456',
    'basic-plan',
    'Subscribed',
    CURRENT_TIMESTAMP,
    300,
    'question',
    false
) ON CONFLICT (marketplace_subscription_id) DO NOTHING;

-- Grant permissions (adjust as needed for your environment)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON subscriptions TO marketplace_app;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON usage_events TO marketplace_app;
-- GRANT SELECT, INSERT ON audit_logs TO marketplace_app;
-- GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO marketplace_app;
