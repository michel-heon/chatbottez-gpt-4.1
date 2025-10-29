#!/bin/bash
# Azure Resource Group Creation Script
# Creates an Azure resource group if it doesn't exist

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_usage() {
    echo "Usage: $0 <environment> [options]"
    echo ""
    echo "Arguments:"
    echo "  environment    Environment name (dev, local, playground, etc.)"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help"
    echo "  --verbose, -v  Enable verbose output"
    echo ""
    echo "Examples:"
    echo "  $0 dev"
    echo "  $0 local --verbose"
    echo ""
    echo "This script creates an Azure resource group based on environment configuration."
}

validate_environment_file() {
    local env_file="$1"
    
    if [ ! -f "$env_file" ]; then
        log_error "Environment file not found: $env_file"
        exit 1
    fi
    
    log_info "Loading environment variables from $env_file"
    
    # Load environment variables
    set -a
    source "$env_file"
    set +a
    
    # Validate required variables
    if [ -z "$AZURE_RESOURCE_GROUP_NAME" ]; then
        log_error "AZURE_RESOURCE_GROUP_NAME not set in $env_file"
        exit 1
    fi
    
    if [ -z "$AZURE_LOCATION" ]; then
        log_error "AZURE_LOCATION not set in $env_file"
        exit 1
    fi
    
    log_info "✓ Required environment variables are set"
    log_info "  Resource Group: $AZURE_RESOURCE_GROUP_NAME"
    log_info "  Location: $AZURE_LOCATION"
}

check_azure_cli() {
    if ! command -v az >/dev/null 2>&1; then
        log_error "Azure CLI is not installed"
        log_info "Install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    log_info "✓ Azure CLI is available: $(az --version | head -1)"
}

check_azure_login() {
    if ! az account show >/dev/null 2>&1; then
        log_warn "Not logged into Azure. Attempting login..."
        az login
    fi
    
    local account_name=$(az account show --query "name" -o tsv 2>/dev/null || echo "Unknown")
    log_info "✓ Logged into Azure account: $account_name"
}

create_resource_group() {
    local rg_name="$1"
    local location="$2"
    
    log_info "Checking if resource group '$rg_name' exists..."
    
    if az group show --name "$rg_name" >/dev/null 2>&1; then
        log_info "✅ Resource group '$rg_name' already exists"
        
        # Show resource group details
        local rg_location=$(az group show --name "$rg_name" --query "location" -o tsv 2>/dev/null || echo "Unknown")
        log_info "   Location: $rg_location"
        
        if [ "$rg_location" != "$location" ]; then
            log_warn "⚠ Resource group location ($rg_location) differs from configured location ($location)"
        fi
    else
        log_info "Creating resource group '$rg_name' in location '$location'..."
        
        if az group create --name "$rg_name" --location "$location" >/dev/null; then
            log_info "✅ Resource group '$rg_name' created successfully"
        else
            log_error "Failed to create resource group '$rg_name'"
            exit 1
        fi
    fi
    
    # Show final resource group information
    log_info "Resource Group Information:"
    az group show --name "$rg_name" --query "{Name:name, Location:location, ProvisioningState:properties.provisioningState}" -o table
}

main() {
    local environment=""
    local verbose=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_usage
                exit 0
                ;;
            --verbose|-v)
                verbose=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                if [ -z "$environment" ]; then
                    environment="$1"
                else
                    log_error "Too many arguments"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Validate required arguments
    if [ -z "$environment" ]; then
        log_error "Environment is required"
        show_usage
        exit 1
    fi
    
    # Enable verbose logging if requested
    if [ "$verbose" = true ]; then
        set -x
    fi
    
    log_info "Azure Resource Group Creation Script"
    log_info "Environment: $environment"
    echo ""
    
    # Validate environment file
    local env_file="env/.env.$environment"
    validate_environment_file "$env_file"
    echo ""
    
    # Check prerequisites
    log_info "Checking prerequisites..."
    check_azure_cli
    check_azure_login
    echo ""
    
    # Create resource group
    log_info "Processing resource group creation..."
    create_resource_group "$AZURE_RESOURCE_GROUP_NAME" "$AZURE_LOCATION"
    echo ""
    
    log_info "✅ Resource group operation completed successfully"
}

# Execute if not sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
