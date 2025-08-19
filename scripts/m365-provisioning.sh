#!/bin/bash
# Microsoft 365 Agents Provisioning Script
# Created from Microsoft 365 Agents Toolkit

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
ENV=${1:-dev}
FORCE_MODE=${2:-false}
CLEAN_MODE=${3:-false}

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    echo "Usage: $0 [ENVIRONMENT] [FORCE] [CLEAN]"
    echo ""
    echo "Parameters:"
    echo "  ENVIRONMENT  - Target environment (dev|local|playground) [default: dev]"
    echo "  FORCE        - Force mode: true to reinstall Bicep [default: false]"
    echo "  CLEAN        - Clean mode: true to clear all caches [default: false]"
    echo ""
    echo "Examples:"
    echo "  $0                    # Provision dev environment"
    echo "  $0 dev                # Provision dev environment"
    echo "  $0 dev true           # Force provision dev with Bicep reinstall"
    echo "  $0 dev false true     # Provision dev with cache cleanup"
    echo "  $0 playground true true # Force clean provision playground"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Node.js
    if ! command -v node >/dev/null 2>&1; then
        log_error "Node.js is not installed"
        exit 1
    fi
    
    # Check npm
    if ! command -v npm >/dev/null 2>&1; then
        log_error "npm is not installed"
        exit 1
    fi
    
    # Check Microsoft 365 Agents Toolkit CLI (atk)
    if ! command -v atk >/dev/null 2>&1; then
        log_error "Microsoft 365 Agents Toolkit CLI (atk) is not installed. Run 'npm install -g @microsoft/m365agentstoolkit-cli'"
        exit 1
    else
        log_info "✓ Microsoft 365 Agents Toolkit CLI is installed: $(atk --version)"
    fi
    
    # Check Bicep CLI
    if command -v bicep >/dev/null 2>&1; then
        log_info "✓ Bicep CLI is installed: $(bicep --version)"
    else
        log_warn "⚠ Bicep CLI not installed"
        return 1
    fi
    
    # Check Azure CLI (optional)
    if command -v az >/dev/null 2>&1; then
        log_info "✓ Azure CLI is installed: $(az --version | head -1)"
    else
        log_warn "⚠ Azure CLI not installed (optional)"
    fi
    
    log_info "✓ Core prerequisites are installed"
    return 0
}

install_bicep() {
    log_info "Installing Azure Bicep CLI..."
    
    if command -v az >/dev/null 2>&1; then
        log_info "Installing Bicep via Azure CLI..."
        az bicep install
    else
        log_info "Installing Bicep directly..."
        local os_type=$(uname)
        
        if [ "$os_type" = "Linux" ]; then
            curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
            chmod +x ./bicep
            sudo mv ./bicep /usr/local/bin/bicep
        elif [ "$os_type" = "Darwin" ]; then
            curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-osx-x64
            chmod +x ./bicep
            sudo mv ./bicep /usr/local/bin/bicep
        else
            log_error "Unsupported platform. Please install Bicep manually."
            exit 1
        fi
    fi
    
    log_info "✓ Bicep CLI installed successfully!"
}

check_environment_file() {
    local env_file="env/.env.${ENV}"
    
    if [ ! -f "$env_file" ]; then
        log_error "Environment file $env_file not found!"
        log_warn "Available environments:"
        ls -1 env/.env.* 2>/dev/null | sed 's/env\/.env\.//g' | sort || echo "No environment files found"
        exit 1
    fi
    
    log_info "✓ Environment file exists: $env_file"
    
    # Check Azure Subscription
    if grep -q "AZURE_SUBSCRIPTION_ID=" "$env_file" && ! grep -q "AZURE_SUBSCRIPTION_ID=$" "$env_file"; then
        log_info "✓ Azure Subscription configured"
    else
        log_error "Azure Subscription not configured in $env_file"
        exit 1
    fi
    
    # Check Resource Group
    if grep -q "AZURE_RESOURCE_GROUP_NAME=" "$env_file" && ! grep -q "AZURE_RESOURCE_GROUP_NAME=$" "$env_file"; then
        log_info "✓ Resource Group configured"
    else
        log_error "Resource Group not configured in $env_file"
        exit 1
    fi
    
    log_info "✓ Environment configuration is valid"
}

show_environment_info() {
    local env_file="env/.env.${ENV}"
    log_info "Environment variables for: $ENV"
    echo ""
    echo -e "${YELLOW}Key Variables:${NC}"
    grep -E "AZURE_|TEAMS_APP_ID|BOT_" "$env_file" | head -10
    echo ""
}

clean_caches() {
    log_info "Clearing TeamsFx and Bicep cache..."
    
    # Remove TeamsFx caches
    rm -rf ~/.fx 2>/dev/null || true
    rm -rf ~/.teamsfx 2>/dev/null || true
    
    # Remove temporary Bicep files
    rm -rf /tmp/bicep* 2>/dev/null || true
    
    log_info "✓ Caches cleared"
}

force_bicep_reinstall() {
    log_info "Force reinstalling Bicep CLI..."
    
    # Remove old Bicep installations
    rm -rf ~/.fx/bin/bicep* 2>/dev/null || true
    rm -rf ~/.teamsfx/bin/bicep* 2>/dev/null || true
    sudo rm -f /usr/local/bin/bicep 2>/dev/null || true
    
    # Reinstall Bicep
    install_bicep
    
    log_info "✓ Bicep force reinstall completed"
}

debug_setup() {
    log_info "Debugging Provisioning Setup:"
    echo ""
    
    echo -e "${YELLOW}1. Checking Tools:${NC}"
    if command -v atk >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Microsoft 365 Agents Toolkit CLI: $(atk --version)"
    else
        echo -e "${RED}✗${NC} TeamsFx CLI not installed"
    fi
    
    if command -v bicep >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Bicep CLI: $(bicep --version)"
    else
        echo -e "${RED}✗${NC} Bicep CLI not installed"
    fi
    
    if command -v az >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Azure CLI: $(az --version | head -1)"
    else
        echo -e "${RED}✗${NC} Azure CLI not installed"
    fi
    
    echo ""
    echo -e "${YELLOW}2. Environment Status:${NC}"
    show_environment_info
    
    echo -e "${YELLOW}3. Cache Directories:${NC}"
    if [ -d "$HOME/.fx" ]; then
        echo -e "${YELLOW}~${NC} TeamsFx cache exists: ~/.fx"
    else
        echo -e "${GREEN}✓${NC} No TeamsFx cache"
    fi
    
    if [ -d "$HOME/.teamsfx" ]; then
        echo -e "${YELLOW}~${NC} TeamsFx cache exists: ~/.teamsfx"
    else
        echo -e "${GREEN}✓${NC} No TeamsFx cache"
    fi
}

run_provision() {
    log_info "Starting provisioning for environment: $ENV"
    
    # Set environment variables
    export TEAMSFX_ENV="$ENV"
    
    # Run the actual provisioning
    log_info "Executing atk provision --env $ENV"
    atk provision --env "$ENV"
    
    log_info "✓ Provisioning completed for environment: $ENV!"
}

main() {
    # Show usage if help requested
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi
    
    log_info "Microsoft 365 Agents Provisioning Script"
    log_info "Environment: $ENV"
    log_info "Force mode: $FORCE_MODE"
    log_info "Clean mode: $CLEAN_MODE"
    echo ""
    
    # Validate environment parameter
    if [[ ! "$ENV" =~ ^(dev|local|playground)$ ]]; then
        log_error "Invalid environment: $ENV. Must be dev, local, or playground"
        show_usage
        exit 1
    fi
    
    # Step 1: Check prerequisites
    if ! check_prerequisites; then
        if [ "$FORCE_MODE" = "true" ]; then
            log_warn "Installing missing Bicep CLI..."
            install_bicep
        else
            log_error "Prerequisites check failed. Use force mode to auto-install Bicep."
            exit 1
        fi
    fi
    
    # Step 2: Check environment file
    check_environment_file
    
    # Step 3: Handle clean mode
    if [ "$CLEAN_MODE" = "true" ]; then
        clean_caches
    fi
    
    # Step 4: Handle force mode
    if [ "$FORCE_MODE" = "true" ]; then
        force_bicep_reinstall
    fi
    
    # Step 5: Check Bicep installation
    if ! command -v bicep >/dev/null 2>&1; then
        log_warn "Bicep not found. Installing..."
        install_bicep
    fi
    
    # Step 6: Show debug info if verbose
    if [ "$VERBOSE" = "true" ]; then
        debug_setup
        echo ""
    fi
    
    # Step 7: Run provisioning
    run_provision
    
    log_info "✅ Provisioning script completed successfully!"
    echo ""
    log_info "Next steps:"
    log_info "1. Run deployment: make deploy ENV=$ENV"
    log_info "2. Or run full lifecycle: make full-lifecycle ENV=$ENV"
}

# Check if script is being sourced or executed
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
