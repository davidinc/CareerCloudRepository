// ============================================
// CareerCloud Lightweight Development Infrastructure
// Cost-Optimized (MongoDB/External DB)
// 
// This template is designed for development only
// - Minimal App Service (B1)
// - No SQL Database (use MongoDB or existing license)
// - Application Insights only
// - Total cost: ~$13/month
// ============================================

targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Environment name (dev, staging)')
param environmentName string = 'dev'

@description('Azure region for resources')
param location string = resourceGroup().location

@description('MongoDB connection string (if using MongoDB)')
param mongoDbConnection string = 'mongodb+srv://user:password@cluster.xxxxx.mongodb.net/careercloud'

@description('Enable Application Insights monitoring')
param enableAppInsights bool = true

// Variables
var tags = {
  environment: environmentName
  project: 'CareerCloud'
  deployedBy: 'Bicep'
  costCenter: 'Development'
  createdDate: utcNow('yyyy-MM-dd')
}

var appServicePlanName = 'plan-careercloud-${environmentName}-${substring(uniqueString(resourceGroup().id), 0, 4)}'
var webAppName = 'app-careercloud-${environmentName}-${substring(uniqueString(resourceGroup().id), 0, 4)}'
var appInsightsName = 'appinsights-${environmentName}-${substring(uniqueString(resourceGroup().id), 0, 4)}'

// ============================================
// Application Insights (Lightweight)
// ============================================
resource appInsights 'Microsoft.Insights/components@2020-02-02' = if(enableAppInsights) {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 30 // Reduced for cost (7 days for B1)
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    DisableIpMasking: false
    SamplingPercentage: 100
  }
}

// ============================================
// App Service Plan (B1 - Smallest/Cheapest)
// ============================================
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: 'B1'
    tier: 'Basic'
    capacity: 1
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
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|6.0'
      alwaysOn: false // Disable for B1 tier (auto-sleep when inactive)
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      use32BitWorkerProcess: false
      managedPipelineMode: 'Integrated'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Development'
        }
        {
          name: 'ASPNETCORE_URLS'
          value: 'http://+:8080'
        }
        // MongoDB Connection (if applicable)
        {
          name: 'MongoDbConnection'
          value: mongoDbConnection
        }
        // Application Insights
        {
          name: 'APPINSIGHTS_CONNECTIONSTRING'
          value: enableAppInsights ? appInsights.properties.ConnectionString : ''
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        // Logging Configuration
        {
          name: 'Logging:LogLevel:Default'
          value: 'Information'
        }
        {
          name: 'Logging:LogLevel:Microsoft'
          value: 'Warning'
        }
      ]
    }
  }

  // Child resource: Logging configuration
  resource logs 'config@2021-03-01' = {
    name: 'logs'
    properties: {
      applicationLogs: {
        fileSystemLevel: 'Information'
        azureBlobStorage: {
          level: 'Off'
          sasUrl: ''
          retentionInDays: 0
        }
        azureTableStorage: {
          level: 'Off'
          sasUrl: ''
        }
      }
      httpLogs: {
        fileSystem: {
          enabled: true
          retentionInMb: 35
          retentionInDays: 2
        }
        azureBlobStorage: {
          enabled: false
          sasUrl: ''
          retentionInDays: 0
        }
      }
      failedRequestsTracing: {
        enabled: true
      }
      detailedErrorMessages: {
        enabled: true
      }
    }
  }
}

// ============================================
// Diagnostic Settings
// ============================================
resource appServiceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if(enableAppInsights) {
  name: 'AppService-Dev-Diagnostics'
  scope: webApp
  properties: {
    workspaceId: ''
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 2 // Reduced for cost
        }
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 2
        }
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 2
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 2
        }
      }
    ]
  }
}

// ============================================
// Outputs
// ============================================
@description('The name of the created App Service')
output webAppName string = webApp.name

@description('The host name of the Web App')
output webAppHostName string = webApp.properties.defaultHostName

@description('The complete Web App URL')
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'

@description('The principal ID of the Web App for RBAC')
output webAppPrincipalId string = webApp.identity.principalId

@description('The App Service Plan ID')
output appServicePlanId string = appServicePlan.id

@description('Application Insights Instrumentation Key')
output appInsightsInstrumentationKey string = enableAppInsights ? appInsights.properties.InstrumentationKey : ''

@description('Application Insights Connection String')
output appInsightsConnectionString string = enableAppInsights ? appInsights.properties.ConnectionString : ''

@description('Total estimated monthly cost')
output estimatedMonthlyCost string = '~$13 (B1 App Service + App Insights)'

@description('Database connection info')
output databaseInfo string = 'Using MongoDB Atlas Free or your existing SQL license - No Cloud DB Cost'
