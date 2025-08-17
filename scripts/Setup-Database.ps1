# =================================================================
# Database Setup Script for Microsoft Marketplace Quota Management
# PowerShell Version for Windows
# =================================================================

param(
    [string]$DatabaseType = "postgresql",
    [string]$DatabaseHost = "localhost",
    [int]$Port = 5432,
    [string]$DatabaseName = "marketplace_quota",
    [string]$Username = "marketplace_user",
    [switch]$Force
)

# Colors for console output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Step($step, $message) {
    Write-ColorOutput Blue "[STEP $step] $message"
}

function Write-Success($message) {
    Write-ColorOutput Green "[SUCCESS] $message"
}

function Write-Warning($message) {
    Write-ColorOutput Yellow "[WARN] $message"
}

function Write-Error($message) {
    Write-ColorOutput Red "[ERROR] $message"
}

function Write-Info($message) {
    Write-ColorOutput Cyan "[INFO] $message"
}

Clear-Host
Write-ColorOutput Cyan "================================================================="
Write-ColorOutput Cyan "Database Setup for Microsoft Marketplace Quota Management"
Write-ColorOutput Cyan "================================================================="

# Check if .env.local exists
if (-not (Test-Path ".env.local")) {
    Write-Error ".env.local file not found. Please run environment setup first."
    exit 1
}

# Load environment variables from .env.local
Write-Step "1" "Loading environment variables..."
Get-Content ".env.local" | ForEach-Object {
    if ($_ -match "^([^#][^=]+)=(.*)$") {
        $name = $matches[1]
        $value = $matches[2]
        Set-Variable -Name $name -Value $value -Scope Global
    }
}

# Override with parameters if provided
if ($DatabaseHost -ne "localhost") { $DB_HOST = $DatabaseHost }
if ($Port -ne 5432) { $DB_PORT = $Port }
if ($DatabaseName -ne "marketplace_quota") { $DB_NAME = $DatabaseName }
if ($Username -ne "marketplace_user") { $DB_USER = $Username }

# Use environment variables or defaults
$DB_TYPE = if ($global:DB_TYPE) { $global:DB_TYPE } else { $DatabaseType }
$DB_HOST = if ($global:DB_HOST) { $global:DB_HOST } else { "localhost" }
$DB_PORT = if ($global:DB_PORT) { $global:DB_PORT } else { 5432 }
$DB_NAME = if ($global:DB_NAME) { $global:DB_NAME } else { "marketplace_quota" }
$DB_USER = if ($global:DB_USER) { $global:DB_USER } else { "marketplace_user" }
$DB_PASSWORD = $global:DB_PASSWORD

Write-Success "Environment variables loaded"
Write-Host ""
Write-Host "Database Configuration:"
Write-Host "Type: $DB_TYPE"
Write-Host "Host: $DB_HOST"
Write-Host "Port: $DB_PORT"
Write-Host "Database: $DB_NAME"
Write-Host "User: $DB_USER"
Write-Host ""

# Function to check PostgreSQL
function Test-PostgreSQL {
    Write-Step "2" "Checking PostgreSQL availability..."
    
    try {
        $psqlVersion = psql --version 2>$null
        if ($psqlVersion) {
            Write-Success "PostgreSQL client found: $($psqlVersion.Split(' ')[2])"
        } else {
            throw "PostgreSQL not found"
        }
    } catch {
        Write-Error "PostgreSQL client not found. Please install PostgreSQL."
        Write-Info "Download from: https://www.postgresql.org/download/windows/"
        Write-Info "Or use chocolatey: choco install postgresql"
        exit 1
    }
    
    # Test connection
    Write-Step "3" "Testing database connection..."
    $env:PGPASSWORD = $DB_PASSWORD
    try {
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "postgres" -c "\q" 2>$null | Out-Null
        Write-Success "Database connection successful"
    } catch {
        Write-Error "Cannot connect to database"
        Write-Info "Please check your credentials in .env.local"
        Write-Info "Make sure PostgreSQL server is running"
        exit 1
    }
}

# Function to create database
function New-Database {
    Write-Step "4" "Creating database '$DB_NAME'..."
    
    $env:PGPASSWORD = $DB_PASSWORD
    
    # Check if database exists
    $dbExists = psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "postgres" -t -c "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';" 2>$null
    
    if ($dbExists -match "1") {
        Write-Warning "Database '$DB_NAME' already exists"
        if ($Force) {
            $recreate = "y"
        } else {
            $recreate = Read-Host "Drop and recreate? (y/N)"
        }
        
        if ($recreate -match "^[Yy]$") {
            psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "postgres" -c "DROP DATABASE IF EXISTS `"$DB_NAME`";" | Out-Null
            Write-Success "Database dropped"
        } else {
            Write-Info "Using existing database"
            return
        }
    }
    
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "postgres" -c "CREATE DATABASE `"$DB_NAME`";" | Out-Null
    Write-Success "Database '$DB_NAME' created"
}

# Function to apply schema
function Set-DatabaseSchema {
    Write-Step "5" "Applying database schema..."
    
    if (-not (Test-Path "src\db\schema.sql")) {
        Write-Error "Schema file src\db\schema.sql not found"
        exit 1
    }
    
    $env:PGPASSWORD = $DB_PASSWORD
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "src\db\schema.sql" | Out-Null
    Write-Success "Schema applied successfully"
}

# Function to verify installation
function Test-DatabaseInstallation {
    Write-Step "6" "Verifying installation..."
    
    $env:PGPASSWORD = $DB_PASSWORD
    
    # Check tables
    $tableCount = psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';" 2>$null
    $tableCount = $tableCount.Trim()
    
    if ([int]$tableCount -ge 3) {
        Write-Success "Tables created successfully ($tableCount tables found)"
    } else {
        Write-Error "Tables not created properly"
        exit 1
    }
    
    # Check sample data
    $sampleCount = psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM subscriptions;" 2>$null
    $sampleCount = $sampleCount.Trim()
    
    if ([int]$sampleCount -ge 1) {
        Write-Success "Sample data inserted ($sampleCount records)"
    } else {
        Write-Warning "No sample data found"
    }
}

# Function to update .env.local
function Update-EnvironmentFile {
    Write-Step "7" "Updating .env.local with DATABASE_URL..."
    
    if (-not $DB_PASSWORD) {
        Write-Error "DB_PASSWORD not set in .env.local"
        $securePassword = Read-Host "Enter database password" -AsSecureString
        $DB_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    }
    
    $newDatabaseUrl = "postgresql://$DB_USER`:$DB_PASSWORD@$DB_HOST`:$DB_PORT/$DB_NAME"
    
    # Update .env.local
    $envContent = Get-Content ".env.local"
    $updated = $false
    
    for ($i = 0; $i -lt $envContent.Length; $i++) {
        if ($envContent[$i] -match "^DATABASE_URL=") {
            $envContent[$i] = "DATABASE_URL=$newDatabaseUrl"
            $updated = $true
            break
        }
    }
    
    if (-not $updated) {
        $envContent += "DATABASE_URL=$newDatabaseUrl"
    }
    
    $envContent | Set-Content ".env.local"
    Write-Success "DATABASE_URL updated in .env.local"
}

# Main execution
try {
    switch ($DB_TYPE.ToLower()) {
        { $_ -in @("postgresql", "postgres") } {
            Test-PostgreSQL
            New-Database
            Set-DatabaseSchema
            Test-DatabaseInstallation
            Update-EnvironmentFile
        }
        default {
            Write-Error "Unsupported database type: $DB_TYPE"
            Write-Info "Supported types: postgresql"
            exit 1
        }
    }
    
    Write-Host ""
    Write-Success "Database setup completed successfully!"
    Write-Host ""
    Write-Info "Next steps:"
    Write-Host "1. Test the connection: npm run test:db"
    Write-Host "2. Start the application: npm run dev"
    Write-Host "3. Check the logs for any connection issues"
    Write-Host ""
    Write-Info "Database URL configured in .env.local"
    Write-Warning "Make sure your database server is running and accessible"
    
} catch {
    Write-Error "Database setup failed: $($_.Exception.Message)"
    exit 1
}
