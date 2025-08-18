#!/bin/bash

# Deploy Application to Azure Web App - DEV-05 Environment
# This script builds and deploys the ChatBottez GPT-4.1 application to Azure Web App

set -e

echo "🚀 ChatBottez GPT-4.1 - Application Deployment (DEV-05)"
echo "======================================================="

# Configuration
WEB_APP_NAME="chatbottez-gpt41-app-rnukfj"
RESOURCE_GROUP="rg-chatbottez-gpt-4-1-dev-05"
KEY_VAULT_NAME="kv-gpt41-rnukfj"

echo "📋 Deployment Configuration:"
echo "   • Web App Name: $WEB_APP_NAME"
echo "   • Resource Group: $RESOURCE_GROUP"
echo "   • Key Vault: $KEY_VAULT_NAME"
echo ""

# Step 1: Build the application
echo "🔨 Step 1: Building application..."
npm ci
npm run build

if [ $? -eq 0 ]; then
    echo "✅ Application build successful!"
else
    echo "❌ Application build failed!"
    exit 1
fi

echo ""

# Step 2: Configure App Settings from Key Vault
echo "🔧 Step 2: Configuring App Settings from Key Vault..."

# Retrieve secrets from Key Vault
BOT_ID=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "BOT-ID" --query "value" --output tsv)
AZURE_OPENAI_API_KEY=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "AZURE-OPENAI-API-KEY" --query "value" --output tsv)
AZURE_OPENAI_ENDPOINT=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "AZURE-OPENAI-ENDPOINT" --query "value" --output tsv)
AZURE_OPENAI_DEPLOYMENT_NAME=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "AZURE-OPENAI-DEPLOYMENT-NAME" --query "value" --output tsv)
APPLICATION_INSIGHTS_CONNECTION_STRING=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "APPLICATION-INSIGHTS-CONNECTION-STRING" --query "value" --output tsv)

# Configure Web App settings
az webapp config appsettings set \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --settings \
        "BOT_ID=$BOT_ID" \
        "BOT_TYPE=MultiTenant" \
        "BOT_TENANT_ID=" \
        "BOT_PASSWORD=" \
        "AZURE_OPENAI_API_KEY=$AZURE_OPENAI_API_KEY" \
        "AZURE_OPENAI_ENDPOINT=$AZURE_OPENAI_ENDPOINT" \
        "AZURE_OPENAI_DEPLOYMENT_NAME=$AZURE_OPENAI_DEPLOYMENT_NAME" \
        "APPLICATION_INSIGHTS_CONNECTION_STRING=$APPLICATION_INSIGHTS_CONNECTION_STRING" \
        "NODE_ENV=production" \
        "WEBSITE_RUN_FROM_PACKAGE=1" \
    --output table

if [ $? -eq 0 ]; then
    echo "✅ App Settings configured successfully!"
else
    echo "❌ App Settings configuration failed!"
    exit 1
fi

echo ""

# Step 3: Create deployment package
echo "📦 Step 3: Creating deployment package..."
zip -r deployment.zip . -x "node_modules/*" "*.git*" "*.vscode*" "tests/*" "scripts/*" "*.md" "*.yml" "*.yaml"

if [ $? -eq 0 ]; then
    echo "✅ Deployment package created successfully!"
else
    echo "❌ Deployment package creation failed!"
    exit 1
fi

echo ""

# Step 4: Deploy to Azure Web App
echo "🚀 Step 4: Deploying to Azure Web App..."
az webapp deployment source config-zip \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --src "deployment.zip"

if [ $? -eq 0 ]; then
    echo "✅ Application deployed successfully!"
else
    echo "❌ Application deployment failed!"
    exit 1
fi

echo ""

# Step 5: Restart Web App
echo "🔄 Step 5: Restarting Web App..."
az webapp restart \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP"

if [ $? -eq 0 ]; then
    echo "✅ Web App restarted successfully!"
else
    echo "❌ Web App restart failed!"
    exit 1
fi

echo ""

# Step 6: Show deployment information
echo "📊 Step 6: Deployment Information:"
az webapp show \
    --name "$WEB_APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "{Name:name, State:state, DefaultHostName:defaultHostName, Kind:kind}" \
    --output table

echo ""
echo "🎉 Application deployment completed!"
echo "🌐 Application URL: https://$WEB_APP_NAME.azurewebsites.net"
echo "🤖 Bot Endpoint: https://$WEB_APP_NAME.azurewebsites.net/api/messages"

# Cleanup
rm -f deployment.zip

echo ""
echo "💡 Next steps:"
echo "   1. Test the bot endpoint: https://$WEB_APP_NAME.azurewebsites.net/api/messages"
echo "   2. Configure Teams App manifest if needed"
echo "   3. Test bot functionality in Teams"
