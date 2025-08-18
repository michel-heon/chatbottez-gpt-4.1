targetScope = 'subscription'

@description('Base name for all resources')
param resourceBaseName string

@description('Environment name (dev, staging, prod)')
param environment string

@description('Location for all resources')
param location string

@description('Publisher email for API Management')
param publisherEmail string

@description('Publisher name for API Management')
param publisherName string

@description('PostgreSQL administrator login')
@secure()
param postgresAdminLogin string

@description('PostgreSQL administrator password')
@secure()
param postgresAdminPassword string

// ============================================================================
// VARIABLES
// ============================================================================

var targetResourceGroupName = 'rg-chatbottez-gpt-4-1-dev-06'
var uniqueSuffix = substring(uniqueString(subscription().id, targetResourceGroupName), 0, 6)

// Resource names (optimized for length limits)
var postgresServerName = '${resourceBaseName}-pg-${uniqueSuffix}'
var keyVaultName = 'kv-gpt41-${uniqueSuffix}'
var apimName = '${resourceBaseName}-apim-${uniqueSuffix}'
var appInsightsName = '${resourceBaseName}-ai-${uniqueSuffix}'
var appServicePlanName = '${resourceBaseName}-plan-${uniqueSuffix}'
var webAppName = '${resourceBaseName}-app-${uniqueSuffix}'
var logAnalyticsWorkspaceName = '${resourceBaseName}-law-${uniqueSuffix}'
var quotaDatabaseName = 'marketplace_quota'

// Shared resources configuration (mutualized from rg-cotechnoe-ai-01)
var sharedResourceGroupName = 'rg-cotechnoe-ai-01'
var sharedOpenAIName = 'openai-cotechnoe'
var sharedKeyVaultName = 'kv-cotechno771554451004'
var sharedOpenAIEndpoint = 'https://openai-cotechnoe.openai.azure.com/'
var sharedOpenAIDeploymentName = 'gpt-4o'

// ============================================================================
// RESOURCE GROUP
// ============================================================================

resource targetResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: targetResourceGroupName
  location: location
  tags: {
    environment: environment
    project: 'ChatBottez GPT-4.1'
    version: 'v1.7.0-step6-dev06-redeploy'
    'cost-center': 'AI-Development'
    'azd-env-name': environment
  }
}

// ============================================================================
// EXISTING SHARED RESOURCES REFERENCE
// ============================================================================

// Reference to existing shared resource group
resource sharedResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: sharedResourceGroupName
  scope: subscription()
}

// Reference to existing shared OpenAI service
resource sharedOpenAI 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: sharedOpenAIName
  scope: sharedResourceGroup
}

// Reference to existing shared Key Vault
resource sharedKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: sharedKeyVaultName
  scope: sharedResourceGroup
}

// ============================================================================
// NEW RESOURCES DEPLOYMENT
// ============================================================================

module resources 'complete-infrastructure-resources.bicep' = {
  name: 'chatbottez-infrastructure-dev06'
  scope: targetResourceGroup
  params: {
    location: location
    resourceBaseName: resourceBaseName
    environment: environment
    uniqueSuffix: uniqueSuffix
    
    // PostgreSQL parameters
    postgresServerName: postgresServerName
    postgresAdminLogin: postgresAdminLogin
    postgresAdminPassword: postgresAdminPassword
    quotaDatabaseName: quotaDatabaseName
    
    // Key Vault parameters
    keyVaultName: keyVaultName
    
    // App Service parameters
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    
    // Monitoring parameters
    appInsightsName: appInsightsName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    
    // API Management parameters
    apimName: apimName
    publisherEmail: publisherEmail
    publisherName: publisherName
    
    // Shared resources (from rg-cotechnoe-ai-01)
    sharedOpenAIEndpoint: sharedOpenAIEndpoint
    sharedOpenAIDeploymentName: sharedOpenAIDeploymentName
    sharedOpenAIResourceId: sharedOpenAI.id
    sharedKeyVaultResourceId: sharedKeyVault.id
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output resourceGroupName string = targetResourceGroup.name
output webAppName string = webAppName
output webAppUrl string = 'https://${webAppName}.azurewebsites.net'
output keyVaultName string = keyVaultName
output postgresServerName string = postgresServerName
output appInsightsName string = appInsightsName
output logAnalyticsWorkspaceName string = logAnalyticsWorkspaceName

// Shared resources outputs
output sharedOpenAIEndpoint string = sharedOpenAIEndpoint
output sharedOpenAIDeploymentName string = sharedOpenAIDeploymentName
output sharedResourceGroupName string = sharedResourceGroupName
