#!/bin/bash

# Deploy Complete Infrastructure for ChatBottez GPT-4.1 - DEV-05 Environment
# This script deploys the complete infrastructure including Resource Group, PostgreSQL, Key Vault, APIM, Web App, etc.

set -e

echo "🚀 ChatBottez GPT-4.1 - Complete Infrastructure Deployment (DEV-05)"
echo "=================================================================="

# Configuration
DEPLOYMENT_NAME="complete-infrastructure-dev05-$(date +%Y%m%d-%H%M%S)"
LOCATION="Canada Central"
TEMPLATE_FILE="infra/complete-infrastructure-dev05.bicep"
PARAMETERS_FILE="infra/complete-infrastructure-dev05.parameters.json"
TARGET_RG="rg-chatbottez-gpt-4-1-dev-05"

echo "📋 Deployment Configuration:"
echo "   • Deployment Name: $DEPLOYMENT_NAME"
echo "   • Location: $LOCATION"
echo "   • Template: $TEMPLATE_FILE"
echo "   • Parameters: $PARAMETERS_FILE"
echo "   • Target RG: $TARGET_RG"
echo ""

# Step 1: Validate template
echo "🔍 Step 1: Validating Bicep template..."
az deployment sub validate \
    --location "$LOCATION" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "@$PARAMETERS_FILE" \
    --output table

if [ $? -eq 0 ]; then
    echo "✅ Template validation successful!"
else
    echo "❌ Template validation failed!"
    exit 1
fi

echo ""

# Step 2: Preview deployment (What-If)
echo "🔮 Step 2: Previewing deployment changes (What-If)..."
az deployment sub what-if \
    --location "$LOCATION" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "@$PARAMETERS_FILE" \
    --output table

echo ""

# Step 3: Confirm deployment
echo "⚠️  This will deploy complete infrastructure to Azure subscription."
echo "   • Resource Group: $TARGET_RG"
echo "   • Environment: DEV-05"
echo "   • Components: PostgreSQL, Key Vault, APIM, Web App, Application Insights, Bot Registration"
echo "   • Optimized naming: Fixed Key Vault length issues"
echo ""
read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled by user."
    exit 1
fi

echo ""

# Step 4: Deploy infrastructure
echo "🚀 Step 4: Deploying complete infrastructure..."
echo "⏱️  This may take 20-30 minutes..."

az deployment sub create \
    --name "$DEPLOYMENT_NAME" \
    --location "$LOCATION" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "@$PARAMETERS_FILE" \
    --output table

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Infrastructure deployment completed successfully!"
    echo ""
    
    # Step 5: Display deployment outputs
    echo "📊 Deployment outputs:"
    az deployment sub show \
        --name "$DEPLOYMENT_NAME" \
        --query "properties.outputs" \
        --output table
        
    echo ""
    echo "✅ Next steps:"
    echo "   1. Configure Azure OpenAI API key in Key Vault"
    echo "   2. Deploy application code to Web App"
    echo "   3. Configure Teams Bot registration"
    echo "   4. Test end-to-end functionality"
    echo ""
    echo "🔗 Useful commands:"
    echo "   • List resources: az resource list --resource-group $TARGET_RG --output table"
    echo "   • Check status: make status-deployment"
    
else
    echo "❌ Infrastructure deployment failed!"
    echo ""
    echo "🔍 Check deployment status:"
    echo "   az deployment sub show --name '$DEPLOYMENT_NAME' --query 'properties.error' --output table"
    exit 1
fi
