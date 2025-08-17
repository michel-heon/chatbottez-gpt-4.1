# =================================================================
# Script: Configure-Environment.ps1
# Objet: Configuration automatique de l'environnement de développement (Windows)
# Usage: .\scripts\Configure-Environment.ps1
# =================================================================

param(
    [switch]$Force = $false,
    [string]$AppName = "chatbottez-marketplace-$(Get-Date -Format 'yyyyMMddHHmm')"
)

# Colors for output
$Colors = @{
    Info = 'Cyan'
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Step = 'Magenta'
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color = 'White')
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Write-Info { param([string]$Message) Write-ColorOutput "[INFO] $Message" 'Info' }
function Write-Success { param([string]$Message) Write-ColorOutput "[SUCCESS] $Message" 'Success' }
function Write-Warning { param([string]$Message) Write-ColorOutput "[WARN] $Message" 'Warning' }
function Write-Error { param([string]$Message) Write-ColorOutput "[ERROR] $Message" 'Error' }
function Write-Step { param([string]$Message) Write-ColorOutput "[STEP] $Message" 'Step' }

Write-ColorOutput "=================================================================" 'Cyan'
Write-ColorOutput "🔧 Configuration Environnement Microsoft Marketplace Quota" 'Cyan'
Write-ColorOutput "=================================================================" 'Cyan'

# Check prerequisites
Write-Step "1. Vérification des prérequis..."

# Check Azure CLI
try {
    $azVersion = az --version | Select-String "azure-cli" | ForEach-Object { $_.ToString().Split()[1] }
    Write-Success "Azure CLI $azVersion trouvé"
} catch {
    Write-Error "Azure CLI n'est pas installé ou accessible."
    Write-Error "Installer depuis: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
}

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Success "Node.js $nodeVersion trouvé"
} catch {
    Write-Error "Node.js n'est pas installé ou accessible."
    exit 1
}

# Check Azure login
Write-Step "2. Vérification connexion Azure..."
try {
    $account = az account show --query '{tenantId:tenantId, subscriptionId:id, userEmail:user.name}' | ConvertFrom-Json
    Write-Success "Connecté en tant que: $($account.userEmail)"
    Write-Success "Tenant ID: $($account.tenantId)"
    Write-Success "Subscription ID: $($account.subscriptionId)"
    
    $TENANT_ID = $account.tenantId
} catch {
    Write-Warning "Non connecté à Azure CLI. Connexion requise..."
    az login
    $account = az account show --query '{tenantId:tenantId, subscriptionId:id, userEmail:user.name}' | ConvertFrom-Json
    $TENANT_ID = $account.tenantId
}

# Step 3: Create .env.local from template
Write-Step "3. Configuration du fichier .env.local..."

$envLocalExists = Test-Path ".env.local"
$createEnv = $true

if ($envLocalExists -and -not $Force) {
    Write-Warning "Le fichier .env.local existe déjà."
    $response = Read-Host "Voulez-vous le remplacer? (y/N)"
    if ($response -notmatch '^[Yy]$') {
        Write-Info "Conservation du fichier existant."
        $createEnv = $false
    }
}

if ($createEnv) {
    Copy-Item ".env.example" ".env.local" -Force
    Write-Success "Fichier .env.local créé depuis .env.example"
    
    # Replace basic values
    (Get-Content ".env.local") -replace 'your-azure-tenant-id', $TENANT_ID | Set-Content ".env.local"
    Write-Success "TENANT_ID configuré: $TENANT_ID"
}

# Step 4: Generate JWT Secret
Write-Step "4. Génération du secret JWT..."

try {
    # Generate JWT secret using .NET crypto (equivalent to openssl rand -hex 32)
    $bytes = New-Object byte[] 32
    ([System.Security.Cryptography.RNGCryptoServiceProvider]::new()).GetBytes($bytes)
    $jwtSecret = [System.Convert]::ToHexString($bytes).ToLower()
    
    (Get-Content ".env.local") -replace 'your-jwt-secret-key-64-characters-long', $jwtSecret | Set-Content ".env.local"
    Write-Success "JWT_SECRET_KEY généré et configuré"
} catch {
    Write-Warning "Erreur lors de la génération du JWT secret"
    Write-Warning "Veuillez générer manuellement JWT_SECRET_KEY dans .env.local"
}

# Step 5: Run marketplace-api-key.sh if available
Write-Step "5. Configuration des credentials Microsoft Marketplace..."

if (Test-Path "scripts\marketplace-api-key.sh") {
    Write-Info "Script marketplace-api-key.sh trouvé. Configuration automatique..."
    
    Write-Info "Création de l'application Azure AD: $AppName"
    Write-Info "Cela va créer une application avec les permissions nécessaires..."
    
    # Run marketplace-api-key.sh using WSL or Git Bash
    try {
        if (Get-Command wsl -ErrorAction SilentlyContinue) {
            Write-Info "Utilisation de WSL pour exécuter le script bash..."
            wsl bash -c "cd /mnt/c$(($PWD.Path -replace ':', '').Replace('\', '/')) && ./scripts/marketplace-api-key.sh -C -n '$AppName' -o marketplace-temp.env -v 3"
        } elseif (Get-Command bash -ErrorAction SilentlyContinue) {
            Write-Info "Utilisation de Git Bash pour exécuter le script..."
            bash -c "./scripts/marketplace-api-key.sh -C -n '$AppName' -o marketplace-temp.env -v 3"
        } else {
            throw "Ni WSL ni Git Bash trouvés"
        }
        
        Write-Success "Credentials Marketplace générés avec succès"
        
        # Extract values from marketplace-temp.env and update .env.local
        if (Test-Path "marketplace-temp.env") {
            $envContent = Get-Content "marketplace-temp.env"
            $envVars = @{}
            
            foreach ($line in $envContent) {
                if ($line -match '^([^#\s][^=]+)=(.*)$') {
                    $envVars[$matches[1]] = $matches[2]
                }
            }
            
            # Update .env.local with marketplace values
            if ($envVars.CLIENT_ID) {
                (Get-Content ".env.local") -replace 'your-client-app-id', $envVars.CLIENT_ID | Set-Content ".env.local"
            }
            if ($envVars.CLIENT_SECRET) {
                (Get-Content ".env.local") -replace 'your-client-secret', $envVars.CLIENT_SECRET | Set-Content ".env.local"
            }
            if ($envVars.MARKETPLACE_API_TOKEN) {
                (Get-Content ".env.local") -replace 'your-oauth2-token', $envVars.MARKETPLACE_API_TOKEN | Set-Content ".env.local"
            }
            if ($envVars.MARKETPLACE_TOKEN_EXPIRES_ON) {
                (Get-Content ".env.local") -replace '2025-08-18T12:00:00Z', $envVars.MARKETPLACE_TOKEN_EXPIRES_ON | Set-Content ".env.local"
            }
            
            Write-Success "Credentials Marketplace intégrés dans .env.local"
            
            # Clean up temporary file
            Remove-Item "marketplace-temp.env" -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Warning "Échec de génération des credentials Marketplace: $($_.Exception.Message)"
        Write-Warning "Veuillez les configurer manuellement dans .env.local"
    }
} else {
    Write-Warning "Script marketplace-api-key.sh non trouvé"
    Write-Warning "Veuillez configurer manuellement MARKETPLACE_API_KEY dans .env.local"
}

# Step 6: Configuration guidance
Write-Step "6. Configuration manuelle requise..."

Write-Warning @"

Les variables suivantes nécessitent une configuration manuelle dans .env.local:

📊 BASE DE DONNÉES:
   DATABASE_URL=postgresql://username:password@localhost:5432/marketplace_quota
   
   Instructions:
   1. Installer PostgreSQL ou SQL Server
   2. Créer la base de données 'marketplace_quota'
   3. Mettre à jour la chaîne de connexion

☁️ AZURE STORAGE (pour retry des événements):
   AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=https;...
   
   Instructions:
   1. Créer un compte Azure Storage
   2. Obtenir la chaîne de connexion
   3. Mettre à jour la variable

📊 APPLICATION INSIGHTS:
   APPLICATION_INSIGHTS_CONNECTION_STRING=InstrumentationKey=...
   
   Instructions:
   1. Créer une ressource Application Insights
   2. Obtenir la chaîne de connexion
   3. Mettre à jour la variable

🤖 BOT FRAMEWORK:
   BOT_ID, BOT_PASSWORD, BOT_TENANT_ID
   
   Instructions:
   1. Configurer Azure Bot Service
   2. Obtenir les credentials du bot
   3. Mettre à jour les variables

🧠 AZURE OPENAI:
   AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT, AZURE_OPENAI_DEPLOYMENT_NAME
   
   Instructions:
   1. Configurer Azure OpenAI Service
   2. Déployer GPT-4
   3. Mettre à jour les variables

"@

# Step 7: Next steps
Write-Step "7. Prochaines étapes..."

Write-Success @"

Configuration de base terminee!

Prochaines actions:
   1. Editer .env.local pour completer les variables manquantes
   2. Executer: npm run dev pour tester l'application
   3. Verifier les logs pour identifier les problemes de configuration
   4. Passer a l'etape 3 du TODO: Configuration de la base de donnees

Fichiers crees/modifies:
   - .env.local (configuration principale)
   - Application Azure AD: $AppName (credentials Marketplace)

Documentation:
   - README_QUOTA.md pour plus de details
   - TODO.md pour les prochaines etapes

"@

Write-Success "Configuration terminee! Verifiez .env.local et completez les variables manquantes."
