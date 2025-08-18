#!/bin/bash

# Clean Failed Deployments - DEV-05 Environment
# This script cleans up failed deployment resources and recreates what's needed

set -e

echo "🧹 ChatBottez GPT-4.1 - Cleanup Failed Deployments (DEV-05)"
echo "============================================================"

# Configuration
RESOURCE_GROUP="rg-chatbottez-gpt-4-1-dev-05"
FAILED_API_NAME="chatbot-api"
APIM_NAME="chatbottez-gpt41-apim-rnukfj"

echo "📋 Cleanup Configuration:"
echo "   • Resource Group: $RESOURCE_GROUP"
echo "   • APIM Name: $APIM_NAME"
echo "   • Failed API: $FAILED_API_NAME"
echo ""

# Step 1: Check if failed API exists and delete it
echo "🔍 Step 1: Checking for failed API..."
if az apim api show --service-name "$APIM_NAME" --resource-group "$RESOURCE_GROUP" --api-id "$FAILED_API_NAME" >/dev/null 2>&1; then
    echo "🗑️  Deleting failed API: $FAILED_API_NAME"
    az apim api delete \
        --service-name "$APIM_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --api-id "$FAILED_API_NAME" \
        --delete-revisions \
        --if-match "*"
    
    if [ $? -eq 0 ]; then
        echo "✅ Failed API deleted successfully!"
    else
        echo "❌ Failed to delete API!"
    fi
else
    echo "ℹ️  API $FAILED_API_NAME does not exist, nothing to clean."
fi

echo ""

# Step 2: List current APIM status
echo "📊 Step 2: Current APIM Status:"
az apim show \
    --name "$APIM_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "{Name:name, State:provisioningState, PublicIPs:publicIPAddresses, GatewayUrl:gatewayUrl}" \
    --output table

echo ""

# Step 3: List APIs in APIM
echo "📋 Step 3: Current APIs in APIM:"
az apim api list \
    --service-name "$APIM_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "[].{Name:name, DisplayName:displayName, Path:path, Protocols:protocols}" \
    --output table 2>/dev/null || echo "⚠️  No APIs found or APIM not ready"

echo ""

# Step 4: List recent failed deployments
echo "📊 Step 4: Recent Failed Deployments:"
az deployment sub list \
    --query "[?contains(name, 'complete-infrastructure-dev05') && properties.provisioningState=='Failed'].{Name:name, State:properties.provisioningState, Timestamp:properties.timestamp}" \
    --output table

echo ""
echo "✅ Cleanup completed!"
echo ""
echo "💡 Next steps:"
echo "   1. Run the corrected deployment: make deploy-dev05"
echo "   2. Monitor with: make status-deployment"
echo "   3. Once successful, deploy app: make deploy-app-dev05"
