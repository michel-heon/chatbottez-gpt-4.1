@description('Base name for all resources')
param resourceBaseName string = 'chatbottez-gpt41'

@description('Environment name (dev, staging, prod)')
param environment string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Publisher email for API Management')
param publisherEmail string

@description('Publisher name for API Management')
param publisherName string = 'ChatBottez'

// ============================================================================
// VARIABLES
// ============================================================================

var suffix = uniqueString(resourceGroup().id)
var shortSuffix = substring(suffix, 0, 6)

// Resource names
var apimName = 'apim-${resourceBaseName}-${environment}-${shortSuffix}'
var appInsightsName = 'ai-${resourceBaseName}-${environment}-${shortSuffix}'
var appServicePlanName = 'plan-${resourceBaseName}-${environment}-${shortSuffix}'
var webAppName = 'app-${resourceBaseName}-${environment}-${shortSuffix}'
var logAnalyticsWorkspaceName = 'law-${resourceBaseName}-${environment}-${shortSuffix}'

// ============================================================================
// EXISTING RESOURCES (Reference only)
// ============================================================================

// Local project resources (already deployed in this resource group)
resource existingPostgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' existing = {
  name: 'gpt-4-1-postgres-dev-rdazbuglrttd6'
}

resource existingKeyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: 'kvgpt41devrdazbuglrttd6'
}

// Shared resources in rg-cotechnoe-ai-01 (mutualized)
resource sharedOpenAI 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: 'openai-cotechnoe'
  scope: resourceGroup('rg-cotechnoe-ai-01')
}

resource sharedKeyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: 'kv-cotechno771554451004'
  scope: resourceGroup('rg-cotechnoe-ai-01')
}

// Shared OpenAI Service configuration
var sharedOpenAIEndpoint = 'https://openai-cotechnoe.openai.azure.com/'
var sharedOpenAIDeploymentName = 'gpt-4.1'

// ============================================================================
// LOG ANALYTICS WORKSPACE
// ============================================================================

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
  tags: {
    Environment: environment
    Project: 'ChatBottez-GPT41'
    Purpose: 'Log Analytics for monitoring'
  }
}

// ============================================================================
// APPLICATION INSIGHTS
// ============================================================================

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: {
    Environment: environment
    Project: 'ChatBottez-GPT41'
    Purpose: 'Application monitoring and telemetry'
  }
}

// ============================================================================
// API MANAGEMENT
// ============================================================================

resource apiManagement 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    notificationSenderEmail: 'apimgmt-noreply@mail.windowsazure.com'
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'false'
    }
    virtualNetworkType: 'None'
    apiVersionConstraint: {
      minApiVersion: '2019-01-01'
    }
  }
  tags: {
    Environment: environment
    Project: 'ChatBottez-GPT41'
    Purpose: 'API Gateway and quota management'
  }

  // API Management Logger for Application Insights
  resource apiManagementLogger 'loggers@2023-05-01-preview' = {
    name: 'applicationinsights-logger'
    properties: {
      loggerType: 'applicationInsights'
      credentials: {
        instrumentationKey: applicationInsights.properties.InstrumentationKey
      }
      isBuffered: true
      description: 'Application Insights logger for ChatBottez GPT-4.1'
    }
  }

  // Global quota policy for 300 requests per month
  resource globalPolicy 'policies@2023-05-01-preview' = {
    name: 'policy'
    properties: {
      value: '''
        <policies>
          <inbound>
            <quota calls="300" renewal-period="2629746" />
            <rate-limit calls="10" renewal-period="60" />
            <set-header name="X-Powered-By" exists-action="delete" />
            <set-header name="X-AspNet-Version" exists-action="delete" />
          </inbound>
          <backend>
            <forward-request />
          </backend>
          <outbound>
            <set-header name="X-RateLimit-Remaining" exists-action="override">
              <value>@(context.Response.Headers.GetValueOrDefault("X-RateLimit-Remaining","0"))</value>
            </set-header>
          </outbound>
          <on-error>
            <base />
          </on-error>
        </policies>
      '''
      format: 'xml'
    }
  }
}

// ============================================================================
// APP SERVICE PLAN AND WEB APP
// ============================================================================

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    family: 'B'
    capacity: 1
  }
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
  tags: {
    Environment: environment
    Project: 'ChatBottez-GPT41'
    Purpose: 'App Service Plan for Teams Bot'
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      nodeVersion: '18-lts'
      appSettings: [
        {
          name: 'NODE_ENV'
          value: 'production'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '18.17.0'
        }
        {
          name: 'AZURE_OPENAI_ENDPOINT'
          value: sharedOpenAIEndpoint
        }
        {
          name: 'AZURE_OPENAI_KEY'
          value: '@Microsoft.KeyVault(VaultName=${sharedKeyVault.name};SecretName=azure-openai-key)'
        }
        {
          name: 'AZURE_OPENAI_DEPLOYMENT_NAME'
          value: sharedOpenAIDeploymentName
        }
        {
          name: 'DATABASE_URL'
          value: '@Microsoft.KeyVault(VaultName=${existingKeyVault.name};SecretName=database-url)'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
      ]
      connectionStrings: [
        {
          name: 'DefaultConnection'
          connectionString: '@Microsoft.KeyVault(VaultName=${existingKeyVault.name};SecretName=database-url)'
          type: 'PostgreSQL'
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    Environment: environment
    Project: 'ChatBottez-GPT41'
    Purpose: 'Teams Bot Application'
  }
}

// ============================================================================
// KEY VAULT ACCESS POLICIES
// ============================================================================

// Grant Web App access to Key Vault
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  name: 'add'
  parent: existingKeyVault
  properties: {
    accessPolicies: [
      {
        tenantId: webApp.identity.tenantId
        objectId: webApp.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

// ============================================================================
// KEY VAULT SECRETS
// ============================================================================

// Store shared OpenAI Endpoint in local Key Vault for reference
resource openaiEndpointSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'azure-openai-endpoint'
  parent: existingKeyVault
  properties: {
    value: sharedOpenAIEndpoint
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}

// Store shared OpenAI Deployment Name in local Key Vault for reference
resource openaiDeploymentSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'azure-openai-deployment-name'
  parent: existingKeyVault
  properties: {
    value: sharedOpenAIDeploymentName
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}

// Store Application Insights Connection String
resource appInsightsConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'application-insights-connection-string'
  parent: existingKeyVault
  properties: {
    value: applicationInsights.properties.ConnectionString
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

output resourceGroupName string = resourceGroup().name
output postgresServerName string = existingPostgresServer.name
output keyVaultName string = existingKeyVault.name
output apiManagementName string = apiManagement.name
output applicationInsightsName string = applicationInsights.name
output webAppName string = webApp.name
output appServicePlanName string = appServicePlan.name

// Connection strings and keys
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
output sharedOpenaiEndpoint string = sharedOpenAIEndpoint
output sharedOpenaiDeployment string = sharedOpenAIDeploymentName
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output apiManagementGatewayUrl string = 'https://${apiManagement.properties.gatewayUrl}'

// Resource IDs for reference
output applicationInsightsId string = applicationInsights.id
output apiManagementId string = apiManagement.id
output webAppId string = webApp.id
