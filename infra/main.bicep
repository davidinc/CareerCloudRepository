// ============================================
// CareerCloud Azure Infrastructure
// Bicep Template for Deployment
// ============================================
// This template provisions:
// - Azure SQL Server and Database
// - Azure App Service Plan
// - Azure App Service (Web App)
// - Application Insights for monitoring
// - Key Vault for secrets management (optional)

targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the environment (e.g., dev, staging, prod)')
param environmentName string

@description('Primary Azure region for resources')
param location string = resourceGroup().location

@description('SQL Server administrator username')
@minLength(1)
param sqlAdminUsername string

@description('SQL Server administrator password')
@minLength(8)
@secure()
param sqlAdminPassword string

@description('The name of the Application Insights resource')
param appInsightsName string = 'appinsights-${environmentName}-${substring(uniqueString(resourceGroup().id), 0, 4)}'

@description('The name of the App Service Plan')
param appServicePlanName string = 'plan-${environmentName}-${substring(uniqueString(resourceGroup().id), 0, 4)}'

@description('The name of the Web App')
param webAppName string = 'app-careercloud-${environmentName}-${substring(uniqueString(resourceGroup().id), 0, 4)}'

@description('The name of the SQL Server')
param sqlServerName string = 'sqlserver-${environmentName}-${substring(uniqueString(resourceGroup().id), 0, 4)}'

@description('The name of the SQL Database')
param sqlDatabaseName string = 'db-careercloud-${environmentName}'

@description('The SKU of the App Service Plan (B1, B2, S1, S2, P1V2, etc.)')
param appServicePlanSku string = 'B1'

@description('The SKU of the SQL Database (Basic, Standard, Premium)')
param sqlDatabaseSku string = 'Basic'

// Variables
var tags = {
  environment: environmentName
  project: 'CareerCloud'
  deployedBy: 'Bicep'
  createdDate: utcNow('yyyy-MM-dd')
}

var appServicePlanId = appServicePlan.id
var sqlServerFqdn = '${sqlServer.name}.database.windows.net'

// ============================================
// Azure SQL Server
// ============================================
resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    publicNetworkAccess: 'Enabled'
    minimalTlsVersion: '1.2'
    administrators: {
      login: sqlAdminUsername
      administratorType: 'ActiveDirectory'
      principalType: 'User'
      sid: '00000000-0000-0000-0000-000000000000' // Will be set during deployment
      tenantId: subscription().tenantId
    }
  }
}

// Allow Azure services to access SQL Server
resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2021-11-01' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// ============================================
// Azure SQL Database
// ============================================
resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-11-01' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: tags
  sku: {
    name: sqlDatabaseSku
    tier: sqlDatabaseSku
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2GB for Basic tier
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Geo'
  }
}

// ============================================
// Application Insights
// ============================================
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 90
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ============================================
// App Service Plan
// ============================================
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: appServicePlanSku
    tier: skuTier(appServicePlanSku)
  }
  properties: {
    reserved: true // Linux
  }
}

// ============================================
// App Service (Web App)
// ============================================
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    virtualNetworkSubnetId: null
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|6.0'
      alwaysOn: appServicePlanSku != 'B1'
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      use32BitWorkerProcess: false
      managedPipelineMode: 'Integrated'
      defaultDocuments: []
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: environmentName == 'prod' ? 'Production' : 'Development'
        }
        {
          name: 'APPINSIGHTS_CONNECTIONSTRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'ConnectionStrings__DataConnection'
          value: 'Server=tcp:${sqlServerFqdn},1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${sqlAdminUsername};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
      ]
      connectionStrings: [
        {
          name: 'DataConnection'
          connectionString: 'Server=tcp:${sqlServerFqdn},1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${sqlAdminUsername};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
          type: 'SQLServer'
        }
      ]
    }
  }
}

// ============================================
// Diagnostic Settings for App Service
// ============================================
resource appServiceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'AppService-Diagnostics'
  scope: webApp
  properties: {
    workspaceId: ''
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 7
        }
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 7
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 7
        }
      }
    ]
  }
}

// ============================================
// Helper Functions
// ============================================
@description('Determine the tier of an SKU')
func skuTier(skuName string) string => first(split(skuName, '1'))

// ============================================
// Outputs
// ============================================
@description('The ID of the created App Service')
output webAppId string = webApp.id

@description('The host name of the Web App')
output webAppHostName string = webApp.properties.defaultHostName

@description('The principal ID of the Web App for RBAC')
output webAppPrincipalId string = webApp.identity.principalId

@description('The FQDN of the SQL Server')
output sqlServerFqdn string = sqlServerFqdn

@description('The SQL Database name')
output sqlDatabaseName string = sqlDatabase.name

@description('The Application Insights Instrumentation Key')
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey

@description('The Application Insights Connection String')
output appInsightsConnectionString string = appInsights.properties.ConnectionString

@description('The complete web app URL')
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
