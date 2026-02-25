# DEV vs PROD Environment Comparison

## Quick Reference

| Feature | Development | Production |
|---------|-------------|------------|
| **Deployment Script** | `deploy-dev.sh` | `deploy-prod.sh` |
| **Infrastructure Template** | `infra/lightweight-dev.bicep` | `infra/main.bicep` |
| **App Service Tier** | B1 (Basic) | S1 (Standard) |
| **Estimated Monthly Cost** | $13 | $40-50 |
| **Database Option 1** | MongoDB Atlas Free | Azure SQL Standard |
| **Database Option 2** | Existing SQL License | Existing SQL License |
| **Auto-Scaling** | None | Yes (2-10 instances) |
| **Availability SLA** | 99.0% | 99.95% |
| **Backup Retention** | 7 days | 7+ days |
| **Monitoring** | Application Insights | Full monitoring, Alerts |
| **Security** | Basic | Enhanced (Firewall, TLS 1.2) |
| **Resource Group Name** | `rg-careercloud-dev` | `rg-careercloud-prod` |
| **Deployment Time** | ~10 minutes | ~15 minutes |

---

## Deployment Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                 Phase 1: Development                        │
├─────────────────────────────────────────────────────────────┤
│ 1. Run: ./deploy-dev.sh                                     │
│ 2. Choose database: MongoDB Free OR SQL License             │
│ 3. Create MongoDB Atlas account (free tier)                 │
│ 4. Get MongoDB connection string                            │
│ 5. Update .env with MongoDB/SQL details                     │
│ 6. Wait for deployment (~10 minutes)                        │
│ 7. Test API endpoints                                       │
│ 8. Verify in Application Insights                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    ✓ Validate & Test
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Phase 2: Production Migration                  │
├─────────────────────────────────────────────────────────────┤
│ 1. Create/Verify production subscription                    │
│ 2. Run: ./deploy-prod.sh                                    │
│ 3. Select production subscription                           │
│ 4. Choose database: Azure SQL Standard OR SQL License       │
│ 5. Auto-configures infrastructure (S1 App Service)          │
│ 6. Auto-imports database schema                             │
│ 7. Builds and deploys application                           │
│ 8. Wait for deployment (~15 minutes)                        │
│ 9. Verify production deployment                             │
│ 10. Set up monitoring & alerts                              │
└─────────────────────────────────────────────────────────────┘
                            ↓
                      ✓ Production Ready
```

---

## Cost Comparison

### Development Environment

**Option A: MongoDB Atlas Free Tier**
```
App Service (B1):           $13/month
MongoDB Atlas (Free):       $0/month
Application Insights:       ~$0.50/month (free tier)
─────────────────────────────────────
Total:                      ~$13.50/month
```

**Option B: Existing SQL License**
```
App Service (B1):           $13/month
SQL Server (License):       $0/month (your license)
Application Insights:       ~$0.50/month (free tier)
─────────────────────────────────────
Total:                      ~$13.50/month
```

### Production Environment

**Option A: Azure SQL Standard**
```
App Service (S1):           $37.05/month
SQL Database (Standard):    $15.71/month
Application Insights:       ~$5/month (typical usage)
Bandwidth (outbound):       ~$0.12/GB
─────────────────────────────────────
Total:                      ~$58-80/month
```

**Option B: Existing SQL License**
```
App Service (S1):           $37.05/month
SQL Server (License):       $0/month (your license)
Application Insights:       ~$5/month (typical usage)
Bandwidth (outbound):       ~$0.12/GB
─────────────────────────────────────
Total:                      ~$42-60/month
```

---

## Environment Variables Comparison

### Development (.env)

```ini
# Development Settings
ASPNETCORE_ENVIRONMENT=Development
LOG_LEVEL=Debug
ENABLE_LOGGING=true

# MongoDB Option
MONGODB_CONNECTION_STRING=mongodb+srv://username:password@cluster.mongodb.net/careercloud?retryWrites=true&w=majority
DATABASE_TYPE=MongoDB

# OR SQL License Option
SQL_CONNECTION_STRING=Server=YOUR_LOCAL_SERVER;Database=CareerCloud;Integrated Security=true;
DATABASE_TYPE=SqlServer
```

### Production (.env.prod)

```ini
# Production Settings
ASPNETCORE_ENVIRONMENT=Production
LOG_LEVEL=Error
ENABLE_LOGGING=true

# Azure SQL Option (Recommended)
SQL_CONNECTION_STRING=Server=tcp:careercloud-prod.database.windows.net,1433;Initial Catalog=careercloud;Persist Security Info=False;User ID=sqladmin;Password=YourSecurePassword@123!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
DATABASE_TYPE=AzureSqlServer

# OR SQL License Option
SQL_CONNECTION_STRING=Server=YOUR_VPN_SERVER;Database=CareerCloud;User ID=sa;Password=YourSecurePassword@123!;Trusted_Connection=false;
DATABASE_TYPE=SqlServer
```

---

## Key Differences Explained

### 1. App Service Tier
- **Dev (B1)**: Shared resources, single instance, ~0.5 GB RAM
- **Prod (S1)**: Dedicated resources, auto-scale capable, 1.75 GB RAM minimum

### 2. Database
- **Dev**: Can use free MongoDB or existing license (minimal cost)
- **Prod**: Should use Azure SQL or managed database (better reliability)

### 3. Monitoring & Security
- **Dev**: Basic Application Insights, minimal alerts
- **Prod**: Full monitoring, custom alerts, security hardening enabled

### 4. Availability
- **Dev**: 99.0% SLA (single instance)
- **Prod**: 99.95% SLA (redundancy, load balancing)

### 5. Backups & Recovery
- **Dev**: 7-day retention (sufficient for testing)
- **Prod**: 7-35 days (compliance, disaster recovery)

---

## Switching from Dev to Prod

### Quick Checklist

1. **Verify Development Works**
   - [ ] API endpoints responding
   - [ ] Database connectivity working
   - [ ] Application Insights showing data
   - [ ] No critical errors in logs

2. **Prepare Production**
   - [ ] Production subscription ready
   - [ ] Budget approved
   - [ ] Security requirements documented
   - [ ] Backup strategy defined

3. **Execute Production Deployment**
   - [ ] Run `./deploy-prod.sh`
   - [ ] Specify production subscription when prompted
   - [ ] Choose database (Azure SQL Standard or SQL License)
   - [ ] Wait for deployment to complete
   - [ ] Verify all components deployed

4. **Validate Production**
   - [ ] Test API endpoints
   - [ ] Verify database connectivity
   - [ ] Check Application Insights
   - [ ] Review security settings
   - [ ] Test user workflows

5. **Configure Monitoring**
   - [ ] Set up alerts for high errors
   - [ ] Set up alerts for high CPU/memory
   - [ ] Configure budget alerts
   - [ ] Set up daily log review

6. **Transition Users**
   - [ ] Update DNS/load balancers
   - [ ] Monitor production closely
   - [ ] Have rollback plan ready
   - [ ] Support team on standby

---

## Rollback Procedure

### If Dev Deployment Fails
```bash
# Delete dev resource group
az group delete --name rg-careercloud-dev --yes --no-wait

# Redeploy
./deploy-dev.sh
```

### If Prod Deployment Fails
```bash
# Keep prod resource group (has data)
# But stop the app service
az webapp stop --resource-group rg-careercloud-prod --name app-careercloud-prod-*

# Investigate logs
az webapp log tail -g rg-careercloud-prod -n app-careercloud-prod-*

# Redeploy once issue is fixed
./deploy-prod.sh

# Or manually restart
az webapp start --resource-group rg-careercloud-prod --name app-careercloud-prod-*
```

---

## Traffic Flow

### Development Architecture
```
Users (Development Team)
        ↓
    [B1 App Service]
        ↓
    [MongoDB Atlas Free]  OR  [SQL Server License]
        ↓
   Application Insights (basic)
```

### Production Architecture
```
Users (Public/Customers)
        ↓
   [Load Balancer]
        ↓
   [S1 App Service] ← Auto-scales 2-10 instances
        ↓
   [Azure SQL Standard] ← Auto-failover replicas
        ↓
   [Application Insights] ← Full monitoring
        ↓
   [Azure Monitor] → [Alert Rules]
```

---

## Common Tasks

### View Development Logs
```bash
az webapp log tail -g rg-careercloud-dev -n app-careercloud-dev-*
```

### View Production Logs
```bash
az webapp log tail -g rg-careercloud-prod -n app-careercloud-prod-* --lines 100
```

### Scale Development to Production
```bash
# When ready to promote app service from B1 to S1
az appservice plan update \
  --name plan-careercloud-dev \
  --resource-group rg-careercloud-dev \
  --sku S1
```

### Download Database Backup
```bash
# Development
az sql db export \
  --resource-group rg-careercloud-dev \
  --server careercloud-dev \
  --name careercloud-dev \
  --admin-user sqladmin \
  --admin-password "YourPassword" \
  --storage-key "StorageKey" \
  --storage-uri "https://yourstorage.blob.core.windows.net/backups/dev.bacpac"

# Production
az sql db export \
  --resource-group rg-careercloud-prod \
  --server careercloud-prod \
  --name careercloud-prod \
  --admin-user sqladmin \
  --admin-password "YourPassword" \
  --storage-key "StorageKey" \
  --storage-uri "https://yourstorage.blob.core.windows.net/backups/prod.bacpac"
```

---

## Support & Troubleshooting

### Development Issues
- Check: `DEV_DEPLOYMENT_GUIDE.md`
- Log file: `deploy-dev-*.log`
- Bicep template: `infra/lightweight-dev.bicep`

### Production Issues
- Check: `PRODUCTION_MIGRATION_GUIDE.md`
- Log file: `deploy-prod-*.log`
- Bicep template: `infra/main.bicep`

### General Issues
- Check: `DEPLOYMENT_GUIDE.md`
- Troubleshooting: `DEPLOYMENT_CHECKLIST.md`

---

## Next Steps

1. **Start with Development** (unless already completed)
   ```bash
   chmod +x deploy-dev.sh
   ./deploy-dev.sh
   ```

2. **Test & Validate**
   - Use DEV_DEPLOYMENT_GUIDE.md
   - Follow DEPLOYMENT_CHECKLIST.md

3. **Plan Production Migration**
   - Review this document (DEV_vs_PROD.md)
   - Review PRODUCTION_MIGRATION_GUIDE.md
   - Prepare production subscription

4. **Deploy to Production**
   ```bash
   chmod +x deploy-prod.sh
   ./deploy-prod.sh
   ```

5. **Monitor & Maintain**
   - Review Application Insights
   - Monitor costs
   - Plan for scaling

---

**Questions?**
- See: `DEPLOYMENT_GUIDE.md` for detailed troubleshooting
- See: `PRODUCTION_MIGRATION_GUIDE.md` for production-specific guidance
- Check logs: `deploy-dev-*.log` or `deploy-prod-*.log`

**Last Updated:** $(date)
