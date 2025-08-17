# Deployment Guide - Microsoft 365 Agent with Marketplace Quotas

This guide provides step-by-step instructions for deploying the Microsoft 365 Agent with marketplace quota management to production.

## Prerequisites

Before deployment, ensure you have:

- [ ] Azure subscription with sufficient permissions
- [ ] Microsoft Partner Center account
- [ ] Azure API Management instance
- [ ] PostgreSQL or SQL Server database
- [ ] Azure OpenAI resource
- [ ] Teams app registration

## Step 1: Environment Configuration

1. **Copy environment template**:
   ```bash
   cp .env.example .env.production
   ```

2. **Configure marketplace settings** in `.env.production`:
   ```bash
   # Marketplace API Configuration
   MARKETPLACE_API_BASE=https://marketplaceapi.microsoft.com
   MARKETPLACE_API_KEY=your-partner-center-api-key
   MARKETPLACE_SUBSCRIPTION_API_VERSION=2018-08-31
   MARKETPLACE_METERING_API_VERSION=2018-08-31

   # Quota Settings
   DIMENSION_NAME=question
   INCLUDED_QUOTA_PER_MONTH=300
   OVERAGE_ENABLED=false

   # Database Configuration
   DATABASE_URL=postgresql://user:password@host:port/database

   # Azure OpenAI
   AZURE_OPENAI_API_KEY=your-azure-openai-key
   AZURE_OPENAI_ENDPOINT=https://your-openai.openai.azure.com/
   AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4

   # Security
   JWT_SECRET_KEY=your-jwt-secret-for-webhook-validation
   APIM_SUBSCRIPTION_KEY=your-apim-subscription-key
   ```

## Step 2: Database Setup

1. **Create database**:
   ```sql
   CREATE DATABASE marketplace_quota;
   ```

2. **Run schema migration**:
   ```bash
   psql -d marketplace_quota -f src/db/schema.sql
   ```

3. **Verify tables created**:
   ```sql
   \dt
   # Should show: subscriptions, usage_events, audit_logs
   ```

## Step 3: Azure API Management Deployment

1. **Deploy APIM infrastructure**:
   ```bash
   az deployment group create \
     --resource-group your-resource-group \
     --template-file infra/apim/apim.bicep \
     --parameters \
       apimServiceName=your-apim-service \
       publisherEmail=admin@yourcompany.com \
       publisherName="Your Company" \
       backendServiceUrl=https://your-bot-app.azurewebsites.net
   ```

2. **Configure Event Hub for logging** (optional but recommended):
   ```bash
   az eventhubs namespace create \
     --resource-group your-resource-group \
     --name your-eventhub-namespace \
     --sku Standard
   
   az eventhubs eventhub create \
     --resource-group your-resource-group \
     --namespace-name your-eventhub-namespace \
     --name quota-audit
   ```

## Step 4: Application Deployment

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Build application**:
   ```bash
   npm run build
   ```

3. **Deploy to Azure App Service**:
   ```bash
   # Using Teams Toolkit
   npx teamsfx deploy --env production

   # Or using Azure CLI
   az webapp deployment source config-zip \
     --resource-group your-resource-group \
     --name your-webapp \
     --src ./dist.zip
   ```

4. **Configure App Service settings**:
   ```bash
   az webapp config appsettings set \
     --resource-group your-resource-group \
     --name your-webapp \
     --settings @appsettings.json
   ```

## Step 5: Microsoft Partner Center Configuration

1. **Create SaaS offer** in Partner Center:
   - Go to Commercial Marketplace → Offers
   - Create new SaaS offer
   - Configure plan with 300 questions/month
   - Set up metered dimension: "question"

2. **Configure webhook endpoints**:
   - Landing page: `https://your-app.azurewebsites.net/marketplace/resolve`
   - Connection webhook: `https://your-app.azurewebsites.net/marketplace/{subscriptionId}/activate`

3. **Set up metered billing**:
   - Dimension: "question"
   - Unit of measure: "Questions"
   - Price per unit: $0.01 (if overage enabled)

## Step 6: Teams App Configuration

1. **Update manifest** with production URLs:
   ```json
   {
     "bots": [{
       "botId": "your-production-bot-id",
       "scopes": ["team", "groupChat", "personal"]
     }],
     "validDomains": [
       "your-app.azurewebsites.net"
     ]
   }
   ```

2. **Upload to Teams Admin Center**:
   ```bash
   npx teamsfx publish --env production
   ```

## Step 7: Monitoring Setup

1. **Configure Application Insights**:
   ```bash
   az monitor app-insights component create \
     --app your-app-insights \
     --location eastus \
     --resource-group your-resource-group
   ```

2. **Set up alerts**:
   - Quota usage > 80%
   - Failed usage event publishing
   - High error rates
   - APIM quota exceeded events

3. **Configure Log Analytics**:
   ```bash
   az monitor log-analytics workspace create \
     --resource-group your-resource-group \
     --workspace-name your-workspace
   ```

## Step 8: Security Configuration

1. **Configure Key Vault** (recommended):
   ```bash
   az keyvault create \
     --resource-group your-resource-group \
     --name your-keyvault
   ```

2. **Store secrets**:
   ```bash
   az keyvault secret set --vault-name your-keyvault --name "marketplace-api-key" --value "your-key"
   az keyvault secret set --vault-name your-keyvault --name "jwt-secret" --value "your-jwt-secret"
   ```

3. **Configure managed identity**:
   ```bash
   az webapp identity assign \
     --resource-group your-resource-group \
     --name your-webapp
   ```

## Step 9: Testing

1. **Run integration tests**:
   ```bash
   npm run test:integration
   ```

2. **Test marketplace webhooks**:
   ```bash
   curl -X POST https://your-app.azurewebsites.net/marketplace/resolve \
     -H "Authorization: Bearer your-test-token" \
     -H "Content-Type: application/json" \
     -d '{"token": "test-marketplace-token"}'
   ```

3. **Test quota enforcement**:
   ```bash
   # Send test messages through APIM
   curl -X POST https://your-apim.azure-api.net/chatbot/api/messages \
     -H "Ocp-Apim-Subscription-Key: your-subscription-key" \
     -H "Content-Type: application/json" \
     -d '{"type": "message", "text": "Hello"}'
   ```

## Step 10: Go Live

1. **Submit offer for certification** in Partner Center
2. **Configure DNS** (if using custom domain)
3. **Update Teams app** in admin center
4. **Monitor deployment** via Application Insights
5. **Set up backup procedures**

## Post-Deployment Checklist

- [ ] Verify all endpoints are responding
- [ ] Check APIM quota policies are working
- [ ] Confirm usage events are being published
- [ ] Test Teams app functionality
- [ ] Verify monitoring and alerts
- [ ] Review security settings
- [ ] Test backup and recovery procedures
- [ ] Document any custom configurations

## Troubleshooting

### Common Issues

1. **APIM quota not working**:
   - Check policy configuration
   - Verify subscription keys
   - Review APIM logs

2. **Usage events not publishing**:
   - Check marketplace API credentials
   - Verify webhook authentication
   - Review application logs

3. **Teams app not loading**:
   - Check bot registration
   - Verify Azure OpenAI connection
   - Review application insights

### Log Locations

- Application logs: Azure App Service → Log Stream
- APIM logs: API Management → Analytics
- Usage events: Event Hub → Capture files
- Audit logs: Log Analytics workspace

### Support

For issues:
1. Check Application Insights for errors
2. Review Azure Monitor metrics
3. Contact Microsoft Partner Center support for marketplace issues
4. Refer to Teams AI Library documentation

## Rollback Procedure

If deployment fails:

1. **Revert App Service deployment**:
   ```bash
   az webapp deployment slot swap \
     --resource-group your-resource-group \
     --name your-webapp \
     --slot staging \
     --target-slot production
   ```

2. **Revert database changes** (if applicable)
3. **Update Teams app manifest** to previous version
4. **Verify APIM configuration** is restored

## Maintenance

### Regular Tasks

- Monitor quota usage trends
- Review usage event publishing rates
- Update marketplace API credentials
- Check APIM policy performance
- Review audit logs for anomalies

### Updates

- Test new features in staging environment
- Coordinate with Partner Center for offer updates
- Update APIM policies if quota changes
- Maintain database schema migrations
