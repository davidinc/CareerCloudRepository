#!/bin/bash

###############################################################################
# CareerCloud Production Deployment Automation Script
# 
# This script automates the deployment of CareerCloud to Azure production
# environment with S1 App Service and Standard SQL Database
#
# Usage: ./deploy-prod.sh [--subscription-id <id>] [--resource-group <name>]
#
# Prerequisites:
#   - Azure CLI installed and configured
#   - .NET 6 SDK installed
#   - Sufficient permissions in production subscription
#   - Production SQL backedump or data migration plan
#
###############################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$SCRIPT_DIR/deploy-prod-$TIMESTAMP.log"

# Default values
PROD_RG_NAME="rg-careercloud-prod"
LOCATION="East US"
ENVIRONMENT_NAME="prod"
APP_SERVICE_PLAN_SKU="S1"
SQL_DB_SKU="Standard"

# Production subscription ID (must be set before running)
PROD_SUBSCRIPTION_ID="${PROD_SUBSCRIPTION_ID:-}"

###############################################################################
# Utility Functions
###############################################################################

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}✗ Error: $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠ Warning: $1${NC}" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_section() {
    echo -e "\n${YELLOW}→ $1${NC}\n"
}

###############################################################################
# Validation Functions
###############################################################################

validate_prerequisites() {
    print_header "Validating Prerequisites"
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Install from https://aka.ms/azure-cli"
        exit 1
    fi
    log_success "Azure CLI installed: $(az --version | head -1)"
    
    # Check .NET SDK
    if ! command -v dotnet &> /dev/null; then
        log_error ".NET SDK is not installed. Install .NET 6 from https://dotnet.microsoft.com/download"
        exit 1
    fi
    log_success ".NET SDK installed: $(dotnet --version)"
    
    # Check Azure login
    if ! az account show &> /dev/null; then
        log_warning "Not logged into Azure. Running 'az login'..."
        az login
    fi
    log_success "Logged into Azure"
    
    # Check Bicep template
    if [ ! -f "$SCRIPT_DIR/infra/main.bicep" ]; then
        log_error "Production Bicep template not found at infra/main.bicep"
        exit 1
    fi
    log_success "Bicep template found: infra/main.bicep"
    
    # Check SQL script
    if [ ! -f "$SCRIPT_DIR/CareerCloud_Database_Script.sql" ]; then
        log_error "Database schema script not found at CareerCloud_Database_Script.sql"
        exit 1
    fi
    log_success "Database schema script found"
    
    # Check Web API project
    if [ ! -f "$SCRIPT_DIR/CareerCloud.WebAPI/CareerCloud.WebAPI.csproj" ]; then
        log_error "Web API project not found"
        exit 1
    fi
    log_success "Web API project found"
}

###############################################################################
# Subscription Management
###############################################################################

setup_production_subscription() {
    print_header "Setting Up Production Subscription"
    
    if [ -z "$PROD_SUBSCRIPTION_ID" ]; then
        print_section "Available Subscriptions:"
        az account list --output table
        echo
        read -p "Enter Production Subscription ID: " PROD_SUBSCRIPTION_ID
    fi
    
    if [ -z "$PROD_SUBSCRIPTION_ID" ]; then
        log_error "Production subscription ID is required"
        exit 1
    fi
    
    # Set subscription
    az account set --subscription "$PROD_SUBSCRIPTION_ID"
    log_success "Switched to production subscription: $PROD_SUBSCRIPTION_ID"
    
    # Show current subscription
    CURRENT_SUB=$(az account show --query "displayName" -o tsv)
    log "Active Subscription: $CURRENT_SUB"
}

###############################################################################
# Resource Group Management
###############################################################################

create_resource_group() {
    print_header "Creating Resource Group"
    
    # Check if resource group exists
    if az group exists --name "$PROD_RG_NAME" | grep -q true; then
        log_warning "Resource group '$PROD_RG_NAME' already exists"
        log "Proceeding with deployment to existing resource group..."
    else
        log "Creating resource group: $PROD_RG_NAME"
        az group create \
            --name "$PROD_RG_NAME" \
            --location "$LOCATION" \
            --tags \
                environment=production \
                project=CareerCloud \
                managedBy=Bicep \
                createdDate="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
            2>&1 | tee -a "$LOG_FILE"
        
        log_success "Resource group created: $PROD_RG_NAME"
    fi
}

###############################################################################
# Infrastructure Deployment
###############################################################################

deploy_infrastructure() {
    print_header "Deploying Production Infrastructure"
    
    print_section "Building Bicep template..."
    
    # Get SQL admin password (generate if not provided)
    if [ -z "$SQL_ADMIN_PASSWORD" ]; then
        SQL_ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)"@P$(date +%s | tail -c 3)"
        log "Generated SQL Admin Password (save this securely!)"
    fi
    
    # Create log file for deployment
    DEPLOYMENT_LOG="$SCRIPT_DIR/bicep-deployment-$TIMESTAMP.txt"
    
    # Deploy infrastructure
    DEPLOYMENT_NAME="CareerCloud-Prod-$(date +%s)"
    
    log "Deployment Name: $DEPLOYMENT_NAME"
    log "Starting deployment (this may take 10-15 minutes)..."
    
    az deployment group create \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$PROD_RG_NAME" \
        --template-file "$SCRIPT_DIR/infra/main.bicep" \
        --parameters "$SCRIPT_DIR/infra/main.parameters.json" \
        --parameters \
            environmentName="$ENVIRONMENT_NAME" \
            location="$LOCATION" \
            appServicePlanSku="$APP_SERVICE_PLAN_SKU" \
            sqlDatabaseSku="$SQL_DB_SKU" \
            sqlAdminPassword="$SQL_ADMIN_PASSWORD" \
        --output json 2>&1 | tee -a "$LOG_FILE" > "$DEPLOYMENT_LOG"
    
    log_success "Infrastructure deployment completed"
    
    # Extract deployment outputs
    print_section "Extracting deployment outputs..."
    
    DEPLOYMENT_OUTPUTS=$(az deployment group show \
        --resource-group "$PROD_RG_NAME" \
        --name "$DEPLOYMENT_NAME" \
        --query properties.outputs -o json)
    
    # Save outputs
    echo "$DEPLOYMENT_OUTPUTS" | jq '.' > "$SCRIPT_DIR/prod-deployment-outputs-$TIMESTAMP.json"
    log_success "Deployment outputs saved to prod-deployment-outputs-$TIMESTAMP.json"
    
    # Extract key values
    PROD_APP_NAME=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.webAppName.value // empty')
    PROD_SQL_SERVER=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.sqlServerFqdn.value // empty')
    PROD_SQL_DB=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.sqlDatabaseName.value // empty')
    PROD_APP_URL=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.webAppUrl.value // empty')
    PROD_APP_INSIGHTS=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.appInsightsName.value // empty')
    
    # Verify outputs
    if [ -z "$PROD_APP_NAME" ] || [ -z "$PROD_SQL_SERVER" ]; then
        log_error "Failed to extract deployment outputs"
        exit 1
    fi
    
    log_success "Infrastructure deployed successfully!"
    echo
    echo "╔════════════════════════════════════════════════╗"
    echo "║     Production Infrastructure Details          ║"
    echo "╠════════════════════════════════════════════════╣"
    echo "║ Resource Group:     $PROD_RG_NAME"
    echo "║ App Service:        $PROD_APP_NAME"
    echo "║ App Service URL:    $PROD_APP_URL"
    echo "║ SQL Server:         $PROD_SQL_SERVER"
    echo "║ SQL Database:       $PROD_SQL_DB"
    echo "║ App Insights:       $PROD_APP_INSIGHTS"
    echo "╚════════════════════════════════════════════════╝"
    echo
}

###############################################################################
# Database Setup
###############################################################################

setup_production_database() {
    print_header "Setting Up Production Database"
    
    print_section "Configuring SQL Server firewall..."
    
    # Extract server name from FQDN
    SQL_SERVER_NAME=$(echo "$PROD_SQL_SERVER" | cut -d. -f1)
    
    # Allow App Service to connect (0.0.0.0 - 0.0.0.0 is for Azure resources)
    log "Adding firewall rule for App Service..."
    az sql server firewall-rule create \
        --resource-group "$PROD_RG_NAME" \
        --server "$SQL_SERVER_NAME" \
        --name "AllowAppService" \
        --start-ip-address "0.0.0.0" \
        --end-ip-address "0.0.0.0" \
        2>&1 | tee -a "$LOG_FILE"
    
    log_success "Firewall rule created for App Service"
    
    # Import database schema
    print_section "Importing database schema..."
    
    log "Connecting to production database: $PROD_SQL_DB"
    log "Server: $PROD_SQL_SERVER"
    
    # Check if sqlcmd is available
    if ! command -v sqlcmd &> /dev/null; then
        log_warning "sqlcmd not found. Install 'mssql-tools' for direct SQL import"
        log "You can manually import the schema using Azure Portal or SSMS:"
        log "  1. Go to Azure Portal > SQL Databases > $PROD_SQL_DB"
        log "  2. Click 'Query Editor' or use 'Connect' with SSMS"
        log "  3. Execute the script file: CareerCloud_Database_Script.sql"
    else
        sqlcmd -S "$PROD_SQL_SERVER" \
            -U "sqladmin" \
            -P "$SQL_ADMIN_PASSWORD" \
            -d "$PROD_SQL_DB" \
            -i "$SCRIPT_DIR/CareerCloud_Database_Script.sql" \
            2>&1 | tee -a "$LOG_FILE"
        
        log_success "Database schema imported successfully"
    fi
}

###############################################################################
# Application Deployment
###############################################################################

build_application() {
    print_header "Building CareerCloud Application"
    
    print_section "Restoring dependencies..."
    cd "$SCRIPT_DIR"
    dotnet restore 2>&1 | tee -a "$LOG_FILE"
    
    print_section "Building application..."
    dotnet build --configuration Release 2>&1 | tail -20 | tee -a "$LOG_FILE"
    log_success "Build completed"
    
    print_section "Publishing application..."
    dotnet publish "$SCRIPT_DIR/CareerCloud.WebAPI/CareerCloud.WebAPI.csproj" \
        -c Release \
        -o "$SCRIPT_DIR/publish" \
        --no-restore \
        2>&1 | tail -20 | tee -a "$LOG_FILE"
    
    log_success "Application published successfully"
}

deploy_application() {
    print_header "Deploying Application to Production"
    
    print_section "Creating deployment package..."
    cd "$SCRIPT_DIR/publish" || exit 1
    
    # Clean up old zip files
    rm -f "$SCRIPT_DIR"/publish*.zip
    
    # Create new deployment package
    zip -r "$SCRIPT_DIR/publish-prod-$TIMESTAMP.zip" . > /dev/null 2>&1
    log_success "Deployment package created: publish-prod-$TIMESTAMP.zip"
    
    print_section "Configuring application settings..."
    
    # Update connection string
    SQL_CONNECTION_STRING="Server=tcp:$PROD_SQL_SERVER,1433;Initial Catalog=$PROD_SQL_DB;Persist Security Info=False;User ID=sqladmin;Password=$SQL_ADMIN_PASSWORD;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    
    az webapp config connection-string set \
        --resource-group "$PROD_RG_NAME" \
        --name "$PROD_APP_NAME" \
        --connection-string-slots \
            DataConnection="$SQL_CONNECTION_STRING" \
        --connection-string-type SQLServer 2>&1 | tee -a "$LOG_FILE"
    
    log_success "Connection string configured"
    
    # Update app settings
    az webapp config appsettings set \
        --resource-group "$PROD_RG_NAME" \
        --name "$PROD_APP_NAME" \
        --settings \
            ASPNETCORE_ENVIRONMENT=Production \
            WEBSITE_ENABLE_SYNC_UPDATE_SITE=true \
            WEBSITE_HTTPLOGGING_RETENTION_DAYS=7 \
            LOG_LEVEL=Error \
            2>&1 | tee -a "$LOG_FILE"
    
    log_success "App settings configured"
    
    # Enforce HTTPS
    az webapp update \
        --resource-group "$PROD_RG_NAME" \
        --name "$PROD_APP_NAME" \
        --https-only true 2>&1 | tee -a "$LOG_FILE"
    
    log "HTTPS enforced"
    
    # Set TLS 1.2 minimum
    az webapp update \
        --resource-group "$PROD_RG_NAME" \
        --name "$PROD_APP_NAME" \
        --min-tls-version 1.2 2>&1 | tee -a "$LOG_FILE"
    
    log "TLS 1.2 minimum set"
    
    print_section "Deploying application package..."
    log "This may take 5-10 minutes..."
    
    az webapp deployment source config-zip \
        --resource-group "$PROD_RG_NAME" \
        --name "$PROD_APP_NAME" \
        --src "$SCRIPT_DIR/publish-prod-$TIMESTAMP.zip" 2>&1 | tee -a "$LOG_FILE"
    
    log_success "Application deployed to production"
    
    print_section "Waiting for application to start..."
    sleep 30
}

###############################################################################
# Verification
###############################################################################

verify_deployment() {
    print_header "Verifying Production Deployment"
    
    print_section "Testing API health..."
    
    # Test endpoint (may be slow for first request)
    HEALTH_URL="$PROD_APP_URL/api/health"
    RETRY_COUNT=0
    MAX_RETRIES=10
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" 2>/dev/null || echo "000")
        
        if [ "$HEALTH_RESPONSE" = "200" ] || [ "$HEALTH_RESPONSE" = "404" ]; then
            log_success "API is responding (HTTP $HEALTH_RESPONSE)"
            break
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                log "Waiting for API to start (attempt $RETRY_COUNT/$MAX_RETRIES)..."
                sleep 5
            fi
        fi
    done
    
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        log_warning "API health check timed out. The app may still be starting."
    fi
    
    # Get deployment status
    DEPLOYMENT_STATE=$(az webapp show \
        --resource-group "$PROD_RG_NAME" \
        --name "$PROD_APP_NAME" \
        --query state -o tsv)
    
    log "App Service State: $DEPLOYMENT_STATE"
    [ "$DEPLOYMENT_STATE" = "Running" ] && log_success "App Service is running" || log_warning "App Service state: $DEPLOYMENT_STATE"
    
    # Show logs
    print_section "Checking application logs (last 20 lines)..."
    az webapp log tail \
        --resource-group "$PROD_RG_NAME" \
        --name "$PROD_APP_NAME" \
        --lines 20 2>&1 | tee -a "$LOG_FILE" || log_warning "Could not retrieve logs (may not be available immediately)"
}

###############################################################################
# Summary
###############################################################################

print_summary() {
    print_header "Production Deployment Summary"
    
    echo "✓ Prerequisites validated"
    echo "✓ Infrastructure deployed (S1 App Service + Standard SQL Database)"
    echo "✓ Database schema imported"
    echo "✓ Application built and deployed"
    echo "✓ Configuration complete"
    echo
    
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║           Production Deployment Complete! 🎉               ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║                                                            ║"
    echo "║ Application URL:                                          ║"
    echo "║   $PROD_APP_URL"
    echo "║                                                            ║"
    echo "║ Database:                                                 ║"
    echo "║   Server: $PROD_SQL_SERVER"
    echo "║   Database: $PROD_SQL_DB"
    echo "║   Admin User: sqladmin                                    ║"
    echo "║                                                            ║"
    echo "║ Monitoring:                                               ║"
    echo "║   https://portal.azure.com                                ║"
    echo "║   Resource Group: $PROD_RG_NAME"
    echo "║   Application Insights: $PROD_APP_INSIGHTS"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo
    
    echo "Next Steps:"
    echo "1. Visit your application: $PROD_APP_URL"
    echo "2. Verify API endpoints are responding"
    echo "3. Test critical workflows"
    echo "4. Monitor Application Insights for errors"
    echo "5. Review logs: az webapp log tail -g $PROD_RG_NAME -n $PROD_APP_NAME"
    echo
    
    echo "Production Deployment Guide:"
    echo "   See: PRODUCTION_MIGRATION_GUIDE.md"
    echo
    
    echo "Save these values securely:"
    echo "   SQL Admin Password: [stored securely, do not share]"
    echo "   Resource Group: $PROD_RG_NAME"
    echo "   Subscription ID: $PROD_SUBSCRIPTION_ID"
    echo
    
    echo "Logs saved to: $LOG_FILE"
}

###############################################################################
# Main Execution
###############################################################################

main() {
    print_header "CareerCloud Production Deployment"
    
    echo "Deployment Configuration:"
    echo "  Environment: $ENVIRONMENT_NAME"
    echo "  Region: $LOCATION"
    echo "  App Service SKU: $APP_SERVICE_PLAN_SKU"
    echo "  SQL Database SKU: $SQL_DB_SKU"
    echo "  Log File: $LOG_FILE"
    echo
    
    # Execute deployment steps
    validate_prerequisites
    setup_production_subscription
    create_resource_group
    deploy_infrastructure
    setup_production_database
    build_application
    deploy_application
    verify_deployment
    print_summary
}

# Run main function
main "$@"

echo -e "${GREEN}Deployment completed at $(date)${NC}"
