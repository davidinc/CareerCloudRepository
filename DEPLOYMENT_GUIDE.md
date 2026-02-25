# CareerCloud Azure Deployment Guide

## Prerequisites

Before deployment, ensure you have:

1. **Azure Subscription** - Active Azure subscription with available quota
2. **Azure CLI** - Latest version installed
3. **.NET 6 SDK** - For building the application
4. **Azure Developer CLI (azd)** - Optional but recommended
5. **SQL Tools** - `sqlcmd` or Azure Data Studio for running SQL scripts

### Installation Commands

```bash
# Install Azure CLI
# On Linux/Mac:
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# On Windows (with Chocolatey):
choco install azure-cli

# Install Azure Developer CLI (azd)
curl -fsSL https://aka.ms/install-azd.sh | bash

# Install .NET 6 SDK
# Visit: https://dotnet.microsoft.com/en-us/download/dotnet/6.0
```

---

## Deployment Steps

### Step 1: Authenticate with Azure

```bash
# Login to your Azure account
az login

# Set the default subscription (if you have multiple)
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify authentication
az account show
```

### Step 2: Create a Resource Group

```bash
# Create a resource group for all CareerCloud resources
az group create \
  --name rg-careercloud-dev \
  --location "East US"

# Save the resource group name for later use
RG_NAME="rg-careercloud-dev"
```

### Step 3: Prepare Deployment Parameters

Create a parameters file `infra/main.parameters.json`:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environmentName": {
      "value": "dev"
    },
    "location": {
      "value": "East US"
    },
    "sqlAdminUsername": {
      "value": "sqladmin"
    },
    "sqlAdminPassword": {
      "value": "YourSecurePassword@123"
    },
    "appServicePlanSku": {
      "value": "B1"
    },
    "sqlDatabaseSku": {
      "value": "Basic"
    }
  }
}
```

### Step 4: Validate Deployment

Before deploying, validate the Bicep template:

```bash
# Validation without deployment
az deployment group validate \
  --resource-group $RG_NAME \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json

# Preview what will be deployed (What-If)
az deployment group what-if \
  --resource-group $RG_NAME \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json \
  --result-format "FullResourcePayloads"
```

### Step 5: Deploy Infrastructure

```bash
# Deploy the Bicep template
az deployment group create \
  --name "CareerCloud-Deployment-$(date +%s)" \
  --resource-group $RG_NAME \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json

# Capture deployment outputs
DEPLOYMENT_OUTPUTS=$(az deployment group show \
  --resource-group $RG_NAME \
  --name "CareerCloud-Deployment-..." \
  --query properties.outputs)

echo "Deployment completed. Outputs: $DEPLOYMENT_OUTPUTS"
```

### Step 6: Build and Publish the Application

```bash
# Navigate to the repository
cd CareerCloudRepository

# Restore dependencies
dotnet restore

# Build the solution
dotnet build --configuration Release

# Publish the Web API
dotnet publish CareerCloud.WebAPI/CareerCloud.WebAPI.csproj \
  -c Release \
  -o ./publish
```

### Step 7: Deploy Code to App Service

```bash
# Get the Web App name from deployment outputs
WEB_APP_NAME=$(az deployment group show \
  --resource-group $RG_NAME \
  --name "CareerCloud-Deployment-..." \
  --query properties.outputs.webAppName.value \
  -o tsv)

# Deploy the published application
az webapp deployment source config-zip \
  --resource-group $RG_NAME \
  --name $WEB_APP_NAME \
  --src ./publish.zip

# Or use the built-in deployment
az webapp up \
  --resource-group $RG_NAME \
  --name $WEB_APP_NAME \
  --runtime "DOTNETCORE:6.0"
```

### Step 8: Import SQL Database Schema

```bash
# Get SQL Server details from deployment outputs
SQL_SERVER=$(az deployment group show \
  --resource-group $RG_NAME \
  --name "CareerCloud-Deployment-..." \
  --query properties.outputs.sqlServerFqdn.value \
  -o tsv)

SQL_DB_NAME=$(az deployment group show \
  --resource-group $RG_NAME \
  --name "CareerCloud-Deployment-..." \
  --query properties.outputs.sqlDatabaseName.value \
  -o tsv)

# Import the SQL script using sqlcmd
sqlcmd -S $SQL_SERVER \
  -U sqladmin \
  -P "YourSecurePassword@123" \
  -d $SQL_DB_NAME \
  -i CareerCloud_Database_Script.sql

# Or use Azure Data Studio for a GUI experience
# File > New Database Connection > Connect > Drag & drop SQL file > Execute
```

### Step 9: Verify Deployment

```bash
# Get the Web App URL
WEB_APP_URL=$(az deployment group show \
  --resource-group $RG_NAME \
  --name "CareerCloud-Deployment-..." \
  --query properties.outputs.webAppUrl.value \
  -o tsv)

echo "Web App URL: $WEB_APP_URL"

# Test the API
curl -X GET "$WEB_APP_URL/api/health" -v

# View application logs
az webapp log tail \
  --resource-group $RG_NAME \
  --name $WEB_APP_NAME
```

### Step 10: Configure Application Settings (Optional)

```bash
# Update specific app settings
az webapp config appsettings set \
  --resource-group $RG_NAME \
  --name $WEB_APP_NAME \
  --settings \
    ASPNETCORE_ENVIRONMENT=Production \
    WEBSITE_ENABLE_SYNC_UPDATE_SITE=true

# View current app settings
az webapp config appsettings list \
  --resource-group $RG_NAME \
  --name $WEB_APP_NAME
```

---

## Complete Deployment Script

Save this as `deploy.sh` and run: `bash deploy.sh`

```bash
#!/bin/bash

# CareerCloud Azure Deployment Script
# Usage: bash deploy.sh <environment> <sql_password>

set -e  # Exit on error

ENVIRONMENT=${1:-dev}
SQL_PASSWORD=${2:-ChangeMe@12345}
LOCATION="East US"
RG_NAME="rg-careercloud-${ENVIRONMENT}"
BUILD_DIR="./publish"

echo "======================================"
echo "CareerCloud Deployment Script"
echo "======================================"
echo "Environment: $ENVIRONMENT"
echo "Resource Group: $RG_NAME"
echo "Location: $LOCATION"
echo "======================================"

# Step 1: Create Resource Group
echo "[1/9] Creating resource group..."
az group create \
  --name $RG_NAME \
  --location "$LOCATION" \
  --tags environment=$ENVIRONMENT project=CareerCloud

# Step 2: Validate Bicep Template
echo "[2/9] Validating deployment template..."
az deployment group validate \
  --resource-group $RG_NAME \
  --template-file infra/main.bicep \
  --parameters \
    environmentName=$ENVIRONMENT \
    location="$LOCATION" \
    sqlAdminPassword=$SQL_PASSWORD

# Step 3: Deploy Infrastructure
echo "[3/9] Deploying infrastructure..."
DEPLOY_OUTPUT=$(az deployment group create \
  --resource-group $RG_NAME \
  --template-file infra/main.bicep \
  --parameters \
    environmentName=$ENVIRONMENT \
    location="$LOCATION" \
    sqlAdminPassword=$SQL_PASSWORD \
  --query properties.outputs)

# Extract outputs
WEB_APP_NAME=$(echo $DEPLOY_OUTPUT | jq -r '.webAppName.value' 2>/dev/null || echo "unknown")
SQL_FQDN=$(echo $DEPLOY_OUTPUT | jq -r '.sqlServerFqdn.value' 2>/dev/null || echo "unknown")
SQL_DB_NAME=$(echo $DEPLOY_OUTPUT | jq -r '.sqlDatabaseName.value' 2>/dev/null || echo "unknown")
WEB_APP_URL=$(echo $DEPLOY_OUTPUT | jq -r '.webAppUrl.value' 2>/dev/null || echo "unknown")

echo "Deployment Outputs:"
echo "  Web App Name: $WEB_APP_NAME"
echo "  SQL Server: $SQL_FQDN"
echo "  SQL Database: $SQL_DB_NAME"
echo "  Web App URL: $WEB_APP_URL"

# Step 4: Build .NET Application
echo "[4/9] Building .NET application..."
dotnet restore
dotnet build --configuration Release
dotnet publish CareerCloud.WebAPI/CareerCloud.WebAPI.csproj \
  -c Release \
  -o $BUILD_DIR

# Step 5: Create deployment package
echo "[5/9] Creating deployment package..."
cd $BUILD_DIR
zip -r ../publish.zip .
cd ..

# Step 6: Deploy to App Service
echo "[6/9] Deploying code to App Service..."
az webapp deployment source config-zip \
  --resource-group $RG_NAME \
  --name $WEB_APP_NAME \
  --src ./publish.zip

# Wait for deployment to complete
echo "[7/9] Waiting for deployment to stabilize..."
sleep 30

# Step 8: Import SQL Database Schema
echo "[8/9] Importing SQL database schema..."
echo "Note: Make sure SQL Server accepts connections from your IP"
echo "Run the following command manually if needed:"
echo "sqlcmd -S $SQL_FQDN -U sqladmin -P $SQL_PASSWORD -d $SQL_DB_NAME -i CareerCloud_Database_Script.sql"

# Step 9: Verify Deployment
echo "[9/9] Verifying deployment..."
echo ""
echo "======================================"
echo "Deployment Complete!"
echo "======================================"
echo "Web App URL: $WEB_APP_URL"
echo "Web App Name: $WEB_APP_NAME"
echo "SQL Server: $SQL_FQDN"
echo "Database: $SQL_DB_NAME"
echo "Resource Group: $RG_NAME"
echo ""
echo "Next Steps:"
echo "1. Test the API: curl $WEB_APP_URL/api/health"
echo "2. Import SQL schema when ready:"
echo "   sqlcmd -S $SQL_FQDN -U sqladmin -P $SQL_PASSWORD -d $SQL_DB_NAME -i CareerCloud_Database_Script.sql"
echo "3. Monitor logs: az webapp log tail -g $RG_NAME -n $WEB_APP_NAME"
echo "======================================"
```

---

## Troubleshooting

### Connection String Issues

If the API can't connect to the database:

```bash
# Check app settings
az webapp config appsettings list \
  --resource-group $RG_NAME \
  --name $WEB_APP_NAME \
  --query "[?name=='ConnectionStrings__DataConnection'].value" \
  -o tsv

# Update connection string if needed
az webapp config connection-string set \
  --resource-group $RG_NAME \
  --name $WEB_APP_NAME \
  --connection-string-slots \
    DataConnection="Server=tcp:$SQL_FQDN,1433;..." \
  --connection-string-type SQLServer
```

### SQL Server Access

If SQL scripts fail to run:

```bash
# Add your IP to SQL Server firewall
MY_IP=$(curl -s https://ipinfo.io/json | jq -r '.ip')

az sql server firewall-rule create \
  --resource-group $RG_NAME \
  --server $SQL_SERVER_NAME \
  --name "AllowClientIP" \
  --start-ip-address $MY_IP \
  --end-ip-address $MY_IP
```

### View Application Logs

```bash
# Stream live logs
az webapp log tail \
  --resource-group $RG_NAME \
  --name $WEB_APP_NAME \
  --log-type application

# View Application Insights
az monitor app-insights component show \
  --resource-group $RG_NAME \
  --app appinsights-${ENVIRONMENT}-*
```

---

## Security Considerations

1. **Change Default Passwords** - Replace `YourSecurePassword@123` with a strong password
2. **Use Key Vault** - Store secrets in Azure Key Vault instead of appsettings
3. **Enable HTTPS Only** - Already enabled in the Bicep template
4. **Configure CORS** - Restrict API access if needed
5. **Enable Authentication** - Add Azure AD or OAuth for API security
6. **Network Security** - Consider using Virtual Networks and Private Endpoints for production

---

## Cleanup

To delete all resources and avoid charges:

```bash
# Delete the resource group (and all resources in it)
az group delete \
  --name $RG_NAME \
  --yes \
  --no-wait

echo "Resource group deletion initiated..."
```

---

## Costs Estimate

**Monthly Cost Estimate (Dev environment):**
- App Service Plan (B1): ~$10
- SQL Database (Basic): ~$5
- Application Insights: ~$3
- **Total: ~$18/month**

Costs may vary by region. Check [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/).

---

## Support & Next Steps

1. **Monitor Performance** - Use Application Insights dashboard
2. **Set up CI/CD** - Configure GitHub Actions or Azure Pipelines for automated deployment
3. **Enable Auto-Scaling** - Configure scale-up rules based on metrics
4. **Backup Strategy** - Configure SQL Database automated backups
5. **Disaster Recovery** - Plan for business continuity

