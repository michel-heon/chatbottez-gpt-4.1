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

var targetResourceGroupName = 'rg-chatbottez-gpt-4-1-dev-05'
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

// Shared resources configuration
var sharedResourceGroupName = 'rg-cotechnoe-ai-01'
var sharedOpenAIName = 'openai-cotechnoe'
var sharedKeyVaultName = 'kv-cotechno771554451004'
var sharedOpenAIEndpoint = 'https://openai-cotechnoe.openai.azure.com/'
var sharedOpenAIDeploymentName = 'gpt-4o'

// ============================================================================
// RESOURCE GROUP
// ============================================================================

resource targetResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: targetResourceGroupName
  location: location
  tags: {
    Environment: environment
    Project: 'ChatBottez-GPT41'
    Version: 'v1.6.0-dev05'
    DeploymentType: 'Complete-Infrastructure'
  }
}

// ============================================================================
// RESOURCES MODULE
// ============================================================================

module infrastructureResources 'complete-infrastructure-resources.bicep' = {
  name: 'main-infrastructure-deployment'
  scope: targetResourceGroup
  params: {
    resourceBaseName: resourceBaseName
    environment: environment
    location: location
    publisherEmail: publisherEmail
    publisherName: publisherName
    postgresAdminLogin: postgresAdminLogin
    postgresAdminPassword: postgresAdminPassword
    postgresServerName: postgresServerName
    keyVaultName: keyVaultName
    apimName: apimName
    appInsightsName: appInsightsName
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    quotaDatabaseName: quotaDatabaseName
    appDatabaseUser: 'chatbottez_app'
    sharedResourceGroupName: sharedResourceGroupName
    sharedOpenAIName: sharedOpenAIName
    sharedKeyVaultName: sharedKeyVaultName
    sharedOpenAIEndpoint: sharedOpenAIEndpoint
    sharedOpenAIDeploymentName: sharedOpenAIDeploymentName
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output resourceGroupName string = targetResourceGroup.name
output postgresServerName string = infrastructureResources.outputs.postgresServerName
output keyVaultName string = infrastructureResources.outputs.keyVaultName
output apiManagementName string = infrastructureResources.outputs.apiManagementName
output webAppName string = infrastructureResources.outputs.webAppName
output managedIdentityName string = infrastructureResources.outputs.managedIdentityName
output BOT_ID string = infrastructureResources.outputs.BOT_ID
output BOT_DOMAIN string = infrastructureResources.outputs.BOT_DOMAIN
output webAppUrl string = infrastructureResources.outputs.webAppUrl
output apiManagementGatewayUrl string = infrastructureResources.outputs.apiManagementGatewayUrl
output apimChatbotApiUrl string = infrastructureResources.outputs.apimChatbotApiUrl
