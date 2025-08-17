# =================================================================
# Script: Setup-Environment.ps1
# Configuration simplifiée de l'environnement de développement
# =================================================================

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Configuration Environnement Microsoft Marketplace Quota" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Step 1: Check prerequisites
Write-Host "[STEP 1] Verification des prerequis..." -ForegroundColor Magenta

# Check Azure CLI
try {
    $azVersion = az --version 2>$null | Select-String "azure-cli"
    Write-Host "[SUCCESS] Azure CLI trouve" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Azure CLI n'est pas installe" -ForegroundColor Red
    exit 1
}

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "[SUCCESS] Node.js $nodeVersion trouve" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Node.js n'est pas installe" -ForegroundColor Red
    exit 1
}

# Step 2: Azure login check
Write-Host "[STEP 2] Verification connexion Azure..." -ForegroundColor Magenta
try {
    $accountInfo = az account show 2>$null | ConvertFrom-Json
    $TENANT_ID = $accountInfo.tenantId
    Write-Host "[SUCCESS] Connecte - Tenant: $TENANT_ID" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Non connecte a Azure CLI" -ForegroundColor Yellow
    az login
    $accountInfo = az account show | ConvertFrom-Json
    $TENANT_ID = $accountInfo.tenantId
}

# Step 3: Create .env.local
Write-Host "[STEP 3] Creation du fichier .env.local..." -ForegroundColor Magenta

if (Test-Path ".env.local") {
    $response = Read-Host "Le fichier .env.local existe. Remplacer? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "[INFO] Conservation du fichier existant" -ForegroundColor Cyan
        exit 0
    }
}

Copy-Item ".env.example" ".env.local"
Write-Host "[SUCCESS] Fichier .env.local cree" -ForegroundColor Green

# Replace TENANT_ID
(Get-Content ".env.local") -replace 'your-azure-tenant-id', $TENANT_ID | Set-Content ".env.local"
Write-Host "[SUCCESS] TENANT_ID configure: $TENANT_ID" -ForegroundColor Green

# Step 4: Generate JWT Secret
Write-Host "[STEP 4] Generation du secret JWT..." -ForegroundColor Magenta
try {
    $bytes = New-Object byte[] 32
    [System.Security.Cryptography.RNGCryptoServiceProvider]::new().GetBytes($bytes)
    $jwtSecret = [BitConverter]::ToString($bytes) -replace '-', ''
    $jwtSecret = $jwtSecret.ToLower()
    
    (Get-Content ".env.local") -replace 'your-jwt-secret-key-64-characters-long', $jwtSecret | Set-Content ".env.local"
    Write-Host "[SUCCESS] JWT_SECRET_KEY genere" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Erreur generation JWT secret" -ForegroundColor Yellow
}

# Step 5: Manual configuration guidance
Write-Host "[STEP 5] Variables a configurer manuellement..." -ForegroundColor Magenta

Write-Host ""
Write-Host "Variables necessitant une configuration manuelle dans .env.local:" -ForegroundColor Yellow
Write-Host ""
Write-Host "DATABASE_URL - Base de donnees PostgreSQL ou SQL Server" -ForegroundColor White
Write-Host "AZURE_STORAGE_CONNECTION_STRING - Compte Azure Storage" -ForegroundColor White
Write-Host "APPLICATION_INSIGHTS_CONNECTION_STRING - Application Insights" -ForegroundColor White
Write-Host "BOT_ID, BOT_PASSWORD - Azure Bot Service" -ForegroundColor White
Write-Host "AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT - Azure OpenAI" -ForegroundColor White
Write-Host ""

# Step 6: Run marketplace script if available
Write-Host "[STEP 6] Configuration Marketplace..." -ForegroundColor Magenta

if (Test-Path "scripts\marketplace-api-key.sh") {
    Write-Host "[INFO] Script marketplace-api-key.sh trouve" -ForegroundColor Cyan
    Write-Host "[INFO] Pour configurer les credentials Marketplace, executez:" -ForegroundColor Cyan
    Write-Host "  .\scripts\marketplace-api-key.sh -C -n 'chatbottez-marketplace' -o marketplace.env" -ForegroundColor White
    Write-Host "  Puis copiez les valeurs dans .env.local" -ForegroundColor White
} else {
    Write-Host "[WARN] Script marketplace-api-key.sh non trouve" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[SUCCESS] Configuration de base terminee!" -ForegroundColor Green
Write-Host ""
Write-Host "Prochaines etapes:" -ForegroundColor Cyan
Write-Host "1. Editer .env.local pour completer les variables manquantes" -ForegroundColor White
Write-Host "2. Executer: npm run dev pour tester" -ForegroundColor White
Write-Host "3. Passer a l'etape 3 du TODO: Base de donnees" -ForegroundColor White
