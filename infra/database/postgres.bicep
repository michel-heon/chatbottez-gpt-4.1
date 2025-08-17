@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment name (dev, test, prod)')
param environment string = 'dev'

@description('Application name prefix')
param appName string = 'gpt-4-1'

@description('PostgreSQL server administrator login')
param administratorLogin string = 'pgadmin'

@description('PostgreSQL server administrator password')
@secure()
param administratorPassword string

@description('PostgreSQL server SKU')
param skuName string = 'Standard_B1ms'

@description('PostgreSQL version')
param postgresqlVersion string = '16'

@description('Storage size in GB')
param storageSizeGB int = 32

@description('Storage auto grow enabled')
param storageAutoGrow bool = true

@description('Backup retention days')
param backupRetentionDays int = 7

@description('Geo-redundant backup enabled')
param geoRedundantBackup bool = false

@description('High availability enabled')
param highAvailability bool = false

@description('Database name')
param databaseName string = 'marketplace_quota'

@description('Application user name')
param appUserName string = 'marketplace_user'

@description('Application user password')
@secure()
param appUserPassword string

// Variables
var serverName = '${appName}-postgres-${environment}-${uniqueString(resourceGroup().id)}'
var keyVaultName = 'kv${replace(appName, '-', '')}${environment}${uniqueString(resourceGroup().id)}'

// Key Vault for storing secrets
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// PostgreSQL Flexible Server
resource postgresqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: 'Burstable'
  }
  properties: {
    version: postgresqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    storage: {
      storageSizeGB: storageSizeGB
      autoGrow: storageAutoGrow ? 'Enabled' : 'Disabled'
    }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup ? 'Enabled' : 'Disabled'
    }
    highAvailability: {
      mode: highAvailability ? 'ZoneRedundant' : 'Disabled'
    }
    maintenanceWindow: {
      customWindow: 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Disabled'
      passwordAuth: 'Enabled'
    }
  }
  
  tags: {
    Environment: environment
    Application: appName
    Purpose: 'Database'
  }
}

// Firewall rule to allow Azure services
resource firewallRuleAzure 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-06-01-preview' = {
  parent: postgresqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Firewall rule to allow all IP addresses (for development only)
resource firewallRuleAll 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-06-01-preview' = if (environment == 'dev') {
  parent: postgresqlServer
  name: 'AllowAllIPs'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

// Database
resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-06-01-preview' = {
  parent: postgresqlServer
  name: databaseName
  properties: {
    charset: 'utf8'
    collation: 'en_US.utf8'
  }
}

// Store connection strings in Key Vault
resource adminConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'postgres-admin-connection-string'
  properties: {
    value: 'postgresql://${administratorLogin}:${administratorPassword}@${postgresqlServer.properties.fullyQualifiedDomainName}:5432/${databaseName}?sslmode=require'
  }
}

resource appConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'postgres-app-connection-string'
  properties: {
    value: 'postgresql://${appUserName}:${appUserPassword}@${postgresqlServer.properties.fullyQualifiedDomainName}:5432/${databaseName}?sslmode=require'
  }
}

resource adminPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'postgres-admin-password'
  properties: {
    value: administratorPassword
  }
}

resource appPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'postgres-app-password'
  properties: {
    value: appUserPassword
  }
}

// Outputs
output serverName string = postgresqlServer.name
output serverFQDN string = postgresqlServer.properties.fullyQualifiedDomainName
output databaseName string = database.name
output keyVaultName string = keyVault.name
output adminConnectionString string = 'postgresql://${administratorLogin}@${postgresqlServer.properties.fullyQualifiedDomainName}:5432/${databaseName}?sslmode=require'
output appConnectionString string = 'postgresql://${appUserName}@${postgresqlServer.properties.fullyQualifiedDomainName}:5432/${databaseName}?sslmode=require'
output resourceGroupName string = resourceGroup().name
