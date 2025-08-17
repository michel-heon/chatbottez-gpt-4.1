@description('API Management service name')
param apimServiceName string

@description('Resource group location')
param location string = resourceGroup().location

@description('API Management SKU')
param apimSku string = 'Developer'

@description('API Management capacity')
param apimCapacity int = 1

@description('Publisher email for APIM')
param publisherEmail string

@description('Publisher name for APIM')
param publisherName string

@description('Backend service URL')
param backendServiceUrl string

@description('Event Hub namespace for logging')
param eventHubNamespace string = ''

@description('Event Hub name for audit logs')
param auditEventHubName string = 'quota-audit'

@description('Event Hub name for usage billing')
param usageBillingEventHubName string = 'usage-billing'

@description('Event Hub name for error logs')
param errorEventHubName string = 'error-logs'

// APIM Service
resource apimService 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apimServiceName
  location: location
  sku: {
    name: apimSku
    capacity: apimCapacity
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'false'
    }
  }
}

// Product for the chatbot API
resource chatbotProduct 'Microsoft.ApiManagement/service/products@2023-05-01-preview' = {
  parent: apimService
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

// API definition
resource chatbotApi 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apimService
  name: 'chatbot-api'
  properties: {
    displayName: 'AI Chatbot API'
    description: 'Microsoft Teams AI Chatbot with quota management'
    serviceUrl: backendServiceUrl
    path: 'chatbot'
    protocols: ['https']
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    apiRevision: '1'
    apiVersion: 'v1'
    format: 'openapi+json'
    value: '''
{
  "openapi": "3.0.1",
  "info": {
    "title": "AI Chatbot API",
    "description": "Microsoft Teams AI Chatbot with quota management",
    "version": "1.0.0"
  },
  "servers": [
    {
      "url": "${backendServiceUrl}"
    }
  ],
  "paths": {
    "/api/messages": {
      "post": {
        "summary": "Process bot message",
        "description": "Processes incoming bot messages and generates AI responses (counts towards quota)",
        "operationId": "processMessage",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "description": "Bot Framework Activity"
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "Message processed successfully",
            "headers": {
              "x-quota-remaining": {
                "schema": {
                  "type": "integer"
                },
                "description": "Number of questions remaining this month"
              },
              "x-quota-total": {
                "schema": {
                  "type": "integer"
                },
                "description": "Total quota for this month"
              },
              "x-quota-reset-date": {
                "schema": {
                  "type": "string",
                  "format": "date-time"
                },
                "description": "Date when quota resets"
              }
            }
          },
          "429": {
            "description": "Quota exceeded",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "error": {"type": "string"},
                    "message": {"type": "string"},
                    "details": {
                      "type": "object",
                      "properties": {
                        "quota_limit": {"type": "integer"},
                        "quota_remaining": {"type": "integer"},
                        "reset_date": {"type": "string", "format": "date-time"}
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "/marketplace/resolve": {
      "post": {
        "summary": "Resolve marketplace token",
        "description": "Resolves marketplace purchase token (does not count towards quota)",
        "operationId": "resolveMarketplace",
        "responses": {
          "200": {
            "description": "Token resolved successfully"
          }
        }
      }
    },
    "/marketplace/{subscriptionId}/activate": {
      "post": {
        "summary": "Activate subscription",
        "description": "Activates marketplace subscription (does not count towards quota)",
        "operationId": "activateSubscription",
        "parameters": [
          {
            "name": "subscriptionId",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Subscription activated successfully"
          }
        }
      }
    }
  }
}
'''
  }
}

// API Operations with quota policy
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

// Apply quota policy to the messages operation
resource messagesPolicy 'Microsoft.ApiManagement/service/apis/operations/policies@2023-05-01-preview' = {
  parent: messagesOperation
  name: 'policy'
  properties: {
    value: loadTextContent('policy.xml')
    format: 'xml'
  }
}

// Marketplace operations (no quota applied)
resource marketplaceResolveOperation 'Microsoft.ApiManagement/service/apis/operations@2023-05-01-preview' = {
  parent: chatbotApi
  name: 'post-marketplace-resolve'
  properties: {
    displayName: 'Resolve Marketplace Token'
    method: 'POST'
    urlTemplate: '/marketplace/resolve'
    description: 'Resolves marketplace purchase token'
  }
}

resource marketplaceActivateOperation 'Microsoft.ApiManagement/service/apis/operations@2023-05-01-preview' = {
  parent: chatbotApi
  name: 'post-marketplace-activate'
  properties: {
    displayName: 'Activate Subscription'
    method: 'POST'
    urlTemplate: '/marketplace/{subscriptionId}/activate'
    description: 'Activates marketplace subscription'
    templateParameters: [
      {
        name: 'subscriptionId'
        type: 'string'
        required: true
      }
    ]
  }
}

// Link API to Product
resource productApi 'Microsoft.ApiManagement/service/products/apis@2023-05-01-preview' = {
  parent: chatbotProduct
  name: chatbotApi.name
  dependsOn: [
    chatbotApi
  ]
}

// Event Hub loggers (if Event Hub is provided)
resource auditLogger 'Microsoft.ApiManagement/service/loggers@2023-05-01-preview' = if (!empty(eventHubNamespace)) {
  parent: apimService
  name: 'quota-audit-logger'
  properties: {
    loggerType: 'azureEventHub'
    description: 'Logger for quota audit events'
    credentials: {
      connectionString: 'Endpoint=sb://${eventHubNamespace}.servicebus.windows.net/;EntityPath=${auditEventHubName}'
    }
  }
}

resource usageLogger 'Microsoft.ApiManagement/service/loggers@2023-05-01-preview' = if (!empty(eventHubNamespace)) {
  parent: apimService
  name: 'usage-billing-logger'
  properties: {
    loggerType: 'azureEventHub'
    description: 'Logger for usage billing events'
    credentials: {
      connectionString: 'Endpoint=sb://${eventHubNamespace}.servicebus.windows.net/;EntityPath=${usageBillingEventHubName}'
    }
  }
}

resource errorLogger 'Microsoft.ApiManagement/service/loggers@2023-05-01-preview' = if (!empty(eventHubNamespace)) {
  parent: apimService
  name: 'error-logger'
  properties: {
    loggerType: 'azureEventHub'
    description: 'Logger for error events'
    credentials: {
      connectionString: 'Endpoint=sb://${eventHubNamespace}.servicebus.windows.net/;EntityPath=${errorEventHubName}'
    }
  }
}

// Named values for configuration
resource quotaLimitNamedValue 'Microsoft.ApiManagement/service/namedValues@2023-05-01-preview' = {
  parent: apimService
  name: 'quota-limit'
  properties: {
    displayName: 'Quota Limit'
    value: '300'
    secret: false
  }
}

resource quotaDimensionNamedValue 'Microsoft.ApiManagement/service/namedValues@2023-05-01-preview' = {
  parent: apimService
  name: 'quota-dimension'
  properties: {
    displayName: 'Quota Dimension'
    value: 'question'
    secret: false
  }
}

// Outputs
output apimServiceName string = apimService.name
output apimServiceUrl string = 'https://${apimService.properties.gatewayUrl}'
output chatbotApiPath string = '${apimService.properties.gatewayUrl}/chatbot'
output productId string = chatbotProduct.name
output apiId string = chatbotApi.name
