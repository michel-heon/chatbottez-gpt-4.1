#!/bin/bash
# Deploy ChatBottez GPT-4.1 Application to DEV-05 (WSL)
set -e

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Configuration
WEB_APP_NAME="chatbottez-gpt41-app-rnukfj"
RESOURCE_GROUP="rg-chatbottez-gpt-4-1-dev-05"
KEY_VAULT_NAME="kv-gpt41-rnukfj"

echo "======================================================"
echo "🚀 ChatBottez GPT-4.1 - Application Deployment (DEV-05)"
echo "======================================================"
echo "📋 Deployment Configuration:"
echo "   • Web App Name: $WEB_APP_NAME"
echo "   • Resource Group: $RESOURCE_GROUP"
echo "   • Key Vault: $KEY_VAULT_NAME"
echo ""

# Change to project directory
cd /mnt/c/01-PROJET-UQAM/00-GIT/GPT-4.1

# Step 1: Build application
echo "🔨 Step 1: Building application..."
npm run build
echo "✅ Application built successfully!"

# Step 2: Get OpenAI API key from Key Vault
echo "🔑 Step 2: Retrieving OpenAI API key from Key Vault..."
OPENAI_API_KEY=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "openai-api-key" --query value -o tsv)
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ Error: Failed to retrieve OpenAI API key from Key Vault"
    exit 1
fi
echo "✅ OpenAI API key retrieved successfully"

# Step 3: Update App Service configuration
echo "⚙️  Step 3: Updating App Service configuration..."
az webapp config appsettings set \
    --resource-group "$RESOURCE_GROUP" \
    --name "$WEB_APP_NAME" \
    --settings \
        OPENAI_API_KEY="$OPENAI_API_KEY" \
        NODE_ENV=production \
        WEBSITE_NODE_DEFAULT_VERSION="~22" \
        WEBSITE_RUN_FROM_PACKAGE=1
echo "✅ App Service configuration updated"

# Step 4: Create deployment package
echo "📦 Step 4: Creating deployment package..."
rm -f deploy.zip

# Create zip package with application files
zip -r deploy.zip lib/ package.json package-lock.json appPackage/ -x "*.git*" "node_modules/*"
echo "✅ Deployment package created: deploy.zip"

# Step 5: Deploy to Azure Web App
echo "🚀 Step 5: Deploying to Azure Web App..."
az webapp deployment source config-zip \
    --resource-group "$RESOURCE_GROUP" \
    --name "$WEB_APP_NAME" \
    --src deploy.zip
echo "✅ Application deployed successfully!"

# Step 6: Restart Web App
echo "🔄 Step 6: Restarting Web App..."
az webapp restart \
    --resource-group "$RESOURCE_GROUP" \
    --name "$WEB_APP_NAME"
echo "✅ Web App restarted successfully!"

# Step 7: Get deployment information
echo "🌐 Step 7: Getting deployment information..."
APP_URL=$(az webapp show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$WEB_APP_NAME" \
    --query defaultHostName -o tsv)

echo ""
echo "🎉 ChatBottez GPT-4.1 Deployment Complete!"
echo "================================================"
echo "🌐 Application URL: https://$APP_URL"
echo "📊 Resource Group: $RESOURCE_GROUP"
echo "🔧 Web App Name: $WEB_APP_NAME"
echo ""
echo "✅ The ChatBottez GPT-4.1 application is now live and ready to use!"
echo "💬 You can now test the Microsoft Teams bot integration."

# Cleanup
rm -f deploy.zip
echo "🧹 Deployment package cleaned up"

echo ""
echo "🚀 Deployment script completed successfully!"
