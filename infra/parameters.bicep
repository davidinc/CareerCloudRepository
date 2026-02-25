@description('Environment name (dev, staging, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('SQL Server administrator username')
param sqlAdminUsername string = 'sqladmin'

@description('SQL Server administrator password - CHANGE THIS!')
@minLength(8)
@secure()
param sqlAdminPassword string = 'ChangeMe@12345'

@description('App Service Plan SKU')
param appServicePlanSku string = 'B1'

@description('SQL Database SKU')
param sqlDatabaseSku string = 'Basic'
