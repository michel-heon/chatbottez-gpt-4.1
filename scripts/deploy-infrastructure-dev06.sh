#!/bin/bash
# Deploy ChatBottez GPT-4.1 Infrastructure to DEV-06 (Clean Redeploy)
set -e

# Configuration
RESOURCE_GROUP="rg-chatbottez-gpt-4-1-dev-06"
LOCATION="Canada Central"
SUBSCRIPTION_ID="0f1323ea-0f29-4187-9872-e1cf15d677de"

echo "======================================================"
echo "🚀 ChatBottez GPT-4.1 - Infrastructure Redeploy (DEV-06)"
echo "======================================================"
echo "📋 Deployment Configuration:"
echo "   • Target Resource Group: $RESOURCE_GROUP"
echo "   • Location: $LOCATION"
echo "   • Subscription: $SUBSCRIPTION_ID"
echo "   • Shared Resources: rg-cotechnoe-ai-01"
echo ""

# Step 1: Verify Azure CLI login
echo "🔐 Step 1: Verifying Azure CLI authentication..."
az account show --query "id" -o tsv
if [ $? -ne 0 ]; then
    echo "❌ Azure CLI not authenticated. Please run: az login"
    exit 1
fi
echo "✅ Azure CLI authenticated successfully!"
echo ""

# Step 2: Set correct subscription
echo "🎯 Step 2: Setting target subscription..."
az account set --subscription "$SUBSCRIPTION_ID"
echo "✅ Subscription set to: $SUBSCRIPTION_ID"
echo ""

# Step 3: Validate Bicep template
echo "📋 Step 3: Validating Bicep template..."
az deployment sub validate \
    --location "$LOCATION" \
    --template-file "infra/complete-infrastructure-dev06.bicep" \
    --parameters "@infra/complete-infrastructure-dev06.parameters.json"

if [ $? -ne 0 ]; then
    echo "❌ Bicep template validation failed!"
    exit 1
fi
echo "✅ Bicep template validation successful!"
echo ""

# Step 4: Check shared resources exist
echo "🔍 Step 4: Verifying shared resources in rg-cotechnoe-ai-01..."
SHARED_RG_EXISTS=$(az group exists --name "rg-cotechnoe-ai-01")
if [ "$SHARED_RG_EXISTS" = "false" ]; then
    echo "❌ Shared resource group 'rg-cotechnoe-ai-01' not found!"
    exit 1
fi

OPENAI_EXISTS=$(az cognitiveservices account show --name "openai-cotechnoe" --resource-group "rg-cotechnoe-ai-01" --query "id" -o tsv 2>/dev/null)
if [ -z "$OPENAI_EXISTS" ]; then
    echo "❌ Shared OpenAI service 'openai-cotechnoe' not found!"
    exit 1
fi

echo "✅ Shared resources validated successfully!"
echo "   • OpenAI Service: openai-cotechnoe"
echo "   • Shared Resource Group: rg-cotechnoe-ai-01"
echo ""

# Step 5: Deploy infrastructure
echo "🏗️ Step 5: Deploying infrastructure to DEV-06..."
DEPLOYMENT_NAME="chatbottez-infrastructure-dev06-$(date +%Y%m%d-%H%M%S)"

az deployment sub create \
    --location "$LOCATION" \
    --template-file "infra/complete-infrastructure-dev06.bicep" \
    --parameters "@infra/complete-infrastructure-dev06.parameters.json" \
    --name "$DEPLOYMENT_NAME"

if [ $? -ne 0 ]; then
    echo "❌ Infrastructure deployment failed!"
    exit 1
fi
echo "✅ Infrastructure deployment completed successfully!"
echo ""

# Step 6: Get deployment outputs
echo "📊 Step 6: Retrieving deployment information..."
DEPLOYMENT_OUTPUT=$(az deployment sub show \
    --name "$DEPLOYMENT_NAME" \
    --query "properties.outputs" -o json)

WEB_APP_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.webAppName.value')
WEB_APP_URL=$(echo $DEPLOYMENT_OUTPUT | jq -r '.webAppUrl.value')
KEY_VAULT_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.keyVaultName.value')
POSTGRES_SERVER=$(echo $DEPLOYMENT_OUTPUT | jq -r '.postgresServerName.value')

echo "✅ Deployment completed successfully!"
echo ""
echo "📋 New DEV-06 Resources Created:"
echo "   • Resource Group: $RESOURCE_GROUP"
echo "   • Web App: $WEB_APP_NAME"
echo "   • Web App URL: $WEB_APP_URL"
echo "   • Key Vault: $KEY_VAULT_NAME"
echo "   • PostgreSQL: $POSTGRES_SERVER"
echo ""
echo "🔗 Mutualized Resources (from rg-cotechnoe-ai-01):"
echo "   • OpenAI Service: openai-cotechnoe"
echo "   • OpenAI Endpoint: https://openai-cotechnoe.openai.azure.com/"
echo "   • Shared Key Vault: kv-cotechno771554451004"
echo ""
echo "🎯 Next Steps:"
echo "   1. Run: ./scripts/deploy-app-dev06.sh"
echo "   2. Configure environment variables via Azure Portal"
echo "   3. Test application functionality"
echo ""
echo "======================================================"
echo "🎉 Infrastructure DEV-06 deployment completed!"
echo "======================================================"
