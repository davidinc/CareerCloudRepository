# CareerCloud Azure Deployment Package

Complete infrastructure and deployment configuration for deploying CareerCloud to Microsoft Azure.

## 📋 Contents

### 📁 Infrastructure (IaC)
- **`infra/main.bicep`** (273 lines) - Main Bicep template orchestrating all Azure resources
  - Azure SQL Server and Database
  - App Service Plan and Web App
  - Application Insights for monitoring
  - Firewall rules and security configuration

- **`infra/main.parameters.json`** - Parameter values for Bicep deployment
  - Update SQL password before deployment
  - Configure SKUs based on environment

### 📖 Documentation
- **`DEPLOYMENT_GUIDE.md`** (457 lines) - Comprehensive step-by-step deployment instructions
  - Prerequisites and installation
  - Manual deployment using Azure CLI
  - Troubleshooting and rollback procedures
  - Cost estimation

- **`DEPLOYMENT_CHECKLIST.md`** (369 lines) - Detailed checklist for deployment verification
  - Pre-deployment verification
  - Step-by-step checklist with commands
  - Post-deployment health checks
  - Security hardening steps

- **`DATABASE_SCHEMA_DOCUMENTATION.md`** (16 KB) - Database design documentation
  - Entity descriptions and relationships
  - Data type mappings
  - Performance considerations
  - Security notes

### 🤖 Automation
- **`deploy-azure.sh`** (11 KB) - Automated deployment script
  - Single-command deployment
  - Prerequisites validation
  - Complete end-to-end automation
  - Health check verification

- **`azure.yaml`** - Azure Developer CLI configuration
  - Service definitions
  - Infrastructure template reference
  - Metadata

### 📝 Scripts
- **`CareerCloud_Database_Script.sql`** (15 KB) - SQL database schema
  - 19 tables with relationships
  - Indexes for performance
  - Sample data inserts (optional)
  - User and security setup

- **`.env.sample`** - Environment configuration template
  - Database credentials
  - Resource naming
  - Application settings

---

## 🚀 Quick Start

### Option 1: Automated Deployment (Recommended)

```bash
# Make script executable
chmod +x deploy-azure.sh

# Deploy to dev environment
./deploy-azure.sh dev YourStrongPassword@123

# Or deploy to production
./deploy-azure.sh prod YourStrongPassword@123
```

**Estimated time: 15-20 minutes** (automated script handles all steps)

### Option 2: Manual Deployment (Step-by-Step)

Follow the detailed instructions in [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

```bash
# 1. Authenticate
az login

# 2. Create resource group
az group create --name rg-careercloud-dev --location "East US"

# 3. Deploy infrastructure
az deployment group create \
  --name CareerCloud-Deployment \
  --resource-group rg-careercloud-dev \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json \
  --parameters sqlAdminPassword="YourPassword@123"

# 4. Build and deploy app
dotnet publish CareerCloud.WebAPI/CareerCloud.WebAPI.csproj -c Release
# ... deploy to App Service

# 5. Import database
sqlcmd -S server.database.windows.net -U sqladmin -P Password -d database \
  -i CareerCloud_Database_Script.sql
```

---

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Azure Resources                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │  App Service │────────▶│ SQL Database │                 │
│  │  (CareerCloud)         │  (Job Portal)│                 │
│  └──────────────┘         └──────────────┘                 │
│         │                                                   │
│         │                  ┌──────────────┐                │
│         └─────────────────▶│  App Insights│                │
│                            │  (Monitoring)│                │
│                            └──────────────┘                │
│                                                              │
│  Security Features:                                        │
│  ✓ HTTPS/TLS 1.2 minimum                                   │
│  ✓ SQL encryption at rest                                  │
│  ✓ Firewall rules                                          │
│  ✓ Application Insights monitoring                         │
│  ✓ System-assigned managed identity                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔐 Security Features Included

✅ **Encryption**
- HTTPS/TLS 1.2 minimum
- SQL Database TDE (Transparent Data Encryption)
- Connection string encryption

✅ **Network Security**
- SQL Server firewall rules
- App-only access to SQL
- Azure services allowed

✅ **Application Security**
- Managed Identity for resources
- Environment-based configuration
- Connection string injection

✅ **Monitoring**
- Application Insights integration
- Diagnostic logging
- Performance metrics

---

## 💰 Cost Estimation

**Monthly Costs (Dev Environment):**
| Resource | SKU | MonthlyCost |
|----------|-----|------------|
| App Service Plan | B1 | ~$10 |
| SQL Database | Basic | ~$5 |
| Application Insights | Default | ~$3 |
| **Total** | | **~$18/month** |

**Production Environment (estimated):**
- App Service: S1 or higher: ~$50+
- SQL Database: Standard/Premium: $30-100+
- Total: ~$100-200+/month

See [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/) for exact pricing.

---

## 🔧 Configuration

### Environment Variables

Key environment variables set by the Bicep template:
```
ASPNETCORE_ENVIRONMENT=Development|Production
APPINSIGHTS_CONNECTIONSTRING=<instrumentation-key>
ConnectionStrings__DataConnection=<sql-connection-string>
```

### App Settings

Configure in Azure Portal or via CLI:
```bash
az webapp config appsettings set \
  --resource-group $RG_NAME \
  --name $WEB_APP_NAME \
  --settings KEY=VALUE
```

### Connection String

The Bicep template automatically configures:
- **Integrated Security**: Native SQL authentication
- **Connection Pooling**: Enabled
- **Encryption**: Required (TrustServerCertificate=False)
- **Timeout**: 30 seconds

---

## 📚 Database Schema

The deployment includes 19 tables organized in logical modules:

**Security Module:**
- Security_Logins
- Security_Roles
- Security_Logins_Roles
- Security_Logins_Log

**Company Module:**
- Company_Profiles
- Company_Descriptions
- Company_Locations
- Company_Jobs
- Company_Jobs_Descriptions
- Company_Job_Skills
- Company_Job_Educations

**Applicant Module:**
- Applicant_Profiles
- Applicant_Work_History
- Applicant_Educations
- Applicant_Skills
- Applicant_Resumes
- Applicant_Job_Applications

**System Module:**
- System_Country_Codes
- System_Language_Codes

See [DATABASE_SCHEMA_DOCUMENTATION.md](DATABASE_SCHEMA_DOCUMENTATION.md) for detailed entity descriptions.

---

## ✅ Verification Steps

After deployment, verify everything is working:

```bash
# 1. Check deployment status
az deployment group show -g $RG_NAME -n $DEPLOYMENT_NAME

# 2. Test API endpoint
curl -X GET "https://$WEB_APP_URL/api/health"

# 3. Verify database connection
sqlcmd -S $SQL_SERVER -U sqladmin -P $PASSWORD -d $SQL_DB_NAME \
  -q "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES"

# 4. Check Application Insights
az monitor metrics list --resource /subscriptions/$SUB_ID/resourceGroups/$RG_NAME/providers/Microsoft.Insights/components/*

# 5. View application logs
az webapp log tail -g $RG_NAME -n $WEB_APP_NAME
```

---

## 🛠️ Troubleshooting

### Common Issues

**Problem:** Deployment fails with permissions error
```
Solution: Ensure you have Contributor or higher role on subscription
az role assignment list --assignee <user-id>
```

**Problem:** Can't connect to SQL Database
```
Solution: Add your IP to SQL Server firewall
az sql server firewall-rule create -g $RG_NAME -s $SQL_SERVER \
  --name AllowMyIP --start-ip-address <your-ip> --end-ip-address <your-ip>
```

**Problem:** App Service shows "502 Bad Gateway"
```
Solution: Wait 5-10 minutes for deployment, check logs:
az webapp log tail -g $RG_NAME -n $WEB_APP_NAME
```

**Problem:** Database migration fails
```
Solution: Verify schema with:
sqlcmd -S $SQL_SERVER -U sqladmin -P $PASSWORD -d $SQL_DB_NAME \
  -q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES"
```

For more troubleshooting, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#troubleshooting).

---

## 🔄 Updates & Maintenance

### Updating Application Code

```bash
# Build new version
dotnet publish CareerCloud.WebAPI -c Release -o ./publish

# Deploy to App Service
az webapp deployment source config-zip \
  -g $RG_NAME -n $WEB_APP_NAME --src ./publish.zip
```

### Scaling Resources

```bash
# Scale App Service Plan
az appservice plan update -g $RG_NAME -n $PLAN_NAME --sku S1

# Scale SQL Database
az sql db update -g $RG_NAME -s $SQL_SERVER -n $SQL_DB_NAME \
  --edition Standard --capacity 20
```

### Backup & Recovery

```bash
# Enable backups
az sql db short-term-retention-policy update \
  -g $RG_NAME -s $SQL_SERVER -n $SQL_DB_NAME --retention-days 14

# View backups
az sql db geo-backup-secondary-drop \
  -g $RG_NAME -s $SQL_SERVER -n $SQL_DB_NAME
```

---

## 🗑️ Cleanup

To remove all resources and stop incurring charges:

```bash
# Delete entire resource group
az group delete --name $RG_NAME --yes --no-wait

# Verify deletion
az group exists -n $RG_NAME
```

**Warning:** This will permanently delete all resources in the group!

---

## 📞 Support & Resources

- **Azure Documentation**: https://docs.microsoft.com/azure/
- **Bicep Documentation**: https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/
- **.NET on Azure**: https://docs.microsoft.com/en-us/dotnet/azure/
- **SQL Database**: https://docs.microsoft.com/en-us/azure/azure-sql/

## 📋 Files Checklist

Before deployment, ensure you have:

- [x] `infra/main.bicep` - Infrastructure template
- [x] `infra/main.parameters.json` - Deployment parameters
- [x] `DEPLOYMENT_GUIDE.md` - Step-by-step instructions
- [x] `DEPLOYMENT_CHECKLIST.md` - Verification checklist
- [x] `DATABASE_SCHEMA_DOCUMENTATION.md` - Database docs
- [x] `deploy-azure.sh` - Automated deployment script
- [x] `CareerCloud_Database_Script.sql` - Database schema
- [x] `.env.sample` - Configuration template
- [x] `azure.yaml` - Azure CLI configuration

---

## 📝 Version History

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-25 | 1.0 | Initial release - Complete Azure deployment package |

---

**Happy Deploying! 🚀**

For issues or improvements, refer to DEPLOYMENT_GUIDE.md troubleshooting section or contact your Azure administrator.
