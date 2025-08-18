@description('Base name for all resources')
param resourceBaseName string

@description('Environment name (dev, staging, prod)')
param environment string

@description('Location for all resources')
param location string = resourceGroup().location

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

@description('PostgreSQL server name')
param postgresServerName string

@description('Key Vault name')
param keyVaultName string

@description('API Management name')
param apimName string

@description('Application Insights name')
param appInsightsName string

@description('App Service Plan name')
param appServicePlanName string

@description('Web App name')
param webAppName string

@description('Log Analytics Workspace name')
param logAnalyticsWorkspaceName string

@description('Database name for quotas')
param quotaDatabaseName string

@description('Application database user')
param appDatabaseUser string

@description('Shared resource group name')
param sharedResourceGroupName string

@description('Shared OpenAI service name')
param sharedOpenAIName string

@description('Shared Key Vault name')
param sharedKeyVaultName string

@description('Shared OpenAI endpoint')
param sharedOpenAIEndpoint string

@description('Shared OpenAI deployment name')
param sharedOpenAIDeploymentName string

// ============================================================================
// SHARED RESOURCES REFERENCES (External Resource Group)
// ============================================================================

resource sharedOpenAI 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: sharedOpenAIName
  scope: resourceGroup(sharedResourceGroupName)
}

resource sharedKeyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: sharedKeyVaultName
  scope: resourceGroup(sharedResourceGroupName)
}

// ============================================================================
// MANAGED IDENTITY
// ============================================================================

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${resourceBaseName}-identity'
  location: location
  tags: {
    Environment: environment
    Project: 'ChatBottez-GPT41'
    Purpose: 'Managed Identity for Bot Framework'
  }
}

// ============================================================================
// POSTGRESQL FLEXIBLE SERVER
// ============================================================================

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: postgresServerName
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: postgresAdminLogin
    administratorLoginPassword: postgresAdminPassword
    version: '16'
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
  tags: {
    Environment: environment
    Project: 'ChatBottez-GPT41'
    Purpose: 'PostgreSQL database for quota management'
  }
}

// Create database
resource quotaDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-12-01' = {
  name: quotaDatabaseName
  parent: postgresServer
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

// Firewall rule to allow Azure services
resource postgresFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2022-12-01' = {
  name: 'AllowAzureServices'
  parent: postgresServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// ============================================================================
// KEY VAULT
// ============================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    accessPolicies: []
    enableSoftDelete: true
    enableRbacAuthorization: false
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    Environment: environment
    Project: 'ChatBottez-GPT41'
    Purpose: 'Key Vault for secrets management'
  }
}

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
}

// API Management Logger for Application Insights
resource apiManagementLogger 'Microsoft.ApiManagement/service/loggers@2023-05-01-preview' = {
  name: 'applicationinsights-logger'
  parent: apiManagement
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      instrumentationKey: applicationInsights.properties.InstrumentationKey
    }
    isBuffered: true
    description: 'Application Insights logger for ChatBottez GPT-4.1'
  }
}

// Named values for configuration
resource quotaLimitNamedValue 'Microsoft.ApiManagement/service/namedValues@2023-05-01-preview' = {
  parent: apiManagement
  name: 'quota-limit'
  properties: {
    displayName: 'QuotaLimit'
    value: '300'
    secret: false
  }
}

// Product for the chatbot API
resource chatbotProduct 'Microsoft.ApiManagement/service/products@2023-05-01-preview' = {
  parent: apiManagement
  name: 'chatbot-quota-product'
  properties: {
    displayName: 'Chatbot with Quota Management'
    description: 'AI Chatbot API with 300 questions per month quota enforcement'
    state: 'published'
    subscriptionRequired: true
    approvalRequired: false
    subscriptionsLimit: 1000
    terms: 'By subscribing to this product, you agree to the quota limits and billing terms.'
  }
}

// API definition with backend service URL pointing to the web app
resource chatbotApi 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apiManagement
  name: 'chatbot-api'
  properties: {
    displayName: 'AI Chatbot API'
    description: 'Microsoft Teams AI Chatbot with quota management'
    serviceUrl: 'https://${webAppName}.azurewebsites.net'
    path: 'chatbot'
    protocols: ['https']
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    apiRevision: '1'
  }
  dependsOn: [
    webApp
  ]
}

// Bot messages operation (main endpoint with quota)
resource messagesOperation 'Microsoft.ApiManagement/service/apis/operations@2023-05-01-preview' = {
  parent: chatbotApi
  name: 'post-api-messages'
  properties: {
    displayName: 'Process Message'
    method: 'POST'
    urlTemplate: '/api/messages'
    description: 'Processes bot messages and applies quota'
  }
}

// Quota policy for the messages operation
resource messagesPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2023-05-01-preview' = {
  parent: messagesOperation
  name: 'policy'
  properties: {
    value: '''
      <policies>
          <inbound>
              <base />
              <set-variable name="subscription-id" value="@(context.Subscription.Id)" />
              <quota-by-key
                  calls="300"
                  renewal-period="month"
                  counter-key="@(context.Subscription.Id)"
                  increment-condition="@(context.Response.StatusCode >= 200 && context.Response.StatusCode < 300)" />
              <rate-limit-by-key
                  calls="60"
                  renewal-period="60"
                  counter-key="@(context.Subscription.Id + &quot;-rate&quot;)" />
              <set-header name="x-apim-subscription-id" exists-action="override">
                  <value>@(context.Subscription.Id)</value>
              </set-header>
          </inbound>
          <backend>
              <base />
          </backend>
          <outbound>
              <base />
              <set-header name="x-quota-remaining" exists-action="override">
                  <value>@{
                      var quotaLimit = 300;
                      var quotaCounter = context.Variables.GetValueOrDefault<int>("quota-counter", 0);
                      return (quotaLimit - quotaCounter).ToString();
                  }</value>
              </set-header>
              <set-header name="x-quota-total" exists-action="override">
                  <value>300</value>
              </set-header>
          </outbound>
          <on-error>
              <base />
              <choose>
                  <when condition="@(context.LastError.Source == &quot;quota-by-key&quot;)">
                      <return-response>
                          <set-status code="429" reason="Quota Exceeded" />
                          <set-header name="Content-Type" exists-action="override">
                              <value>application/json</value>
                          </set-header>
                          <set-body>@{
                              return new JObject(
                                  new JProperty("error", "Quota Exceeded"),
                                  new JProperty("message", "You have exceeded your monthly quota of 300 questions. Please upgrade your plan or wait for the quota to reset."),
                                  new JProperty("details", new JObject(
                                      new JProperty("quota_limit", 300),
                                      new JProperty("quota_remaining", 0)
                                  ))
                              ).ToString();
                          }</set-body>
                      </return-response>
                  </when>
              </choose>
          </on-error>
      </policies>
    '''
    format: 'xml'
  }
}

// Link API to Product
resource productApi 'Microsoft.ApiManagement/service/products/apis@2023-05-01-preview' = {
  parent: chatbotProduct
  name: chatbotApi.name
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
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'RUNNING_ON_AZURE'
          value: '1'
        }
        {
          name: 'BOT_ID'
          value: managedIdentity.properties.clientId
        }
        {
          name: 'BOT_TENANT_ID'
          value: managedIdentity.properties.tenantId
        }
        {
          name: 'BOT_TYPE'
          value: 'UserAssignedMsi'
        }
        {
          name: 'AZURE_OPENAI_ENDPOINT'
          value: sharedOpenAIEndpoint
        }
        {
          name: 'AZURE_OPENAI_KEY'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=azure-openai-key)'
        }
        {
          name: 'AZURE_OPENAI_DEPLOYMENT_NAME'
          value: sharedOpenAIDeploymentName
        }
        {
          name: 'DATABASE_URL'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=database-url)'
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
          connectionString: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=database-url)'
          type: 'PostgreSQL'
        }
      ]
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
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

// Grant Web App (Managed Identity) access to local Key Vault
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        tenantId: managedIdentity.properties.tenantId
        objectId: managedIdentity.properties.principalId
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

// Store PostgreSQL connection string
resource databaseUrlSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'database-url'
  parent: keyVault
  properties: {
    value: 'postgresql://${postgresAdminLogin}:${postgresAdminPassword}@${postgresServer.properties.fullyQualifiedDomainName}:5432/${quotaDatabaseName}?sslmode=require'
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}

// Store shared OpenAI Endpoint in local Key Vault for reference
resource openaiEndpointSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'azure-openai-endpoint'
  parent: keyVault
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
  parent: keyVault
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
  parent: keyVault
  properties: {
    value: applicationInsights.properties.ConnectionString
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}

// Note: Azure OpenAI API Key from shared service will need to be configured manually
// or via a separate deployment that has access to the shared Key Vault

// ============================================================================
// BOT FRAMEWORK REGISTRATION
// ============================================================================

// Register the web service as a bot with the Bot Framework
module azureBotRegistration './botRegistration/azurebot.bicep' = {
  name: 'Azure-Bot-registration'
  params: {
    resourceBaseName: resourceBaseName
    identityClientId: managedIdentity.properties.clientId
    identityResourceId: managedIdentity.id
    identityTenantId: managedIdentity.properties.tenantId
    botAppDomain: webApp.properties.defaultHostName
    botDisplayName: 'ChatBottez GPT-4.1 ${environment}'
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

// Resource names
output postgresServerName string = postgresServer.name
output keyVaultName string = keyVault.name
output apiManagementName string = apiManagement.name
output applicationInsightsName string = applicationInsights.name
output webAppName string = webApp.name
output appServicePlanName string = appServicePlan.name
output managedIdentityName string = managedIdentity.name

// Bot Framework compatible outputs (matching v1.0.0-marketplace-quota)
output BOT_AZURE_APP_SERVICE_RESOURCE_ID string = webApp.id
output BOT_DOMAIN string = webApp.properties.defaultHostName
output BOT_ID string = managedIdentity.properties.clientId
output BOT_TENANT_ID string = managedIdentity.properties.tenantId

// Connection strings and keys
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output apiManagementGatewayUrl string = 'https://${apiManagement.properties.gatewayUrl}'
output postgresServerFqdn string = postgresServer.properties.fullyQualifiedDomainName

// API Management specific outputs
output apimChatbotApiUrl string = 'https://${apiManagement.properties.gatewayUrl}/chatbot'
output apimProductName string = chatbotProduct.name

// Resource IDs for reference
output applicationInsightsId string = applicationInsights.id
output apiManagementId string = apiManagement.id
output webAppId string = webApp.id
output postgresServerId string = postgresServer.id
output keyVaultId string = keyVault.id
output managedIdentityId string = managedIdentity.id
