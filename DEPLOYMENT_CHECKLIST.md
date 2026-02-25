# CareerCloud Azure Deployment Checklist

## Pre-Deployment Requirements ✅

- [ ] Azure subscription active and accessible
- [ ] Azure CLI installed (`az --version`)
- [ ] .NET 6 SDK installed (`dotnet --version`)
- [ ] SQL Command-line tool installed (`sqlcmd` or Azure Data Studio)
- [ ] Git repository cloned locally
- [ ] All configuration files reviewed and updated

## Authentication & Access ✅

- [ ] Logged in to Azure (`az login`)
- [ ] Correct subscription selected (`az account list`)
- [ ] Permissions to create resources (Subscription Contributor role)
- [ ] IP address allowed for SQL Server (firewall rule)

## Pre-Deployment Configuration ✅

- [ ] Update `.env` file with:
  - [ ] Environment name (dev/staging/prod)
  - [ ] Azure location
  - [ ] **SQL Admin password** (STRONG PASSWORD!)
  - [ ] Subscription ID
- [ ] Review `infra/main.parameters.json`:
  - [ ] App Service Plan SKU (B1 for dev, S1+ for production)
  - [ ] SQL Database SKU (Basic for dev, Standard/Premium for production)
- [ ] Create resource group YAML (optional)

## Infrastructure Deployment ✅

- [ ] Validate Bicep template:
  ```bash
  az deployment group validate \
    --resource-group $RG_NAME \
    --template-file infra/main.bicep \
    --parameters infra/main.parameters.json
  ```
  
- [ ] Run what-if to review changes:
  ```bash
  az deployment group what-if \
    --resource-group $RG_NAME \
    --template-file infra/main.bicep \
    --parameters infra/main.parameters.json --result-format FullResourcePayloads
  ```

- [ ] Deploy Bicep template:
  ```bash
  az deployment group create \
    --name CareerCloud-Deployment \
    --resource-group $RG_NAME \
    --template-file infra/main.bicep \
    --parameters infra/main.parameters.json
  ```

- [ ] Verify deployment completed successfully
- [ ] Check deployment outputs:
  ```bash
  az deployment group show \
    --resource-group $RG_NAME \
    --name CareerCloud-Deployment \
    --query properties.outputs
  ```
- [ ] Document resource names and IDs from deployment outputs

## Application Deployment ✅

### Build Phase
- [ ] Restore NuGet packages:
  ```bash
  dotnet restore
  ```
  
- [ ] Build in Release mode:
  ```bash
  dotnet build --configuration Release
  ```
  
- [ ] Run tests (if any):
  ```bash
  dotnet test
  ```
  
- [ ] Publish the WebAPI:
  ```bash
  dotnet publish CareerCloud.WebAPI/CareerCloud.WebAPI.csproj \
    -c Release -o ./publish
  ```

- [ ] Create deployment ZIP package:
  ```bash
  cd publish && zip -r ../publish.zip . && cd ..
  ```

### Deployment Phase
- [ ] Deploy to App Service via ZIP:
  ```bash
  az webapp deployment source config-zip \
    --resource-group $RG_NAME \
    --name $WEB_APP_NAME \
    --src ./publish.zip
  ```

- [ ] Wait for deployment to complete (5-10 minutes)
- [ ] Start the App Service if not auto-started:
  ```bash
  az webapp start --resource-group $RG_NAME --name $WEB_APP_NAME
  ```

- [ ] Check deployment status:
  ```bash
  az webapp deployment list --resource-group $RG_NAME --name $WEB_APP_NAME
  ```

## Database Setup ✅

### Check SQL Server Access
- [ ] Verify SQL Server firewall rules:
  ```bash
  az sql server firewall-rule list \
    --resource-group $RG_NAME \
    --server $SQL_SERVER_NAME
  ```

- [ ] Add your IP if needed:
  ```bash
  az sql server firewall-rule create \
    --resource-group $RG_NAME \
    --server $SQL_SERVER_NAME \
    --name AllowMyIP \
    --start-ip-address $MY_IP \
    --end-ip-address $MY_IP
  ```

### Import Database Schema
- [ ] Test SQL connection:
  ```bash
  sqlcmd -S $SQL_SERVER_FQDN -U sqladmin -P $SQL_PASSWORD \
    -d master -q "SELECT @@VERSION"
  ```

- [ ] Run database creation script:
  ```bash
  sqlcmd -S $SQL_SERVER_FQDN \
    -U sqladmin \
    -P $SQL_PASSWORD \
    -d $SQL_DATABASE_NAME \
    -i CareerCloud_Database_Script.sql
  ```

- [ ] Verify tables created:
  ```bash
  sqlcmd -S $SQL_SERVER_FQDN \
    -U sqladmin \
    -P $SQL_PASSWORD \
    -d $SQL_DATABASE_NAME \
    -q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME"
  ```

- [ ] Sample query test:
  ```bash
  sqlcmd -S $SQL_SERVER_FQDN \
    -U sqladmin \
    -P $SQL_PASSWORD \
    -d $SQL_DATABASE_NAME \
    -q "SELECT COUNT(*) as TableCount FROM (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE') t"
  ```

## Post-Deployment Verification ✅

### API Connectivity
- [ ] Get Web App URL:
  ```bash
  az webapp show --resource-group $RG_NAME --name $WEB_APP_NAME --query defaultHostName
  ```

- [ ] Test API health endpoint:
  ```bash
  curl -X GET "https://$WEB_APP_URL/api/health" -v
  ```

- [ ] Test API with swagger (if available):
  ```bash
  curl -X GET "https://$WEB_APP_URL/swagger/index.html"
  ```

- [ ] Monitor deployment logs:
  ```bash
  az webapp log tail --resource-group $RG_NAME --name $WEB_APP_NAME
  ```

### Application Settings Verification
- [ ] Check connection string is set:
  ```bash
  az webapp config appsettings list --resource-group $RG_NAME --name $WEB_APP_NAME \
    --query "[?name=='ConnectionStrings__DataConnection'].value"
  ```

- [ ] Verify environment configuration:
  ```bash
  az webapp config appsettings list --resource-group $RG_NAME --name $WEB_APP_NAME \
    --query "[?name=='ASPNETCORE_ENVIRONMENT'].value"
  ```

- [ ] Check Application Insights is connected:
  ```bash
  az webapp config appsettings list --resource-group $RG_NAME --name $WEB_APP_NAME \
    --query "[?name=='APPINSIGHTS_CONNECTIONSTRING'].value"
  ```

### Database Verification
- [ ] Verify database size:
  ```bash
  sqlcmd -S $SQL_SERVER_FQDN -U sqladmin -P $SQL_PASSWORD \
    -d $SQL_DATABASE_NAME \
    -q "SELECT DB_NAME() as DatabaseName, CAST(SUM(size)*8./1024 AS DECIMAL(18,2)) as SizeMB FROM sys.master_files WHERE name LIKE N'%' GROUP BY name" 
  ```

- [ ] Check for any errors in database:
  ```bash
  sqlcmd -S $SQL_SERVER_FQDN -U sqladmin -P $SQL_PASSWORD \
    -d $SQL_DATABASE_NAME \
    -q "DBCC CHECKDB" timeout=60
  ```

## Monitoring & Logging Setup ✅

- [ ] Enable Application Insights:
  ```bash
  az webapp log show --name $WEB_APP_NAME --resource-group $RG_NAME
  ```

- [ ] View Application Insights metrics:
  ```bash
  az monitor metrics list --resource /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Insights/components/appinsights-* \
    --interval PT1M
  ```

- [ ] Set up alerting (optional):
  ```bash
  az monitor metrics alert create \
    --name HighErrorRate \
    --resource-group $RG_NAME \
    --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Insights/components/*"
  ```

- [ ] Review resource logs:
  ```bash
  az monitor log-analytics workspace list --resource-group $RG_NAME
  ```

## Security Hardening ✅

- [ ] Change SQL admin password post-deployment
- [ ] Enable SQL Database firewall rules (restrict to app only)
- [ ] Enable HTTPS only on App Service (already done)
- [ ] Configure CORS if needed:
  ```bash
  az webapp cors add --resource-group $RG_NAME --name $WEB_APP_NAME \
    --allowed-origins "https://yourdomain.com"
  ```

- [ ] Set up backup for SQL Database:
  ```bash
  az sql db short-term-retention-policy update \
    --resource-group $RG_NAME \
    --server $SQL_SERVER_NAME \
    --database $SQL_DATABASE_NAME \
    --retention-days 7
  ```

- [ ] Enable auditing (optional):
  ```bash
  az sql server audit-policy update --resource-group $RG_NAME \
    --server $SQL_SERVER_NAME --state Enabled
  ```

## Documentation & Handoff ✅

- [ ] Document all deployed resource IDs
- [ ] Save deployment outputs to file:
  ```bash
  az deployment group show \
    --resource-group $RG_NAME \
    --name CareerCloud-Deployment \
    --query properties.outputs > deployment-outputs.json
  ```

- [ ] Create postman collection with API endpoints
- [ ] Update README with:
  - [ ] Deployed API URL
  - [ ] Database connection details (for team reference)
  - [ ] Environment setup instructions
  - [ ] Known issues or workarounds

- [ ] Schedule deployment review meeting
- [ ] Set up team access to:
  - [ ] Azure Portal resource group
  - [ ] Application Insights dashboard
  - [ ] SQL Database

## Post-Deployment Maintenance ✅

### Immediate (First Hour)
- [ ] Monitor application logs for errors
- [ ] Test API endpoints thoroughly
- [ ] Verify database connections work

### Short Term (First Week)
- [ ] Monitor Application Insights metrics
- [ ] Check cost of deployed resources
- [ ] Review and adjust resource sizes if needed
- [ ] Set up automated backups if not enabled

### Ongoing
- [ ] Plan next deployment/updates
- [ ] Set up CI/CD pipeline (GitHub Actions/Azure Pipelines)
- [ ] Document lessons learned
- [ ] Plan for disaster recovery

## Rollback Plan (If Needed)

If deployment fails:

1. **Delete everything:**
   ```bash
   az group delete --name $RG_NAME --yes --no-wait
   ```

2. **Retrace steps:**
   - Check deployment logs: `az deployment group show --resource-group $RG_NAME --name CareerCloud-Deployment`
   - Fix configuration
   - Restart from "Infrastructure Deployment" step

3. **Restore from backup** (if available in production)

---

## Deployment Summary Form

```
Deployment Date: _______________
Deployed By: ____________________
Environment: ____________________

Resource Group: _________________
Web App Name: ___________________
Web App URL: ____________________

SQL Server: ______________________
SQL Database: ____________________

Deployment Status: ✅ SUCCESSFUL / ❌ FAILED

Issues Encountered: ______________

Post-Deployment Sign-Off:
- QA Team: _____ Date: _____
- DevOps Team: _____ Date: _____
- Product Owner: _____ Date: _____
```

---

**Total Estimated Time: 45-60 minutes**

If any step fails, check the troubleshooting section in DEPLOYMENT_GUIDE.md
