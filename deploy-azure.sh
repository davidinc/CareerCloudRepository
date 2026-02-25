#!/bin/bash

################################################################################
# CareerCloud Automated Azure Deployment Script
# 
# Usage:
#   ./deploy-azure.sh                        # Interactive mode
#   ./deploy-azure.sh dev                    # Deploy to dev environment
#   ./deploy-azure.sh prod YourPassword@123  # Deploy prod with password
#
# Features:
# - Validates Azure CLI and .NET SDK
# - Creates resource group
# - Deploys infrastructure via Bicep
# - Builds and publishes .NET application
# - Deploys to Azure App Service
# - Imports SQL database schema
# - Performs health checks
################################################################################

set -e  # Exit on any error
set -o pipefail  # Exit on pipe failures

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Configuration
ENVIRONMENT=${1:-dev}
SQL_PASSWORD=${2:-ChangeMe@12345}
LOCATION="East US"
RG_NAME="rg-careercloud-${ENVIRONMENT}"
DEPLOY_NAME="CareerCloud-Deployment-$(date +%s)"

# Validation
validate_prerequisites() {
    log_info "Validating prerequisites..."
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI not installed. Visit: https://aka.ms/InstallAzureCLI"
        exit 1
    fi
    log_success "Azure CLI found: $(az --version | head -1)"
    
    # Check .NET SDK
    if ! command -v dotnet &> /dev/null; then
        log_error ".NET SDK not installed. Visit: https://dotnet.microsoft.com/download"
        exit 1
    fi
    log_success ".NET SDK found: $(dotnet --version)"
    
    # Check required files
    if [[ ! -f "infra/main.bicep" ]]; then
        log_error "infra/main.bicep not found!"
        exit 1
    fi
    
    if [[ ! -f "CareerCloud.WebAPI/CareerCloud.WebAPI.csproj" ]]; then
        log_error "CareerCloud.WebAPI project not found!"
        exit 1
    fi
    
    if [[ ! -f "CareerCloud_Database_Script.sql" ]]; then
        log_error "CareerCloud_Database_Script.sql not found!"
        exit 1
    fi
    
    log_success "All prerequisites validated"
}

# Azure authentication
authenticate_azure() {
    log_info "Checking Azure authentication..."
    
    if ! az account show &> /dev/null; then
        log_warning "Not authenticated with Azure. Starting login..."
        az login
    fi
    
    CURRENT_ACCOUNT=$(az account show --query user.name -o tsv)
    SUBSCRIPTION=$(az account show --query id -o tsv)
    
    log_success "Authenticated as: $CURRENT_ACCOUNT"
    log_info "Using subscription: $SUBSCRIPTION"
}

# Create resource group
create_resource_group() {
    log_info "Creating resource group: $RG_NAME..."
    
    az group create \
        --name $RG_NAME \
        --location "$LOCATION" \
        --tags environment=$ENVIRONMENT project=CareerCloud \
        --output none
    
    log_success "Resource group created/updated"
}

# Validate Bicep template
validate_template() {
    log_info "Validating Bicep template..."
    
    az deployment group validate \
        --resource-group $RG_NAME \
        --template-file infra/main.bicep \
        --parameters infra/main.parameters.json \
        --parameters \
            environmentName=$ENVIRONMENT \
            sqlAdminPassword=$SQL_PASSWORD \
        --output none
    
    log_success "Bicep template validation passed"
}

# Deploy infrastructure
deploy_infrastructure() {
    log_info "Deploying infrastructure (this may take 5-10 minutes)..."
    
    az deployment group create \
        --name $DEPLOY_NAME \
        --resource-group $RG_NAME \
        --template-file infra/main.bicep \
        --parameters infra/main.parameters.json \
        --parameters \
            environmentName=$ENVIRONMENT \
            location="$LOCATION" \
            sqlAdminPassword=$SQL_PASSWORD \
        --output none
    
    log_success "Infrastructure deployment completed"
    
    # Extract deployment outputs
    log_info "Extracting deployment outputs..."
    
    OUTPUTS=$(az deployment group show \
        --resource-group $RG_NAME \
        --name $DEPLOY_NAME \
        --query properties.outputs -o json)
    
    WEB_APP_NAME=$(echo $OUTPUTS | jq -r '.webAppName.value // empty')
    SQL_FQDN=$(echo $OUTPUTS | jq -r '.sqlServerFqdn.value // empty')
    SQL_DB_NAME=$(echo $OUTPUTS | jq -r '.sqlDatabaseName.value // empty')
    WEB_APP_URL=$(echo $OUTPUTS | jq -r '.webAppUrl.value // empty')
    APP_INSIGHTS=$(echo $OUTPUTS | jq -r '.appInsightsInstrumentationKey.value // empty')
    
    log_success "Deployment outputs extracted"
}

# Build .NET application
build_application() {
    log_info "Building .NET application..."
    
    cd "$SCRIPT_DIR"
    
    # Restore packages
    log_info "Restoring NuGet packages..."
    dotnet restore --nologo
    
    # Build
    log_info "Building solution in Release mode..."
    dotnet build --configuration Release --nologo
    
    # Publish
    log_info "Publishing CareerCloud.WebAPI..."
    dotnet publish CareerCloud.WebAPI/CareerCloud.WebAPI.csproj \
        -c Release \
        -o ./publish \
        --nologo
    
    log_success "Application built successfully"
}

# Deploy to App Service
deploy_to_app_service() {
    log_info "Deploying to App Service: $WEB_APP_NAME..."
    
    # Create zip package
    log_info "Creating deployment package..."
    cd publish
    zip -r -q ../publish.zip .
    cd ..
    
    # Deploy
    log_info "Uploading to App Service..."
    az webapp deployment source config-zip \
        --resource-group $RG_NAME \
        --name $WEB_APP_NAME \
        --src ./publish.zip \
        --output none
    
    log_success "Application deployed to App Service"
    
    # Wait for deployment
    log_info "Waiting for deployment to stabilize..."
    sleep 20
}

# Import database schema
import_database_schema() {
    log_info "Importing database schema..."
    
    # Check if sqlcmd is available
    if ! command -v sqlcmd &> /dev/null; then
        log_warning "sqlcmd not found. Skipping automatic schema import."
        log_warning "Run manually:"
        log_warning "sqlcmd -S $SQL_FQDN -U sqladmin -P *** -d $SQL_DB_NAME -i CareerCloud_Database_Script.sql"
        return
    fi
    
    # Check firewall access
    log_info "Note: SQL Server requires your IP in the firewall."
    log_info "If connection fails, manually add your IP to the SQL Server firewall rules."
    
    # Attempt import
    if timeout 30 sqlcmd -S "$SQL_FQDN" \
        -U sqladmin \
        -P "$SQL_PASSWORD" \
        -d "$SQL_DB_NAME" \
        -i CareerCloud_Database_Script.sql \
        -t 30 &> /dev/null; then
        
        log_success "Database schema imported successfully"
    else
        log_warning "Could not automatically import database schema."
        log_warning "This is typically due to firewall restrictions."
        log_warning "Please run manually when ready:"
        echo ""
        echo "sqlcmd -S $SQL_FQDN \"
        echo "  -U sqladmin \"
        echo "  -P \$SQL_PASSWORD \"
        echo "  -d $SQL_DB_NAME \"
        echo "  -i CareerCloud_Database_Script.sql"
        echo ""
    fi
}

# Health checks
health_check() {
    log_info "Performing health checks..."
    
    if [[ -z "$WEB_APP_URL" ]]; then
        log_warning "Could not determine Web App URL"
        return
    fi
    
    log_info "Testing Web App URL: $WEB_APP_URL"
    
    # Wait a moment for app to be ready
    sleep 10
    
    # Test connectivity
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$WEB_APP_URL" 2>/dev/null || echo "000")
    
    if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "301" ]] || [[ "$HTTP_CODE" == "302" ]]; then
        log_success "Web App is responding (HTTP $HTTP_CODE)"
    else
        log_warning "Web App returned HTTP $HTTP_CODE. App may still be warming up."
    fi
}

# Display summary
display_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║         CareerCloud Deployment Complete!              ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    echo "Deployment Summary:"
    echo "  Environment: $ENVIRONMENT"
    echo "  Resource Group: $RG_NAME"
    echo "  Region: $LOCATION"
    echo "  Deployment ID: $DEPLOY_NAME"
    echo ""
    echo "Deployed Resources:"
    echo "  Web App: $WEB_APP_NAME"
    echo "  Web App URL: $WEB_APP_URL"
    echo "  SQL Server: $SQL_FQDN"
    echo "  SQL Database: $SQL_DB_NAME"
    echo "  SQL Admin: sqladmin"
    echo ""
    echo "Next Steps:"
    echo "  1. Test API: curl -X GET '$WEB_APP_URL/api/health'"
    echo "  2. View logs: az webapp log tail -g $RG_NAME -n $WEB_APP_NAME"
    echo "  3. SQL Import: sqlcmd -S $SQL_FQDN -U sqladmin -P *** -d $SQL_DB_NAME -i CareerCloud_Database_Script.sql"
    echo "  4. Monitor: https://portal.azure.com/#@/resource/subscriptions/$SUBSCRIPTION/resourceGroups/$RG_NAME"
    echo ""
    echo "To cleanup resources:"
    echo "  az group delete --name $RG_NAME --yes --no-wait"
    echo ""
}

# Main execution
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║    CareerCloud Azure Deployment Script                ║"
    echo "║    Environment: $ENVIRONMENT"
    echo "║    Location: $LOCATION"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    
    validate_prerequisites
    authenticate_azure
    create_resource_group
    validate_template
    deploy_infrastructure
    build_application
    deploy_to_app_service
    import_database_schema
    health_check
    display_summary
}

# Error handling
trap 'log_error "Deployment failed at line $LINENO"; exit 1' ERR

# Run main
main

log_success "All steps completed successfully!"
