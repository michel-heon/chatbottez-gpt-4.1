#!/bin/bash
# =================================================================
# Database Setup Script for Microsoft Marketplace Quota Management
# =================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}[STEP $1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

echo -e "${CYAN}=================================================================${NC}"
echo -e "${CYAN}Database Setup for Microsoft Marketplace Quota Management${NC}"
echo -e "${CYAN}=================================================================${NC}"

# Check if env/.env.local exists
if [ ! -f "env/.env.local" ]; then
    print_error "env/.env.local file not found. Please run environment setup first."
    exit 1
fi

# Load environment variables
set -a
source env/.env.local
set +a

# Default values
DB_TYPE=${DB_TYPE:-"postgresql"}
DB_HOST=${DB_HOST:-"localhost"}
DB_PORT=${DB_PORT:-"5432"}
DB_NAME=${DB_NAME:-"marketplace_quota"}
DB_USER=${DB_USER:-"marketplace_user"}

print_step "1" "Database Configuration"
echo "Database Type: $DB_TYPE"
echo "Host: $DB_HOST"
echo "Port: $DB_PORT"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo ""

# Function to check PostgreSQL
check_postgresql() {
    print_step "2" "Checking PostgreSQL availability..."
    
    if command -v psql &> /dev/null; then
        print_success "PostgreSQL client found"
    else
        print_error "PostgreSQL client not found. Please install PostgreSQL."
        print_info "Ubuntu/Debian: sudo apt-get install postgresql-client"
        print_info "macOS: brew install postgresql"
        print_info "Windows: Download from https://www.postgresql.org/download/windows/"
        exit 1
    fi
    
    # Test connection
    print_step "3" "Testing database connection..."
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "postgres" -c "\q" 2>/dev/null; then
        print_success "Database connection successful"
    else
        print_error "Cannot connect to database"
        print_info "Please check your credentials in env/.env.local"
        exit 1
    fi
}

# Function to create database
create_database() {
    print_step "4" "Creating database '$DB_NAME'..."
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "postgres" -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
        print_warn "Database '$DB_NAME' already exists"
        read -p "Drop and recreate? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "postgres" -c "DROP DATABASE IF EXISTS $DB_NAME;"
            print_success "Database dropped"
        else
            print_info "Using existing database"
            return 0
        fi
    fi
    
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "postgres" -c "CREATE DATABASE $DB_NAME;"
    print_success "Database '$DB_NAME' created"
}

# Function to apply schema
apply_schema() {
    print_step "5" "Applying database schema..."
    
    if [ ! -f "src/db/schema.sql" ]; then
        print_error "Schema file src/db/schema.sql not found"
        exit 1
    fi
    
    PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "src/db/schema.sql"
    print_success "Schema applied successfully"
}

# Function to verify installation
verify_installation() {
    print_step "6" "Verifying installation..."
    
    # Check tables
    tables=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';")
    
    if [ "$tables" -ge 3 ]; then
        print_success "Tables created successfully ($tables tables found)"
    else
        print_error "Tables not created properly"
        exit 1
    fi
    
    # Check sample data
    sample_count=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM subscriptions;")
    
    if [ "$sample_count" -ge 1 ]; then
        print_success "Sample data inserted ($sample_count records)"
    else
        print_warn "No sample data found"
    fi
}

# Function to update env/.env.local with database URL
update_env() {
    print_step "7" "Updating env/.env.local with DATABASE_URL..."
    
    # Extract password from current DATABASE_URL or use env var
    if [ -n "$DB_PASSWORD" ]; then
        PASSWORD="$DB_PASSWORD"
    else
        print_error "DB_PASSWORD not set in env/.env.local"
        read -s -p "Enter database password: " PASSWORD
        echo ""
    fi
    
    NEW_DATABASE_URL="postgresql://$DB_USER:$PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME"
    
    # Update env/.env.local
    if grep -q "^DATABASE_URL=" env/.env.local; then
        sed -i.bak "s|^DATABASE_URL=.*|DATABASE_URL=$NEW_DATABASE_URL|" env/.env.local
    else
        echo "DATABASE_URL=$NEW_DATABASE_URL" >> env/.env.local
    fi
    
    print_success "DATABASE_URL updated in env/.env.local"
}

# Main execution
case "$DB_TYPE" in
    "postgresql"|"postgres")
        check_postgresql
        create_database
        apply_schema
        verify_installation
        update_env
        ;;
    *)
        print_error "Unsupported database type: $DB_TYPE"
        print_info "Supported types: postgresql"
        exit 1
        ;;
esac

echo ""
print_success "Database setup completed successfully!"
echo ""
print_info "Next steps:"
echo "1. Test the connection: npm run test:db"
echo "2. Start the application: npm run dev"
echo "3. Check the logs for any connection issues"
echo ""
print_info "Database URL configured in env/.env.local"
print_warn "Make sure your database server is running and accessible"
