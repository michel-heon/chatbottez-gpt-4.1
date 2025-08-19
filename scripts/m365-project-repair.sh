#!/bin/bash
# Microsoft 365 Agents Project Repair Script
# Fix Teams Toolkit project recognition issues

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
    echo "Usage: $0 [--fix] [--backup]"
    echo ""
    echo "Options:"
    echo "  --fix      - Attempt to fix project configuration"
    echo "  --backup   - Create backup before fixing"
    echo "  --help     - Show this help"
    echo ""
    echo "This script diagnoses and fixes Teams Toolkit project recognition issues."
}

check_project_structure() {
    log_info "Checking Teams Toolkit project structure..."
    
    local issues=0
    
    # Check for required files
    if [ ! -f "m365agents.yml" ]; then
        log_error "Missing m365agents.yml"
        issues=$((issues + 1))
    else
        log_info "✓ m365agents.yml exists"
    fi
    
    if [ ! -f "package.json" ]; then
        log_error "Missing package.json"
        issues=$((issues + 1))
    else
        log_info "✓ package.json exists"
    fi
    
    if [ ! -d "appPackage" ]; then
        log_error "Missing appPackage directory"
        issues=$((issues + 1))
    else
        log_info "✓ appPackage directory exists"
    fi
    
    if [ ! -f "appPackage/manifest.json" ]; then
        log_error "Missing appPackage/manifest.json"
        issues=$((issues + 1))
    else
        log_info "✓ appPackage/manifest.json exists"
    fi
    
    # Check for project ID in m365agents.yml
    if [ -f "m365agents.yml" ]; then
        if grep -q "projectId:" "m365agents.yml"; then
            local project_id=$(grep "projectId:" "m365agents.yml" | cut -d: -f2 | tr -d ' ')
            if [ -n "$project_id" ] && [ "$project_id" != "null" ]; then
                log_info "✓ Project ID found: $project_id"
            else
                log_warn "⚠ Project ID is empty or null"
                issues=$((issues + 1))
            fi
        else
            log_warn "⚠ Project ID not found in m365agents.yml"
            issues=$((issues + 1))
        fi
    fi
    
    # Check environment directory
    if [ ! -d "env" ]; then
        log_error "Missing env directory"
        issues=$((issues + 1))
    else
        log_info "✓ env directory exists"
        
        # Check for at least one environment file
        env_files=$(find env -name ".env.*" | wc -l)
        if [ "$env_files" -eq 0 ]; then
            log_error "No environment files found in env/"
            issues=$((issues + 1))
        else
            log_info "✓ Found $env_files environment file(s)"
        fi
    fi
    
    return $issues
}

check_teamsfx_config() {
    log_info "Checking TeamsFx configuration..."
    
    # Check for .fx directory (old Teams Toolkit)
    if [ -d ".fx" ]; then
        log_warn "⚠ Old .fx directory found (Teams Toolkit v4 or earlier)"
        return 1
    fi
    
    # Check for newer config files
    if [ -f ".localConfigs" ] || [ -f ".localConfigs.playground" ]; then
        log_info "✓ Local config files found"
        return 0
    else
        log_warn "⚠ No local config files found"
        return 1
    fi
}

create_backup() {
    local backup_dir="backup-$(date +%Y%m%d-%H%M%S)"
    log_info "Creating backup in $backup_dir..."
    
    mkdir -p "$backup_dir"
    
    # Backup key files
    [ -f "m365agents.yml" ] && cp "m365agents.yml" "$backup_dir/"
    [ -f "package.json" ] && cp "package.json" "$backup_dir/"
    [ -d "appPackage" ] && cp -r "appPackage" "$backup_dir/"
    [ -d "env" ] && cp -r "env" "$backup_dir/"
    [ -f ".localConfigs" ] && cp ".localConfigs" "$backup_dir/"
    [ -f ".localConfigs.playground" ] && cp ".localConfigs.playground" "$backup_dir/"
    
    log_info "✓ Backup created in $backup_dir"
}

fix_project_id() {
    log_info "Fixing project ID in m365agents.yml..."
    
    if [ ! -f "m365agents.yml" ]; then
        log_error "m365agents.yml not found"
        return 1
    fi
    
    # Generate a new project ID if missing or null
    if ! grep -q "projectId:" "m365agents.yml" || grep -q "projectId: null" "m365agents.yml" || grep -q "projectId:$" "m365agents.yml"; then
        local new_project_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
        
        if grep -q "projectId:" "m365agents.yml"; then
            # Replace existing line
            sed -i "s/projectId:.*/projectId: $new_project_id/" "m365agents.yml"
        else
            # Add projectId at the end
            echo "projectId: $new_project_id" >> "m365agents.yml"
        fi
        
        log_info "✓ Project ID set to: $new_project_id"
    else
        log_info "✓ Project ID already exists"
    fi
}

initialize_teamsfx() {
    log_info "Initializing TeamsFx configuration..."
    
    # Try to run teamsapp info to initialize the project
    if teamsapp info >/dev/null 2>&1; then
        log_info "✓ Project recognized by Teams Toolkit"
        return 0
    else
        log_warn "⚠ Project still not recognized by Teams Toolkit"
        
        # Try to force initialization
        log_info "Attempting to force initialize..."
        
        # Create minimal .localConfigs if missing
        if [ ! -f ".localConfigs" ]; then
            cat > .localConfigs << EOF
{
  "projectId": "$(grep 'projectId:' m365agents.yml | cut -d: -f2 | tr -d ' ' || echo '')"
}
EOF
            log_info "✓ Created .localConfigs"
        fi
        
        # Test again
        if teamsapp info >/dev/null 2>&1; then
            log_info "✓ Project now recognized by Teams Toolkit"
            return 0
        else
            log_error "✗ Project still not recognized. Manual intervention may be required."
            return 1
        fi
    fi
}

show_diagnosis() {
    log_info "=== Teams Toolkit Project Diagnosis ==="
    echo ""
    
    check_project_structure
    local structure_issues=$?
    
    echo ""
    check_teamsfx_config
    local config_issues=$?
    
    echo ""
    log_info "=== Summary ==="
    if [ $structure_issues -eq 0 ] && [ $config_issues -eq 0 ]; then
        log_info "✅ Project structure appears to be correct"
    else
        log_warn "⚠ Found $((structure_issues + config_issues)) potential issue(s)"
        echo ""
        log_info "Suggested fixes:"
        echo "  1. Run with --fix to attempt automatic repair"
        echo "  2. Check Teams Toolkit extension version"
        echo "  3. Restart VS Code"
        echo "  4. Clear Teams Toolkit cache: rm -rf ~/.fx ~/.teamsfx"
    fi
}

main() {
    local do_fix=false
    local do_backup=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix)
                do_fix=true
                shift
                ;;
            --backup)
                do_backup=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    log_info "Microsoft 365 Agents Project Repair Script"
    echo ""
    
    if [ "$do_fix" = true ]; then
        if [ "$do_backup" = true ]; then
            create_backup
            echo ""
        fi
        
        log_info "Attempting to fix project configuration..."
        echo ""
        
        fix_project_id
        echo ""
        
        initialize_teamsfx
        echo ""
        
        log_info "✅ Repair attempt completed"
        echo ""
        log_info "Try running: make provision ENV=dev"
    else
        show_diagnosis
        echo ""
        log_info "To attempt automatic repair, run: $0 --fix --backup"
    fi
}

# Execute if not sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
