#!/bin/bash

#############################################################################
# CareerCloud - Development Environment Deployment Script
# 
# This script deploys CareerCloud to Azure development environment with:
# - Minimal cost ($13/month)
# - MongoDB Atlas (Free Tier) OR your SQL license
# - B1 App Service (cheapest)
#
# Usage: chmod +x deploy-dev.sh && ./deploy-dev.sh
#
#############################################################################

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Header
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  CareerCloud - Development Environment Deployment       ║"
echo "║  Cost-Optimized ($13/month)                             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Configuration
RG_NAME="rg-careercloud-dev"
LOCATION="East US"
DEPLOY_NAME="CareerCloud-Dev-$(date +%s)"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function: Validate prerequisites
validate_prerequisites() {
    log_info "Validating prerequisites..."
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI not found. Install from: https://aka.ms/InstallAzureCLI"
        exit 1
    fi
    log_success "Azure CLI found"
    
    # Check .NET SDK
    if ! command -v dotnet &> /dev/null; then
        log_error ".NET SDK not found. Install from: https://dotnet.microsoft.com/download"
        exit 1
    fi
    log_success ".NET SDK found"
    
    # Check required files
    if [[ ! -f "infra/lightweight-dev.bicep" ]]; then
        log_error "infra/lightweight-dev.bicep not found!"
        exit 1
    fi
    
    log_success "All prerequisites validated"
}

# Function: Check Azure authentication
check_azure_auth() {
    log_info "Checking Azure authentication..."
    
    if ! az account show &> /dev/null; then
        log_warning "Not authenticated with Azure. Launching login..."
        az login
    fi
    
    CURRENT_USER=$(az account show --query user.name -o tsv)
    SUBSCRIPTION=$(az account show --query id -o tsv)
    
    log_success "Authenticated as: $CURRENT_USER"
    log_info "Subscription: $SUBSCRIPTION"
}

# Function: Create resource group
create_resource_group() {
    log_info "Creating resource group: $RG_NAME..."
    
    az group create \
        --name $RG_NAME \
        --location "$LOCATION" \
        --tags environment=development project=CareerCloud \
        --output none
    
    log_success "Resource group created"
}

# Function: Deploy infrastructure
deploy_infrastructure() {
    log_info "Deploying infrastructure to $LOCATION..."
    echo "  - App Service Plan (B1)"
    echo "  - Web App (.NET 6)"
    echo "  - Application Insights"
    echo "  - No SQL Database (using MongoDB or your license)"
    echo ""
    
    az deployment group create \
        --name $DEPLOY_NAME \
        --resource-group $RG_NAME \
        --template-file infra/lightweight-dev.bicep \
        --parameters infra/lightweight-dev.parameters.json \
        --output none
    
    log_success "Infrastructure deployed successfully"
    
    # Extract outputs
    log_info "Retrieving deployment details..."
    
    OUTPUTS=$(az deployment group show \
        --resource-group $RG_NAME \
        --name $DEPLOY_NAME \
        --query properties.outputs -o json)
    
    WEB_APP_NAME=$(echo $OUTPUTS | jq -r '.webAppName.value')
    WEB_APP_URL=$(echo $OUTPUTS | jq -r '.webAppUrl.value')
    
    log_success "Deployment outputs retrieved"
}

# Function: Build application
build_application() {
    log_info "Building .NET application..."
    
    cd "$SCRIPT_DIR/.."
    
    # Restore packages
    log_info "Restoring NuGet packages for Web API project..."
    PROJECT_PATH="CareerCloud.WebAPI/CareerCloud.WebAPI.csproj"
    dotnet restore "$PROJECT_PATH" --nologo || dotnet restore "$PROJECT_PATH"

    # Build
    log_info "Building Web API project (Release mode)..."
    dotnet build "$PROJECT_PATH" --configuration Release --nologo /p:WarningLevel=0
    
    # Publish
    log_info "Publishing Web API..."
    dotnet publish CareerCloud.WebAPI/CareerCloud.WebAPI.csproj \
        -c Release \
        -o ./publish \
        --nologo --verbosity quiet 2>/dev/null || \
    dotnet publish CareerCloud.WebAPI/CareerCloud.WebAPI.csproj \
        -c Release \
        -o ./publish \
        --nologo
    
    log_success "Application built successfully"
}

# Function: Deploy to App Service
deploy_to_app_service() {
    log_info "Deploying application to App Service: $WEB_APP_NAME..."
    
    # Create zip package
    log_info "Creating deployment package..."
    cd publish
    zip -r -q ../publish.zip . 2>/dev/null || zip -r ../publish.zip .
    cd ..
    
    # Deploy
    log_info "Uploading to App Service..."
    az webapp deployment source config-zip \
        --resource-group $RG_NAME \
        --name $WEB_APP_NAME \
        --src ./publish.zip \
        --output none
    
    log_success "Application deployed"
    log_warning "Waiting for app to start... (30 seconds)"
    sleep 30
}

# Function: Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check deployment status
    STATUS=$(az webapp show \
        --resource-group $RG_NAME \
        --name $WEB_APP_NAME \
        --query state -o tsv)
    
    if [[ "$STATUS" == "Running" ]]; then
        log_success "App Service is running"
    else
        log_warning "App Service status: $STATUS"
    fi
    
    # Test API endpoint
    log_info "Testing API endpoint..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$WEB_APP_URL" 2>/dev/null || echo "000")
    
    if [[ "$HTTP_CODE" == "200" ]] || [[ "$HTTP_CODE" == "301" ]] || [[ "$HTTP_CODE" == "302" ]]; then
        log_success "Web App responding (HTTP $HTTP_CODE)"
    else
        log_warning "Web App returned HTTP $HTTP_CODE (may still be initializing)"
    fi
}

# Function: Display summary
display_summary() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║         Development Deployment Complete! ✅              ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "📊 DEPLOYMENT SUMMARY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Environment:        Development"
    echo "Resource Group:     $RG_NAME"
    echo "Location:           $LOCATION"
    echo "Deployment ID:      $DEPLOY_NAME"
    echo ""
    echo "🌐 DEPLOYED RESOURCES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Web App Name:       $WEB_APP_NAME"
    echo "Web App URL:        $WEB_APP_URL"
    echo "Estimated Cost:     ~\$13/month"
    echo ""
    echo "💰 COST BREAKDOWN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "App Service (B1):   \$10/month"
    echo "App Insights:       \$3/month"
    echo "MongoDB Atlas FREE: \$0/month ✨"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "TOTAL:              ~\$13/month (vs \$18 with SQL DB)"
    echo ""
    echo "🚀 NEXT STEPS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. Test the API:"
    echo "   curl -X GET '$WEB_APP_URL/api/health'"
    echo ""
    echo "2. View application logs:"
    echo "   az webapp log tail -g $RG_NAME -n $WEB_APP_NAME"
    echo ""
    echo "3. Access Azure Portal:"
    echo "   az group show -g $RG_NAME"
    echo ""
    echo "4. Add your MongoDB connection string:"
    echo "   az webapp config appsettings set -g $RG_NAME -n $WEB_APP_NAME \\"
    echo "     --settings MongoDbConnection='your-connection-string'"
    echo ""
    echo "📚 DOCUMENTATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Dev Guide:          DEV_DEPLOYMENT_GUIDE.md"
    echo "Production Setup:   DEPLOYMENT_GUIDE.md (later)"
    echo "Database Design:    DATABASE_SCHEMA_DOCUMENTATION.md"
    echo "Prod Checklist:     DEPLOYMENT_CHECKLIST.md"
    echo ""
    echo "🧹 TO CLEANUP (delete resources and stop charges):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   az group delete --name $RG_NAME --yes --no-wait"
    echo ""
}

# Main execution
main() {
    validate_prerequisites
    check_azure_auth
    create_resource_group
    deploy_infrastructure
    build_application
    deploy_to_app_service
    verify_deployment
    display_summary
}

# Error handling
trap 'log_error "Deployment failed at line $LINENO"; exit 1' ERR

# Run main
main

log_success "Deployment completed successfully!"
log_info "Your CareerCloud development environment is ready 🎉"
