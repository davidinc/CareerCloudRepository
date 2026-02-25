# CareerCloud - Development to Production Migration Guide

## Overview

After validating your CareerCloud application in the development environment, this guide shows you how to:

1. Switch to Production Azure subscription
2. Scale up resources (S1 App Service, Standard SQL Database)
3. Configure production security
4. Migrate data from dev to prod
5. Set up monitoring & alerting

---

## 📋 Prerequisites

✅ Development environment is running and tested
✅ Production Azure subscription is available
✅ Production subscription has sufficient quota
✅ Database backups are created
✅ Security requirements are documented

---

## 🔄 Phase 1: Switch to Production Subscription

### Step 1: List Available Subscriptions

```bash
# Display all subscriptions you have access to
az account list --output table

# Shows: Name, CloudName, SubscriptionId, State, IsDefault
```

### Step 2: Identify Production Subscription

```bash
# Get subscription ID
PROD_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Set as active
az account set --subscription "$PROD_SUBSCRIPTION_ID"

# Verify you're on production subscription
az account show --query "{name:name, id:id, isDefault:isDefault}" -o table
```

### Step 3: Create Production Resource Group

```bash
# Create new resource group for production
PROD_RG_NAME="rg-careercloud-prod"
LOCATION="East US"  # Or your preferred region

az group create \
  --name $PROD_RG_NAME \
  --location "$LOCATION" \
  --tags environment=production \
           project=CareerCloud \
           managedBy="Terraform/Bicep" \
           costCenter="Production"

# Verify creation
az group show --name $PROD_RG_NAME
```

---

## 🚀 Phase 2: Deploy Production Infrastructure

### Step 1: Deploy Full Infrastructure (with SQL Database)

```bash
# Deploy using production Bicep template
# This includes: App Service (S1), SQL Database (Standard), App Insights

az deployment group create \
  --name CareerCloud-Prod-Deployment \
  --resource-group $PROD_RG_NAME \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json \
  --parameters \
    environmentName=prod \
    location="$LOCATION" \
    appServicePlanSku=S1 \
    sqlDatabaseSku=Standard \
    sqlAdminPassword="YourVeryStrongPassword@2024!" \
  --output json > prod-deployment.json

# Extract deployment outputs
PROD_OUTPUTS=$(az deployment group show \
  --resource-group $PROD_RG_NAME \
  --name CareerCloud-Prod-Deployment \
  --query properties.outputs -o json)

# Save outputs for reference
echo "$PROD_OUTPUTS" | jq '.' > prod-deployment-outputs.json

# Extract key values
PROD_APP_NAME=$(echo "$PROD_OUTPUTS" | jq -r '.webAppName.value')
PROD_SQL_SERVER=$(echo "$PROD_OUTPUTS" | jq -r '.sqlServerFqdn.value')
PROD_SQL_DB=$(echo "$PROD_OUTPUTS" | jq -r '.sqlDatabaseName.value')
PROD_APP_URL=$(echo "$PROD_OUTPUTS" | jq -r '.webAppUrl.value')

echo "Production Resources Created:"
echo "  Web App: $PROD_APP_NAME"
echo "  SQL Server: $PROD_SQL_SERVER"
echo "  SQL Database: $PROD_SQL_DB"
echo "  URL: $PROD_APP_URL"
```

### Step 2: Configure Production Settings

```bash
# Update app settings for production
az webapp config appsettings set \
  --resource-group $PROD_RG_NAME \
  --name $PROD_APP_NAME \
  --settings \
    ASPNETCORE_ENVIRONMENT=Production \
    WEBSITE_ENABLE_SYNC_UPDATE_SITE=true \
    WEBSITE_HTTPLOGGING_RETENTION_DAYS=7 \
    LOG_LEVEL=Error

# Verify settings
az webapp config appsettings list \
  --resource-group $PROD_RG_NAME \
  --name $PROD_APP_NAME \
  --output table
```

### Step 3: Configure HTTPS and Security

```bash
# Enable HTTPS only (should already be enabled in Bicep)
az webapp update \
  --resource-group $PROD_RG_NAME \
  --name $PROD_APP_NAME \
  --https-only true

# Configure minimum TLS version
az webapp update \
  --resource-group $PROD_RG_NAME \
  --name $PROD_APP_NAME \
  --min-tls-version 1.2
```

---

## 📊 Phase 3: Prepare Production Database

### Step 1: Import Production Database Schema

```bash
# Get SQL connection string
PROD_SQL_FQDN="$PROD_SQL_SERVER"
PROD_SQL_USER="sqladmin"
PROD_SQL_PASS="YourVeryStrongPassword@2024!"

# Test connection first
sqlcmd -S "$PROD_SQL_FQDN" \
  -U "$PROD_SQL_USER" \
  -P "$PROD_SQL_PASS" \
  -Q "SELECT @@VERSION"

# Import database schema
sqlcmd -S "$PROD_SQL_FQDN" \
  -U "$PROD_SQL_USER" \
  -P "$PROD_SQL_PASS" \
  -d "$PROD_SQL_DB" \
  -i CareerCloud_Database_Script.sql

# Verify tables created
sqlcmd -S "$PROD_SQL_FQDN" \
  -U "$PROD_SQL_USER" \
  -P "$PROD_SQL_PASS" \
  -d "$PROD_SQL_DB" \
  -Q "SELECT COUNT(*) as TableCount FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'"
```

### Step 2: Configure SQL Server Firewall

```bash
# Allow App Service to connect to SQL
az sql server firewall-rule create \
  --resource-group $PROD_RG_NAME \
  --server $(echo $PROD_SQL_SERVER | cut -d. -f1) \
  --name "AllowAppService" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Allow your admin IP (for management)
MY_IP=$(curl -s https://ipinfo.io/json | jq -r '.ip')

az sql server firewall-rule create \
  --resource-group $PROD_RG_NAME \
  --server $(echo $PROD_SQL_SERVER | cut -d. -f1) \
  --name "AllowAdminIP" \
  --start-ip-address "$MY_IP" \
  --end-ip-address "$MY_IP"

# Verify rules
az sql server firewall-rule list \
  --resource-group $PROD_RG_NAME \
  --server $(echo $PROD_SQL_SERVER | cut -d. -f1)
```

### Step 3: Configure SQL Database Backups

```bash
# Set up automated backups (7 days for Standard tier)
az sql db short-term-retention-policy update \
  --resource-group $PROD_RG_NAME \
  --server $(echo $PROD_SQL_SERVER | cut -d. -f1) \
  --database "$PROD_SQL_DB" \
  --retention-days 7

# View backup policy
az sql db short-term-retention-policy show \
  --resource-group $PROD_RG_NAME \
  --server $(echo $PROD_SQL_SERVER | cut -d. -f1) \
  --database "$PROD_SQL_DB"
```

---

## 🔄 Phase 4: Migrate Data from Dev to Prod

### Option A: Direct SQL Backup & Restore

```bash
# Step 1: Export dev database
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

sqlcmd -S "careercloud-dev.database.windows.net" \
  -U sqladmin \
  -P "DevPassword@123" \
  -d careercloud-dev \
  -o "backup_dev_$TIMESTAMP.sql"

# Step 2: Import to production
sqlcmd -S "$PROD_SQL_FQDN" \
  -U "$PROD_SQL_USER" \
  -P "$PROD_SQL_PASS" \
  -d "$PROD_SQL_DB" \
  -i "backup_dev_$TIMESTAMP.sql"

# Step 3: Verify migration
echo "Dev record count:"
sqlcmd -S "careercloud-dev.database.windows.net" \
  -U sqladmin -P "DevPassword@123" -d careercloud-dev \
  -Q "SELECT SUM(row_count) FROM sys.dm_db_partition_stats WHERE object_id > 100"

echo "Prod record count:"
sqlcmd -S "$PROD_SQL_FQDN" \
  -U "$PROD_SQL_USER" -P "$PROD_SQL_PASS" -d "$PROD_SQL_DB" \
  -Q "SELECT SUM(row_count) FROM sys.dm_db_partition_stats WHERE object_id > 100"
```

### Option B: Development Copy Feature

```bash
# Use Azure SQL's "Create Copy" feature (faster, more reliable)

az sql db copy \
  --resource-group "rg-careercloud-dev" \
  --server "careercloud-dev-server" \
  --name "careercloud-dev" \
  --dest-resource-group $PROD_RG_NAME \
  --dest-server "$(echo $PROD_SQL_SERVER | cut -d. -f1)" \
  --dest-name "$PROD_SQL_DB"

# Monitor copy progress
az sql db list-copies \
  --resource-group $PROD_RG_NAME \
  --name "$PROD_SQL_DB"
```

---

## 🚀 Phase 5: Deploy Updated Application

### Step 1: Update Connection Strings

```bash
# Update production connection string
PROD_CONNECTION_STRING="Server=tcp:$PROD_SQL_FQDN,1433;Initial Catalog=$PROD_SQL_DB;Persist Security Info=False;User ID=$PROD_SQL_USER;Password=$PROD_SQL_PASS;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

az webapp config connection-string set \
  --resource-group $PROD_RG_NAME \
  --name $PROD_APP_NAME \
  --connection-string-slots \
    DataConnection="$PROD_CONNECTION_STRING" \
  --connection-string-type SQLServer
```

### Step 2: Deploy Updated Code

```bash
# Build latest version
cd CareerCloudRepository
dotnet restore
dotnet build --configuration Release
dotnet publish CareerCloud.WebAPI/CareerCloud.WebAPI.csproj -c Release -o ./publish

# Create deployment package
cd publish && zip -r ../publish.zip . && cd ..

# Deploy to production
az webapp deployment source config-zip \
  --resource-group $PROD_RG_NAME \
  --name $PROD_APP_NAME \
  --src ./publish.zip

# Wait for deployment
echo "Deployment started... Waiting 5-10 minutes"
sleep 60

# Check deployment status
az webapp deployment list \
  --resource-group $PROD_RG_NAME \
  --name $PROD_APP_NAME
```

### Step 3: Verify Production Deployment

```bash
# Test API
echo "Testing production API..."
curl -X GET "$PROD_APP_URL/api/health" -v

# View logs
az webapp log tail \
  --resource-group $PROD_RG_NAME \
  --name $PROD_APP_NAME \
  --lines 100
```

---

## 📊 Phase 6: Configure Production Monitoring

### Step 1: Set Up Alerts

```bash
# Alert: High Error Rate (>10 errors per minute)
az monitor metrics alert create \
  --name "CareerCloud-HighErrorRate" \
  --resource-group $PROD_RG_NAME \
  --scopes "/subscriptions/$PROD_SUBSCRIPTION_ID/resourceGroups/$PROD_RG_NAME/providers/Microsoft.Web/sites/$PROD_APP_NAME" \
  --description "Alert when error rate is high" \
  --condition "avg FailedRequests > 10" \
  --window-size 1m \
  --evaluation-frequency 1m \
  --action create_action_group \
  --action-group "CareerCloud-Alerts"

# Alert: High CPU Usage (>80%)
az monitor metrics alert create \
  --name "CareerCloud-HighCPU" \
  --resource-group $PROD_RG_NAME \
  --scopes "/subscriptions/$PROD_SUBSCRIPTION_ID/resourceGroups/$PROD_RG_NAME/providers/Microsoft.Web/serverfarms/plan-careercloud-prod-*" \
  --condition "avg CpuPercentage > 80" \
  --window-size 5m \
  --evaluation-frequency 1m
```

### Step 2: Enable Detailed Logging

```bash
# Enable all diagnostic logs
az webapp log config \
  --resource-group $PROD_RG_NAME \
  --name $PROD_APP_NAME \
  --application-logging true \
  --detailed-error-messages true \
  --failed-request-tracing true \
  --level verbose

# Set retention
az webapp log config \
  --resource-group $PROD_RG_NAME \
  --name $PROD_APP_NAME \
  --retention-in-days 30
```

### Step 3: Configure Application Insights

```bash
# View Application Insights dashboard
APP_INSIGHTS_NAME=$(echo "$PROD_OUTPUTS" | jq -r '.appInsightsName.value')

echo "View your Application Insights dashboard:"
echo "https://portal.azure.com/#@/resource/subscriptions/$PROD_SUBSCRIPTION_ID/resourceGroups/$PROD_RG_NAME/providers/Microsoft.Insights/components/$APP_INSIGHTS_NAME"

# Create custom alert
az monitor metrics alert create \
  --name "AppInsights-HighResponseTime" \
  --resource-group $PROD_RG_NAME \
  --scopes "/subscriptions/$PROD_SUBSCRIPTION_ID/resourceGroups/$PROD_RG_NAME/providers/Microsoft.Insights/components/$APP_INSIGHTS_NAME" \
  --condition "avg ResponseTime > 2000"
```

---

## 💰 Phase 7: Manage Costs

### Step 1: Set Up Budget Alert

```bash
# Create monthly budget alert
az billing budget create \
  --resource-group $PROD_RG_NAME \
  --name "CareerCloud-Monthly-Budget" \
  --amount 200 \
  --time-period Month \
  --start-date 2024-01-01 \
  --notifications-enabled true \
  --threshold 80 \
  --threshold-type Forecasted

# View budget
az billing budget list --output table
```

### Step 2: Compare Costs

```bash
# Check current costs
az costmanagement query \
  --timeframe MonthToDate \
  --metric ActualCost \
  --scope "/subscriptions/$PROD_SUBSCRIPTION_ID"

# Get daily cost breakdown
az costmanagement query \
  --timeframe MonthToDate \
  --metric ActualCost \
  --granularity Daily \
  --groupby "type/dimension" \
  --scope "/subscriptions/$PROD_SUBSCRIPTION_ID"
```

### Step 3: Optimize Resources (If Needed)

```bash
# Check App Service metrics
az monitor metrics list \
  --resource /subscriptions/$PROD_SUBSCRIPTION_ID/resourceGroups/$PROD_RG_NAME/providers/Microsoft.Web/sites/$PROD_APP_NAME \
  --metric CpuPercentage,MemoryPercentage \
  --interval PT1H \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-08T00:00:00Z

# If CPU < 20%, consider scaling down to B2 or S0
# If CPU > 80%, consider scaling up to S2 or P1V2
```

---

## ✅ Production Deployment Checklist

### Pre-Migration
- [ ] Development environment fully tested
- [ ] All data backed up from dev
- [ ] Production subscription budget approved
- [ ] Production security requirements documented
- [ ] Disaster recovery plan in place

### Infrastructure Deployment
- [ ] Production resource group created
- [ ] Bicep template deployed successfully
- [ ] App Service (S1) running
- [ ] SQL Database (Standard) created
- [ ] Application Insights configured

### Database Setup
- [ ] Database schema imported
- [ ] Data migrated from dev to prod
- [ ] Backups configured (7+ days)
- [ ] Firewall rules configured
- [ ] SQL Agent jobs configured (if needed)

### Application Deployment
- [ ] Latest code deployed to production
- [ ] Connection strings configured
- [ ] App settings updated for production
- [ ] HTTPS enforced
- [ ] TLS 1.2 minimum configured

### Monitoring & Alerts
- [ ] Application Insights enabled
- [ ] Alert rules created
- [ ] Budget alerts configured
- [ ] Diagnostic logging enabled
- [ ] Daily log review schedule set

### Security
- [ ] SQL Server firewall configured
- [ ] HTTPS/SSL certificates valid
- [ ] Application secrets in Key Vault (optional)
- [ ] Role-based access control (RBAC) configured
- [ ] Security scanning enabled (optional)

### Documentation
- [ ] Production URLs documented
- [ ] SQL credentials stored securely
- [ ] Disaster recovery procedures documented
- [ ] Runbook for common issues created
- [ ] Escalation contacts defined

---

## 🆘 Troubleshooting Production Issues

### Issue: 502 Bad Gateway

```bash
# Check app service health
az webapp show -g $PROD_RG_NAME -n $PROD_APP_NAME --query state

# Check connection string
az webapp config appsettings list -g $PROD_RG_NAME -n $PROD_APP_NAME \
  | grep -i connection

# Check logs
az webapp log tail -g $PROD_RG_NAME -n $PROD_APP_NAME

# Restart app
az webapp restart -g $PROD_RG_NAME -n $PROD_APP_NAME
```

### Issue: Database Connection Timeout

```bash
# Test SQL connectivity
sqlcmd -S "$PROD_SQL_FQDN" \
  -U "$PROD_SQL_USER" \
  -P "$PROD_SQL_PASS" \
  -Q "SELECT @@VERSION"

# Check firewall rules
az sql server firewall-rule list \
  -g $PROD_RG_NAME \
  -s $(echo $PROD_SQL_SERVER | cut -d. -f1)

# Add App Service IP if missing
az sql server firewall-rule create \
  -g $PROD_RG_NAME \
  -s $(echo $PROD_SQL_SERVER | cut -d. -f1) \
  --name "AllowAppService" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0
```

### Issue: High Costs

```bash
# Identify expensive resources
az costmanagement query \
  --scope "/subscriptions/$PROD_SUBSCRIPTION_ID" \
  --timeframe MonthToDate \
  --metric ActualCost \
  --groupby "type/dimension" \
  --dimension ResourceType

# Consider scaling down or using reservations
# Review: https://aka.ms/azure-cost-optimization
```

---

## 🎉 Success Criteria

Your production deployment is successful when:

✅ Application is running on production URL
✅ Users can access all API endpoints
✅ Database has all required data
✅ Backups are running automatically
✅ Monitoring shows normal operation
✅ Alerts are configured and tested
✅ Performance is acceptable (< 1 second response time)
✅ Security is configured (HTTPS, firewall rules, etc.)
✅ Cost is within budget

---

## 📋 Post-Deployment Tasks

1. **Day 1**: Monitor closely, check logs frequently
2. **Day 2-3**: Performance testing under load
3. **Day 4-5**: Security review and hardening
4. **Day 6-7**: User acceptance testing (UAT)
5. **Week 2+**: Continuous monitoring and optimization

---

## 🔗 Useful Links

- [Azure App Service Pricing](https://azure.microsoft.com/en-us/pricing/details/app-service/)
- [Azure SQL Database Pricing](https://azure.microsoft.com/en-us/pricing/details/sql-database/)
- [Azure Monitoring Best Practices](https://docs.microsoft.com/en-us/azure/azure-monitor/best-practices)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/)

---

**Congratulations on your production deployment! 🎉**

For support, refer to DEPLOYMENT_GUIDE.md troubleshooting section.
