#!/bin/bash
# =================================================================
# Hybrid Azure Database Deployment - Bash + PowerShell pour Bicep
# =================================================================

set -e

# Charger la configuration
source scripts/config-loader.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[STEP $1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo -e "${CYAN}=================================================================${NC}"
echo -e "${CYAN}Azure Database Deployment - Hybride Bash/PowerShell${NC}"
echo -e "${CYAN}=================================================================${NC}"

# Charger la configuration
if ! load_azure_config; then
    exit 1
fi

print_info "Configuration:"
echo "  Groupe de ressources: $RESOURCE_GROUP_NAME"
echo "  Localisation: $AZURE_LOCATION"
echo "  Environnement: $ENVIRONMENT"
echo ""

# Vérifier la connexion Azure
print_step "1" "Vérification de la connexion Azure..."
if ! az account show &> /dev/null; then
    print_error "Non connecté à Azure"
    exit 1
fi

account_name=$(az account show --query name -o tsv)
print_success "Connecté à: $account_name"

# Vérifier le groupe de ressources
print_step "2" "Vérification du groupe de ressources..."
if az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
    print_success "Groupe de ressources trouvé: $RESOURCE_GROUP_NAME"
else
    print_error "Groupe de ressources non trouvé: $RESOURCE_GROUP_NAME"
    exit 1
fi

# Déployer via PowerShell (Bicep fonctionne mieux sur Windows)
print_step "3" "Déploiement via PowerShell (pour Bicep)..."
print_info "Passage à PowerShell pour le déploiement Bicep..."

# Créer un script PowerShell temporaire
cat > temp_deploy.ps1 << 'EOF'
# Charger la configuration
$ConfigPath = "config/azure.env"
$Config = @{}

Get-Content $ConfigPath | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*?)\s*=\s*(.*?)\s*$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim('"', "'")
        $Config[$key] = $value
    }
}

# Variables dérivées
$ResourceGroupName = "rg-$($Config.PROJECT_NAME)-$($Config.ENVIRONMENT)-$($Config.REGION_SUFFIX)"
$Location = $Config.AZURE_LOCATION
$Environment = $Config.ENVIRONMENT

Write-Host "Déploiement Bicep avec:" -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "  Location: $Location" -ForegroundColor Yellow
Write-Host "  Environment: $Environment" -ForegroundColor Yellow

# Validation du template
Write-Host "Validation du template Bicep..." -ForegroundColor Blue
try {
    az deployment group validate `
        --resource-group $ResourceGroupName `
        --template-file "infra/database/postgres.bicep" `
        --parameters "@infra/database/postgres.parameters.json" `
        --parameters location="$Location" environment="$Environment" `
        --output none
    
    Write-Host "✅ Validation réussie" -ForegroundColor Green
} catch {
    Write-Host "❌ Échec de validation: $_" -ForegroundColor Red
    exit 1
}

# Déploiement
Write-Host "Déploiement de l'infrastructure..." -ForegroundColor Blue
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$deploymentName = "postgres-deploy-$timestamp"

try {
    $deploymentResult = az deployment group create `
        --resource-group $ResourceGroupName `
        --template-file "infra/database/postgres.bicep" `
        --parameters "@infra/database/postgres.parameters.json" `
        --parameters location="$Location" environment="$Environment" `
        --name $deploymentName `
        --output json | ConvertFrom-Json
    
    if ($deploymentResult.properties.provisioningState -eq "Succeeded") {
        Write-Host "✅ Déploiement réussi!" -ForegroundColor Green
        
        # Sauvegarder les outputs
        $outputs = $deploymentResult.properties.outputs
        $outputFile = "deployment-outputs.json"
        $outputs | ConvertTo-Json -Depth 10 | Out-File $outputFile
        Write-Host "Outputs sauvegardés dans: $outputFile" -ForegroundColor Yellow
        
        # Afficher les résultats
        Write-Host "Détails du déploiement:" -ForegroundColor Cyan
        Write-Host "  Serveur: $($outputs.serverName.value)" -ForegroundColor Yellow
        Write-Host "  FQDN: $($outputs.serverFQDN.value)" -ForegroundColor Yellow
        Write-Host "  Base de données: $($outputs.databaseName.value)" -ForegroundColor Yellow
        Write-Host "  Key Vault: $($outputs.keyVaultName.value)" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Échec du déploiement: $($deploymentResult.properties.provisioningState)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Erreur de déploiement: $_" -ForegroundColor Red
    exit 1
}
EOF

# Exécuter le script PowerShell
powershell.exe -ExecutionPolicy Bypass -File temp_deploy.ps1

# Vérifier le résultat
if [ $? -eq 0 ]; then
    print_step "4" "Post-traitement en Bash..."
    
    # Lire les outputs si disponibles
    if [ -f "deployment-outputs.json" ]; then
        print_success "Déploiement terminé avec succès!"
        
        # Extraire les informations du JSON
        if command -v jq &> /dev/null; then
            SERVER_FQDN=$(jq -r '.serverFQDN.value // empty' deployment-outputs.json)
            KEY_VAULT_NAME=$(jq -r '.keyVaultName.value // empty' deployment-outputs.json)
            
            if [ -n "$SERVER_FQDN" ] && [ -n "$KEY_VAULT_NAME" ]; then
                print_info "Tentative de récupération des chaînes de connexion..."
                
                # Test de connexion au Key Vault
                if az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "postgres-app-connection-string" --query value -o tsv &> /dev/null; then
                    conn_str=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "postgres-app-connection-string" --query value -o tsv)
                    
                    # Mettre à jour .env.local
                    echo "" >> .env.local
                    echo "# Azure Database Connection (Auto-generated)" >> .env.local
                    echo "DATABASE_URL=$conn_str" >> .env.local
                    echo "AZURE_DATABASE_SERVER=$SERVER_FQDN" >> .env.local
                    echo "AZURE_KEY_VAULT_NAME=$KEY_VAULT_NAME" >> .env.local
                    echo "AZURE_RESOURCE_GROUP=$RESOURCE_GROUP_NAME" >> .env.local
                    
                    print_success ".env.local mis à jour"
                else
                    print_info "Chaînes de connexion non accessibles (permissions Key Vault requises)"
                fi
            fi
        fi
        
        echo ""
        echo -e "${GREEN}=================================================================${NC}"
        echo -e "${GREEN}✅ Déploiement hybride terminé avec succès!${NC}"
        echo -e "${GREEN}=================================================================${NC}"
        echo ""
        echo -e "${YELLOW}Nouveau groupe de ressources:${NC} $RESOURCE_GROUP_NAME"
        echo -e "${YELLOW}Localisation:${NC} $AZURE_LOCATION"
        echo ""
        echo -e "${CYAN}Prochaines étapes:${NC}"
        echo "1. Configurer les permissions Key Vault"
        echo "2. Tester la connexion à la base de données"
        echo "3. Démarrer l'application"
    fi
else
    print_error "Échec du déploiement PowerShell"
    exit 1
fi

# Nettoyer
rm -f temp_deploy.ps1
