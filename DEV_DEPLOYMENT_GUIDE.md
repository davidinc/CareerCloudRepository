# CareerCloud - Development First Deployment Guide
## With Cost Optimization (MongoDB / SQL License Options)

This guide shows how to deploy to development environment first, then migrate to production with lower subscription costs.

---

## 📊 Cost Comparison

### Option 1: Azure SQL (Expensive)
| Resource | SKU | Monthly Cost |
|----------|-----|--------------|
| App Service | B1 | $10 |
| **SQL Database** | **Basic** | **$5** |
| App Insights | Default | $3 |
| **Total** | | **$18/month** |

### Option 2: MongoDB Atlas (Recommended - FREE Tier)
| Resource | SKU | Monthly Cost |
|----------|-----|--------------|
| App Service | B1 | $10 |
| **MongoDB Atlas** | **Free Tier** | **$0** |
| App Insights | Default | $3 |
| **Total** | | **$13/month** |

### Option 3: SQL License (Your Own)
| Resource | SKU | Monthly Cost |
|----------|-----|--------------|
| App Service | B1 | $10 |
| **SQL Server** | **Your License** | **$0** |
| App Insights | Default | $3 |
| **Total** | | **$13/month** |

**Savings: 28-72% depending on option!**

---

## 🎯 Deployment Strategy

```
Phase 1: Development Environment (THIS WEEK)
├── Deploy to Azure Dev subscription
├── Use MongoDB Atlas Free Tier OR
├── Use your existing SQL license
└── Full testing & validation

        ↓ (After validation)

Phase 2: Production Environment (LATER)
├── Switch to Production subscription
├── Scale resources as needed
├── Implement production security
└── Monitor & optimize costs
```

---

## 🚀 PHASE 1: Development Environment Deployment

### Step 1: Choose Your Database Option

**Option A: MongoDB Atlas (Recommended - Simplest)**
```bash
# Pros: Free tier, no infrastructure cost, cloud-hosted
# Cons: Different from SQL Server (requires EF Core changes)
# Best for: Quick development, cost-sensitive teams
```

**Option B: Use Existing SQL License**
```bash
# Pros: Same database, no cloud costs
# Cons: Requires on-premise SQL Server access
# Best for: Enterprise environments with licenses
```

**For this guide, we'll use MongoDB Atlas (Free Tier)**

### Step 2: Prerequisites

```bash
# Install required tools
az --version        # Azure CLI 2.40+
dotnet --version   # .NET 6 SDK
git --version       # Git

# Verify installations
az login           # Test Azure connection
```

### Step 3: Create MongoDB Atlas Free Account

**A. Go to MongoDB Atlas**
```
1. Visit: https://www.mongodb.com/cloud/atlas
2. Click "Try Free"
3. Sign up with email
4. Create organization
5. Create project named "CareerCloud-Dev"
```

**B. Create Free Cluster**
```
1. Click "Create" → "Database"
2. Select "Shared" (Free tier)
3. Choose region close to you (e.g., Eastern US)
4. Cluster name: "careercloud-dev"
5. Click "Create Cluster"
6. Wait 5-10 minutes for cluster to initialize
```

**C. Get Connection String**
```
1. In MongoDB Atlas, click "Connect"
2. Select "Drivers" → "Node.js" (for connection string)
3. Copy connection string: 
   mongodb+srv://username:password@careercloud-dev.xxxxx.mongodb.net/careercloud?retryWrites=true&w=majority
4. Save for later use
```

**D. Create Database User**
```
1. In Atlas: Click "Database Access"
2. Click "Add New Database User"
3. Username: careercloud_user
4. Password: Generate secure password (save it!)
5. Click "Add User"
6. Note: Username and password will be used in connection string
```

**E. Whitelist Your IP** (or allow all)
```
1. Click "Network Access"
2. Click "Add IP Address"
3. Option A: Add your current IP
4. Option B: Click "Allow Access from Anywhere" (0.0.0.0/0)
   ⚠️ Only for development! Restrict in production
5. Click "Confirm"
```

### Step 4: Update Application for MongoDB

**A. Modify `appsettings.json`**

In `CareerCloud.WebAPI/appsettings.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "MongoDbConnection": "mongodb+srv://careercloud_user:YourPassword@careercloud-dev.xxxxx.mongodb.net/careercloud?retryWrites=true&w=majority"
  },
  "MongoDbSettings": {
    "DatabaseName": "careercloud",
    "ConnectionString": "mongodb+srv://careercloud_user:YourPassword@careercloud-dev.xxxxx.mongodb.net/careercloud?retryWrites=true&w=majority"
  }
}
```

**B. Add MongoDB NuGet Package**

```bash
cd CareerCloud.WebAPI

# Add MongoDB driver
dotnet add package MongoDB.Driver

# Or manually update .csproj and run:
dotnet restore
```

**C. Update Startup.cs** (if using traditional startup)

```csharp
services.AddSingleton<MongoDbSettings>(sp =>
{
    var config = sp.GetRequiredService<IConfiguration>();
    return new MongoDbSettings
    {
        DatabaseName = "careercloud",
        ConnectionString = config.GetConnectionString("MongoDbConnection")
    };
});

// If using Entity Framework with SQL:
var sqlConnection = configuration.GetConnectionString("DataConnection");
services.AddDbContext<CareerCloudDbContext>(options =>
    options.UseSqlServer(sqlConnection));
```

### Step 5: Update Connection String in Code

**Create configuration class** (`DbSettings.cs`):

```csharp
public class DbSettings
{
    public string ConnectionString { get; set; }
    public string DatabaseName { get; set; }
}

// Or keep existing SQL if using SQL license:
public class SqlDbSettings
{
    public string ConnectionString { get; set; }
}
```

### Step 6: Create Azure Resource Group for Dev

```bash
# Set variables
RG_NAME="rg-careercloud-dev"
LOCATION="East US"
SUBSCRIPTION="your-dev-subscription-id"

# Set subscription (if you have multiple)
az account set --subscription "$SUBSCRIPTION"

# Create resource group
az group create \
  --name $RG_NAME \
  --location "$LOCATION" \
  --tags environment=development project=CareerCloud

# Verify creation
az group show --name $RG_NAME
```

### Step 7: Deploy Infrastructure (Minimal Cost)

**Create lightweight-dev.bicep** for development:

```bicep
// Minimal development infrastructure
// This creates only App Service (no expensive SQL DB)

targetScope = 'resourceGroup'

param environmentName string = 'dev'
param location string = resourceGroup().location

// App Service Plan (B1 - cheapest)
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'plan-careercloud-${environmentName}'
  location: location
  kind: 'linux'
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  properties: {
    reserved: true
  }
}

// App Service
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: 'app-careercloud-${environmentName}'
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|6.0'
      alwaysOn: false
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Development'
        }
        {
          name: 'MongoDbConnection'
          value: 'mongodb+srv://careercloud_user:password@cluster.xxxxx.mongodb.net/careercloud'
        }
      ]
    }
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appinsights-careercloud-${environmentName}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 30
  }
}

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppName string = webApp.name
```

### Step 8: Deploy Dev Infrastructure

```bash
# Deploy using Bicep
az deployment group create \
  --name CareerCloud-Dev-Deployment \
  --resource-group $RG_NAME \
  --template-file infra/lightweight-dev.bicep \
  --parameters \
    environmentName=dev \
    location="East US"

# Get outputs
OUTPUTS=$(az deployment group show \
  --resource-group $RG_NAME \
  --name CareerCloud-Dev-Deployment \
  --query properties.outputs -o json)

WEB_APP_NAME=$(echo $OUTPUTS | jq -r '.webAppName.value')
WEB_APP_URL=$(echo $OUTPUTS | jq -r '.webAppUrl.value')

echo "Web App Name: $WEB_APP_NAME"
echo "Web App URL: $WEB_APP_URL"
```

### Step 9: Build and Deploy Application

```bash
# Navigate to repository
cd /home/dawit/azuredev-66ed/CareerCloudRepository

# Restore dependencies
dotnet restore

# Build in Release mode
dotnet build --configuration Release

# Publish WebAPI
dotnet publish CareerCloud.WebAPI/CareerCloud.WebAPI.csproj \
  -c Release \
  -o ./publish

# Create deployment package
cd publish
zip -r ../publish.zip .
cd ..

# Deploy to App Service
az webapp deployment source config-zip \
  --resource-group $RG_NAME \
  --name $WEB_APP_NAME \
  --src ./publish.zip

echo "Deployment started... Please wait 5-10 minutes"
```

### Step 10: Verify Dev Deployment

```bash
# Wait for app to be ready
sleep 30

# Check deployment status
echo "Checking deployment status..."
az webapp deployment list \
  --resource-group $RG_NAME \
  --name $WEB_APP_NAME

# Check logs
echo "Recent application logs:"
az webapp log tail \
  --resource-group $RG_NAME \
  --name $WEB_APP_NAME \
  --lines 50

# Test API endpoint
echo "Testing API..."
curl -X GET "$WEB_APP_URL/api/health" -v

# Expected output: Should return status 200 or 404 (not 502/503)
```

### Step 11: Testing in Development

```bash
# Use Postman or curl to test

# Test health endpoint
curl -X GET "https://app-careercloud-dev-xxxx.azurewebsites.net/api/health"

# Test a data endpoint (example)
curl -X GET "https://app-careercloud-dev-xxxx.azurewebsites.net/api/applicants"

# Create sample data
curl -X POST "https://app-careercloud-dev-xxxx.azurewebsites.net/api/applicants" \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'

# Check logs for any errors
az webapp log tail -g $RG_NAME -n $WEB_APP_NAME
```

---

## 💾 DATABASE OPTIONS (Detailed)

### Option A: MongoDB Atlas (FREE - Recommended)

```
Step 1: Create account at https://www.mongodb.com/cloud/atlas
Step 2: Create free shared cluster (0.5 GB storage)
Step 3: Get connection string
Step 4: Update appsettings.json with connection string
Step 5: Test connection from App Service

Pros:
✅ Free tier (0.5 GB - great for dev)
✅ 512 MB RAM
✅ Shared cluster
✅ 24-hour backup retention
✅ No credit card required

Cons:
❌ Requires code changes (MongoDB instead of SQL)
❌ Different query syntax
❌ No SQL joins (requires aggregation pipeline)
```

**Cost: $0/month for development**

---

### Option B: Your Existing SQL Server License

```
If you have SQL Server license (Standard, Enterprise, Developer):

Step 1: Ensure SQL Server is running on-premise or VM
Step 2: Create CareerCloud database
Step 3: Import CareerCloud_Database_Script.sql
Step 4: Expose SQL Server to internet (if needed) with VPN/Gateway
Step 5: Update connection string in appsettings.json

Connection String Example:
Data Source=your-server.com,1433;
Initial Catalog=CareerCloud;
User ID=sa;
Password=YourPassword;
Encrypt=true;
TrustServerCertificate=false;

Pros:
✅ No Azure SQL costs
✅ Same database structure
✅ Fast local connection (if on-premise)
✅ No code changes needed

Cons:
❌ Requires VPN/gateway for remote access
❌ Your responsibility for backups
❌ Your responsibility for security
```

**Cost: $0/month (use existing license)**

---

### Option C: Azure SQL Free Trial

```
If you want to evaluate Azure SQL:

Step 1: New Azure subscription gets $200 credit
Step 2: Use that credit for SQL evaluation
Step 3: Migrate to MongoDB/License after trial

Pros:
✅ Full evaluation of Azure services
✅ $200 free credit
✅ Same database structure (no code changes)

Cons:
❌ Credit expires after 30 days
❌ Requires credit card
❌ May not cover production costs
```

**Cost: $0 for first month (with $200 credit)**

---

## 🔄 PHASE 2: Switch to Production (Later)

### When You're Ready for Production:

```bash
# Step 1: Create NEW subscription or use existing prod subscription
PROD_RG="rg-careercloud-prod"
PROD_SUBSCRIPTION="your-prod-subscription-id"

# Step 2: Switch subscription
az account set --subscription "$PROD_SUBSCRIPTION"

# Step 3: Deploy production infrastructure
az deployment group create \
  --name CareerCloud-Prod-Deployment \
  --resource-group $PROD_RG \
  --template-file infra/main.bicep \
  --parameters \
    environmentName=prod \
    sqlAdminPassword="YourStrongPassword@123"

# Step 4: Deploy application
# (Same as dev, but to prod resources)

# Step 5: Migrate data from dev to prod
# (MongoDB export/import OR SQL backup/restore)
```

---

## 📋 Step-by-Step CHECKLIST for Development Deployment

### Pre-Deployment (Day 1)
- [ ] Install Azure CLI, .NET 6, Git
- [ ] Create MongoDB Atlas free account
- [ ] Get MongoDB connection string
- [ ] Fork/clone CareerCloud repository
- [ ] Update `appsettings.json` with MongoDB connection
- [ ] Add MongoDB.Driver NuGet package

### Azure Setup (Day 1)
- [ ] Verify Azure account access
- [ ] Get development subscription ID
- [ ] Create resource group `rg-careercloud-dev`
- [ ] Create lightweight-dev.bicep template

### Deployment (Day 1)
- [ ] Deploy infrastructure to dev
- [ ] Build .NET application
- [ ] Deploy app to App Service
- [ ] Verify deployment logs

### Testing (Day 1-2)
- [ ] Test API endpoints
- [ ] Test MongoDB connection
- [ ] Add sample data
- [ ] Monitor application logs
- [ ] Fix any connection issues

### Documentation (Day 2)
- [ ] Document dev environment details
- [ ] Save deployment URLs
- [ ] Document MongoDB connection string (encrypted)
- [ ] Create dev test plan

---

## 🎯 QUICK START SCRIPT

Save this as `deploy-dev.sh`:

```bash
#!/bin/bash

set -e

# Configuration
RG_NAME="rg-careercloud-dev"
LOCATION="East US"
MONGODB_CONNECTION="mongodb+srv://user:password@cluster.xxxxx.mongodb.net/careercloud"
WEB_APP_NAME="app-careercloud-dev"

echo "🚀 Deploying CareerCloud to Development Environment"
echo "Resource Group: $RG_NAME"
echo "Location: $LOCATION"
echo ""

# Step 1: Create resource group
echo "[1/6] Creating resource group..."
az group create \
  --name $RG_NAME \
  --location "$LOCATION" \
  --tags environment=dev project=CareerCloud

# Step 2: Deploy infrastructure
echo "[2/6] Deploying infrastructure..."
az deployment group create \
  --name CareerCloud-Dev \
  --resource-group $RG_NAME \
  --template-file infra/lightweight-dev.bicep \
  --parameters environmentName=dev location="$LOCATION"

# Step 3: Get deployment outputs
echo "[3/6] Retrieving deployment details..."
WEB_APP_NAME=$(az deployment group show \
  --resource-group $RG_NAME \
  --name CareerCloud-Dev \
  --query properties.outputs.webAppName.value -o tsv)

# Step 4: Build application
echo "[4/6] Building application..."
dotnet restore
dotnet build --configuration Release
dotnet publish CareerCloud.WebAPI/CareerCloud.WebAPI.csproj -c Release -o ./publish

# Step 5: Deploy to App Service
echo "[5/6] Deploying to App Service..."
cd publish && zip -r ../publish.zip . && cd ..
az webapp deployment source config-zip \
  --resource-group $RG_NAME \
  --name $WEB_APP_NAME \
  --src ./publish.zip

# Step 6: Verify
echo "[6/6] Verifying deployment..."
sleep 30

WEB_APP_URL=$(az webapp show \
  --resource-group $RG_NAME \
  --name $WEB_APP_NAME \
  --query defaultHostName -o tsv)

echo ""
echo "✅ Deployment Complete!"
echo "Web App URL: https://$WEB_APP_URL"
echo "MongoDB Connection: $MONGODB_CONNECTION"
echo ""
echo "Test the API:"
echo "curl -X GET 'https://$WEB_APP_URL/api/health'"
```

Run it:
```bash
chmod +x deploy-dev.sh
./deploy-dev.sh
```

---

## 🔐 Security for Development

```bash
# ⚠️ IMPORTANT: Development Security Checklist

# 1. Protect sensitive data
# Never commit connection strings to git
echo "MongoDB URL" > .env
echo ".env" >> .gitignore

# 2. Use strong passwords for MongoDB
# Generate: https://docs.microsoft.com/en-us/sql/relational-databases/security/password-policy
# Example: P@ssw0rd_D3v2024!

# 3. Restrict network access (after dev phase)
# Only allow your IP in MongoDB Atlas
# Not "Allow from Anywhere" (0.0.0.0/0)

# 4. Rotate credentials monthly
# Update MongoDB password regularly
# Update SQL Server password regularly

# 5. Enable logging
# Check App Service logs daily during development
az webapp log tail -g $RG_NAME -n $WEB_APP_NAME

# 6. Monitor costs daily
# Check Azure billing to ensure free tier limits
az vm list-usage --location "$LOCATION"
```

---

## 📊 Monitor Development Costs

```bash
# Check current spending
az billing accounts list

# Set up budget alert (optional)
az billing budget create \
  --name CareerCloud-Dev-Budget \
  --amount 50 \
  --category "Total spending"

# View App Service metrics
az monitor metrics list \
  --resource /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.Web/sites/$WEB_APP_NAME
```

---

## ❌ Cleanup Development Environment (If Needed)

```bash
# Delete entire dev environment
az group delete \
  --name $RG_NAME \
  --yes \
  --no-wait

# Delete MongoDB cluster (if using Atlas)
# Go to MongoDB Atlas → Cluster → Delete Cluster

# Estimated time: 5-10 minutes
# Cost savings: $13-18/month
```

---

## 📞 Common Issues & Solutions

### Issue 1: Cannot connect to MongoDB
```bash
# Solution 1: Verify connection string
# Check username and password are URL encoded

# Solution 2: Add your IP to MongoDB Atlas
# Go to Network Access → Add IP Address

# Solution 3: Test connection locally
# Install MongoDB Compass
# Try connecting from local machine first
```

### Issue 2: App Service returns 502 Bad Gateway
```bash
# Solution 1: Wait 5-10 minutes (deployment still in progress)

# Solution 2: Check logs
az webapp log tail -g $RG_NAME -n $WEB_APP_NAME

# Solution 3: Verify connection string
az webapp config appsettings list -g $RG_NAME -n $WEB_APP_NAME

# Solution 4: Restart app service
az webapp restart -g $RG_NAME -n $WEB_APP_NAME
```

### Issue 3: MongoDB cluster initializing
```bash
# MongoDB free tier takes 5-10 minutes to initialize
# Wait for status to show "Active" in MongoDB Atlas dashboard
# Check status: https://cloud.mongodb.com/v2/projects
```

---

## 🎁 Next Steps After Dev Deployment

1. **Test thoroughly** (2-3 days)
   - Create test data
   - Test all API endpoints
   - Load test if needed

2. **Get approval** (1 day)
   - Demo to stakeholders
   - Get sign-off for production

3. **Prepare production** (1 day)
   - Set up production subscription
   - Update configurations
   - Plan data migration

4. **Deploy to production** (1 day)
   - Follow Phase 2 steps
   - Scale resources as needed
   - Switch to production database

---

## 📝 Development Deployment Summary

**Timeline**: 2-3 hours total
- Prerequisites: 15 minutes
- Azure setup: 15 minutes
- Deployment: 30 minutes
- Testing: 60 minutes

**Cost**: $13-18/month OR $0 (if using MongoDB Free + your SQL license)

**Next**: Production deployment after validation

---

## 🚀 Ready to Deploy?

```bash
# Option 1: Run automated script
chmod +x deploy-dev.sh
./deploy-dev.sh

# Option 2: Follow steps manually
# (See "Step-by-Step CHECKLIST" above)

# Option 3: Use Azure Portal UI
# (Click "Create Resource" → "App Service")
```

**Choose your path and start deploying!**

