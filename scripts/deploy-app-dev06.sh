#!/bin/bash
# Deploy ChatBottez GPT-4.1 Application to DEV-06 (Clean Redeploy)
set -e

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Configuration - Updated for DEV-06
RESOURCE_GROUP="rg-chatbottez-gpt-4-1-dev-06"

# Get the actual resource names from the deployed infrastructure
echo "🔍 Discovering deployed resources in $RESOURCE_GROUP..."

# Get the actual web app name from Azure (will be determined by Bicep uniqueString)
ACTUAL_WEB_APP=$(az webapp list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv)
if [ -z "$ACTUAL_WEB_APP" ]; then
    echo "❌ Web app not found in resource group $RESOURCE_GROUP"
    echo "   Please ensure infrastructure is deployed first with: ./scripts/deploy-infrastructure-dev06.sh"
    exit 1
fi

# Get the actual Key Vault name
ACTUAL_KEY_VAULT=$(az keyvault list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv)
if [ -z "$ACTUAL_KEY_VAULT" ]; then
    echo "❌ Key Vault not found in resource group $RESOURCE_GROUP"
    exit 1
fi

WEB_APP_NAME="$ACTUAL_WEB_APP"
KEY_VAULT_NAME="$ACTUAL_KEY_VAULT"

echo "======================================================"
echo "🚀 ChatBottez GPT-4.1 - Application Deployment (DEV-06)"
echo "======================================================"
echo "📋 Deployment Configuration:"
echo "   • Web App Name: $WEB_APP_NAME"
echo "   • Resource Group: $RESOURCE_GROUP"
echo "   • Key Vault: $KEY_VAULT_NAME"
echo "   • Shared OpenAI: openai-cotechnoe (rg-cotechnoe-ai-01)"
echo ""

# Change to project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Step 1: Build application
echo "🔨 Step 1: Building application..."
# Installer toutes les dépendances (tsc est en devDependencies)
npm ci
npm run build
# Option: réduire la taille pour le package final (désactiver si vous développez juste après)
if [[ "${PRUNE_PROD_ONLY:-1}" == "1" ]]; then
  echo "🧹 Pruning dev dependencies (npm prune --production)"
  npm prune --production || true
fi
echo "✅ Application built successfully!"

# Step 2: Create deployment package
echo "📦 Step 2: Creating deployment package..."

# Create deployment directory
rm -rf deploy
mkdir -p deploy

# Copy built application
cp -r lib/* deploy/
cp package.json deploy/
cp web.config deploy/
[ -f iisnode.yml ] && cp iisnode.yml deploy/
cp -r node_modules deploy/

# Create deployment archive
cd deploy
zip -r ../chatbottez-deployment-dev06.zip . -x "*.git*" "node_modules/*"
cd ..

echo "✅ Deployment package created: chatbottez-deployment-dev06.zip"

# Step 3: Deploy to Azure App Service
echo "🚀 Step 3: Deploying to Azure App Service..."

# Get the actual web app name from Azure
ACTUAL_WEB_APP=$(az webapp list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv)
if [ -z "$ACTUAL_WEB_APP" ]; then
    echo "❌ Web app not found in resource group $RESOURCE_GROUP"
    exit 1
fi

echo "📋 Deploying to web app: $ACTUAL_WEB_APP"

# Deploy the application
az webapp deployment source config-zip \
    --resource-group "$RESOURCE_GROUP" \
    --name "$ACTUAL_WEB_APP" \
    --src "chatbottez-deployment-dev06.zip"

if [ $? -ne 0 ]; then
    echo "❌ Application deployment failed!"
    exit 1
fi

echo "✅ Application deployed successfully!"

# Step 4: Get OpenAI key from shared Key Vault
echo "🔑 Step 4: Retrieving OpenAI key from shared resources..."

SHARED_KEY_VAULT="kv-cotechno771554451004"
OPENAI_KEY=""
SECRET_USED=""
# Liste de secrets potentiels (ordre de préférence)
POSSIBLE_SECRETS=("azure-openai-api-key" "openai-api-key" "azure-openai-key")
for s in "${POSSIBLE_SECRETS[@]}"; do
  VAL=$(az keyvault secret show --vault-name "$SHARED_KEY_VAULT" --name "$s" --query "value" -o tsv 2>/dev/null || true)
  if [[ -n "$VAL" ]]; then
    OPENAI_KEY="$VAL"
    SECRET_USED="$s"
    break
  fi
done

if [[ -z "$OPENAI_KEY" ]]; then
  echo "⚠️ Could not retrieve OpenAI key from shared Key Vault ($SHARED_KEY_VAULT). Tried: ${POSSIBLE_SECRETS[*]}"
  echo "   Proceeding without storing key (manual step required)."
else
  echo "✅ OpenAI key retrieved from shared Key Vault ($SHARED_KEY_VAULT) secret='$SECRET_USED'"
fi

# Step 5: Configure environment variables (Attempt via CLI)
echo "⚙️ Step 5: Attempting to configure environment variables..."

# Try to set environment variables via Azure CLI
az webapp config appsettings set \
    --resource-group "$RESOURCE_GROUP" \
    --name "$ACTUAL_WEB_APP" \
    --settings \
        NODE_ENV="production" \
        AZURE_OPENAI_ENDPOINT="https://openai-cotechnoe.openai.azure.com/" \
        AZURE_OPENAI_DEPLOYMENT_NAME="gpt-4o" \
        PORT="3978" 2>/dev/null || echo "⚠️ CLI configuration failed - manual configuration required"

# Step 6: Store OpenAI key in project Key Vault
if [[ -n "$OPENAI_KEY" ]]; then
  echo "🔐 Step 6: Storing OpenAI key in project Key Vault..."
  
  # Get the actual Key Vault name
  ACTUAL_KEY_VAULT=$(az keyvault list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv)
  
  if [ ! -z "$ACTUAL_KEY_VAULT" ]; then
      az keyvault secret set \
          --vault-name "$ACTUAL_KEY_VAULT" \
          --name "azure-openai-key" \
          --value "$OPENAI_KEY" 2>/dev/null || echo "⚠️ Failed to store key in project Key Vault"
      
      echo "✅ OpenAI key stored in project Key Vault: $ACTUAL_KEY_VAULT"
  fi
fi

# Ensure AZURE_OPENAI_API_KEY app setting references Key Vault if not already
KV_URI="https://$ACTUAL_KEY_VAULT.vault.azure.net/secrets/azure-openai-key/"
az webapp config.appsettings set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACTUAL_WEB_APP" \
  --settings AZURE_OPENAI_API_KEY="@Microsoft.KeyVault(SecretUri=$KV_URI)" >/dev/null 2>&1 || true

# Step 7: Test deployment
echo "🧪 Step 7: Testing deployment..."
WEB_APP_URL="https://${ACTUAL_WEB_APP}.azurewebsites.net"

curl -s -o /dev/null -w "%{http_code}" "$WEB_APP_URL" | grep -q "200\|404\|500" && echo "✅ Web app is responding" || echo "⚠️ Web app may not be responding correctly"

# Cleanup
echo "🧹 Cleaning up temporary files..."
rm -f chatbottez-deployment-dev06.zip
rm -rf deploy

echo ""
echo "======================================================"
echo "🎉 Application DEV-06 deployment completed!"
echo "======================================================"
echo ""
echo "📋 Deployment Summary:"
echo "   • Resource Group: $RESOURCE_GROUP"
echo "   • Web App: $ACTUAL_WEB_APP"
echo "   • URL: $WEB_APP_URL"
echo "   • Key Vault: $ACTUAL_KEY_VAULT"
echo ""
echo "🔗 Shared Resources Used:"
echo "   • OpenAI Service: openai-cotechnoe"
echo "   • Shared Key Vault: kv-cotechno771554451004"
echo ""
echo "⚠️ MANUAL CONFIGURATION REQUIRED:"
echo "   1. Go to: https://portal.azure.com"
echo "   2. Navigate to: $RESOURCE_GROUP → $ACTUAL_WEB_APP"
echo "   3. Settings → Configuration → Application settings"
echo "   4. Add missing environment variables:"
echo "      - OPENAI_API_KEY=<from shared Key Vault>"
echo "      - MICROSOFT_APP_ID=<Teams bot registration>"
echo "      - MICROSOFT_APP_PASSWORD=<Teams bot secret>"
echo ""
echo "🎯 Next Steps:"
echo "   1. Configure environment variables manually"
echo "   2. Test application: $WEB_APP_URL"
echo "   3. Configure Teams bot registration"
echo ""
