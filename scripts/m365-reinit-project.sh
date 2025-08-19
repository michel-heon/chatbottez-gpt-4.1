#!/bin/bash
# Script pour réinitialiser le projet comme un projet Microsoft 365 Agents Toolkit valide
# Ce script va diagnostiquer et réparer la configuration selon la documentation officielle

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

PROJECT_ID="9dfd58b3-4e85-4feb-97cb-0c7fc518b00b"

show_usage() {
    echo "Usage: $0 [--diagnose] [--fix] [--backup]"
    echo ""
    echo "Options:"
    echo "  --diagnose - Run diagnostic only (default)"
    echo "  --fix      - Attempt to fix project configuration"
    echo "  --backup   - Create backup before fixing"
    echo "  --help     - Show this help"
    echo ""
    echo "This script diagnoses and fixes Microsoft 365 Agents Toolkit project issues."
}

run_atk_doctor() {
    log_info "Running atk doctor to check prerequisites..."
    if atk doctor; then
        log_info "✅ All prerequisites are met"
        return 0
    else
        log_warn "⚠ Some prerequisites are missing or need attention"
        return 1
    fi
}

check_project_structure() {
    log_info "Checking Microsoft 365 Agents Toolkit project structure..."
    
    local issues=0
    
    # Check for required files according to atk documentation
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

test_atk_commands() {
    log_info "Testing Microsoft 365 Agents Toolkit CLI commands..."
    
    # Test basic atk commands that should work in a valid project
    if atk list templates >/dev/null 2>&1; then
        log_info "✓ atk list templates works"
    else
        log_warn "⚠ atk list templates failed"
    fi
    
    # Try to get project info (this should work if project is valid)
    if atk env list >/dev/null 2>&1; then
        log_info "✅ Project recognized by Microsoft 365 Agents Toolkit CLI"
        return 0
    else
        log_error "❌ Project not recognized by Microsoft 365 Agents Toolkit CLI"
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

fix_project_configuration() {
    log_info "Attempting to fix project configuration..."
    
    # Run atk upgrade to ensure project is up to date
    log_info "Running atk upgrade..."
    if atk upgrade --force; then
        log_info "✓ Project upgraded successfully"
    else
        log_warn "⚠ Project upgrade had issues, continuing..."
    fi
    
    # Test again after upgrade
    if test_atk_commands; then
        log_info "✅ Project now recognized after upgrade"
        return 0
    else
        log_error "❌ Project still not recognized after upgrade"
        return 1
    fi
}

show_diagnosis() {
    log_info "=== Microsoft 365 Agents Toolkit Project Diagnosis ==="
    echo ""
    
    # Run atk doctor first
    run_atk_doctor
    echo ""
    
    check_project_structure
    local structure_issues=$?
    
    echo ""
    test_atk_commands
    local atk_issues=$?
    
    echo ""
    log_info "=== Summary ==="
    if [ $structure_issues -eq 0 ] && [ $atk_issues -eq 0 ]; then
        log_info "✅ Project configuration appears to be correct"
        log_info "You can now run: make provision ENV=dev"
    else
        log_warn "⚠ Found $((structure_issues + atk_issues)) potential issue(s)"
        echo ""
        log_info "Suggested fixes:"
        echo "  1. Run with --fix to attempt automatic repair"
        echo "  2. Check Microsoft 365 Agents Toolkit extension version in VS Code"
        echo "  3. Restart VS Code"
        echo "  4. Run: atk upgrade --force"
        echo "  5. Clear cache: rm -rf ~/.fx ~/.teamsfx ~/.atk"
    fi
}

main() {
    local do_fix=false
    local do_backup=false
    local do_diagnose=true
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix)
                do_fix=true
                do_diagnose=false
                shift
                ;;
            --backup)
                do_backup=true
                shift
                ;;
            --diagnose)
                do_diagnose=true
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
    
    log_info "Microsoft 365 Agents Toolkit Project Repair Script"
    echo ""
    
    # Check if atk is installed
    if ! command -v atk >/dev/null 2>&1; then
        log_error "Microsoft 365 Agents Toolkit CLI (atk) is not installed"
        log_info "Install with: npm install -g @microsoft/m365agentstoolkit-cli"
        exit 1
    fi
    
    if [ "$do_fix" = true ]; then
        if [ "$do_backup" = true ]; then
            create_backup
            echo ""
        fi
        
        log_info "Attempting to fix project configuration..."
        echo ""
        
        fix_project_configuration
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
