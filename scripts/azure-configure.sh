#!/bin/bash
# =================================================================
# Configuration Post-Déploiement Azure - Bash
# =================================================================

set -e

source scripts/config-loader.sh

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
echo -e "${CYAN}Configuration Post-Déploiement Azure${NC}"
echo -e "${CYAN}=================================================================${NC}"

# Charger la configuration
if ! load_azure_config; then
    exit 1
fi

# Lire les outputs du déploiement
if [ ! -f "deployment-outputs.json" ]; then
    print_error "Fichier deployment-outputs.json non trouvé"
    print_info "Exécutez d'abord le déploiement"
    exit 1
fi

# Extraire les informations avec PowerShell (pour gérer le JSON complexe)
KEY_VAULT_NAME=$(powershell.exe -Command "(Get-Content deployment-outputs.json | ConvertFrom-Json).keyVaultName.value")
SERVER_NAME=$(powershell.exe -Command "(Get-Content deployment-outputs.json | ConvertFrom-Json).serverName.value")
SERVER_FQDN=$(powershell.exe -Command "(Get-Content deployment-outputs.json | ConvertFrom-Json).serverFQDN.value")
DATABASE_NAME=$(powershell.exe -Command "(Get-Content deployment-outputs.json | ConvertFrom-Json).databaseName.value")

# Nettoyer les retours chariot Windows
KEY_VAULT_NAME=$(echo "$KEY_VAULT_NAME" | tr -d '\r')
SERVER_NAME=$(echo "$SERVER_NAME" | tr -d '\r')
SERVER_FQDN=$(echo "$SERVER_FQDN" | tr -d '\r')
DATABASE_NAME=$(echo "$DATABASE_NAME" | tr -d '\r')

print_info "Ressources déployées:"
echo "  Key Vault: $KEY_VAULT_NAME"
echo "  Serveur: $SERVER_NAME"
echo "  FQDN: $SERVER_FQDN"
echo "  Base de données: $DATABASE_NAME"
echo ""

print_step "1" "Configuration des permissions Key Vault..."

# Obtenir l'ID utilisateur actuel
USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
print_info "User Object ID: $USER_OBJECT_ID"

# Configurer les permissions Key Vault
print_info "Attribution des permissions Key Vault..."
az keyvault set-policy \
    --name "$KEY_VAULT_NAME" \
    --object-id "$USER_OBJECT_ID" \
    --secret-permissions get list set delete \
    --output none

print_success "Permissions Key Vault configurées"

print_step "2" "Récupération des chaînes de connexion..."

# Attendre un peu pour que les permissions se propagent
sleep 5

# Récupérer les chaînes de connexion
if APP_CONN_STR=$(az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "postgres-app-connection-string" --query value -o tsv 2>/dev/null); then
    print_success "Chaîne de connexion app récupérée"
    
    print_step "3" "Mise à jour de .env.local..."
    
    # Créer ou mettre à jour .env.local
    if [ -f ".env.local" ]; then
        cp ".env.local" ".env.local.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backup créé: .env.local.backup.*"
    fi
    
    # Supprimer les anciennes entrées Azure s'il y en a
    if [ -f ".env.local" ]; then
        grep -v "^DATABASE_URL=" .env.local > .env.local.tmp || true
        grep -v "^AZURE_" .env.local.tmp > .env.local || true
        rm -f .env.local.tmp
    fi
    
    # Ajouter les nouvelles configurations
    cat >> .env.local << EOF

# Azure Database Configuration (Auto-generated $(date))
DATABASE_URL=$APP_CONN_STR
AZURE_DATABASE_SERVER=$SERVER_FQDN
AZURE_DATABASE_NAME=$DATABASE_NAME
AZURE_KEY_VAULT_NAME=$KEY_VAULT_NAME
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP_NAME
AZURE_LOCATION=$AZURE_LOCATION
EOF
    
    print_success ".env.local mis à jour avec la configuration Azure"
    
    print_step "4" "Test de connexion à la base de données..."
    
    # Test simple avec psql si disponible
    if command -v psql &> /dev/null; then
        print_info "Test de connexion avec psql..."
        if timeout 10 psql "$APP_CONN_STR" -c "SELECT version();" &> /dev/null; then
            print_success "Connexion à la base de données réussie!"
        else
            print_info "Connexion directe échouée (firewall ou permissions)"
        fi
    else
        print_info "psql non disponible - sautez le test de connexion"
    fi
    
else
    print_error "Impossible de récupérer les chaînes de connexion"
    print_info "Vérifiez les permissions Key Vault"
fi

echo ""
echo -e "${GREEN}=================================================================${NC}"
echo -e "${GREEN}✅ Configuration post-déploiement terminée!${NC}"
echo -e "${GREEN}=================================================================${NC}"
echo ""
echo -e "${YELLOW}Résumé de la configuration:${NC}"
echo "🔹 Groupe de ressources: $RESOURCE_GROUP_NAME"
echo "🔹 Serveur PostgreSQL: $SERVER_FQDN"
echo "🔹 Base de données: $DATABASE_NAME"
echo "🔹 Key Vault: $KEY_VAULT_NAME"
echo "🔹 Configuration: .env.local mis à jour"
echo ""
echo -e "${CYAN}Prochaines étapes:${NC}"
echo "1. Créer l'utilisateur application:"
echo "   ./scripts/setup-database-user.sh"
echo ""
echo "2. Tester l'application:"
echo "   npm run dev"
echo ""
echo "3. Configurer le firewall si nécessaire:"
echo "   az postgres flexible-server firewall-rule create \\"
echo "     --resource-group $RESOURCE_GROUP_NAME \\"
echo "     --name $SERVER_NAME \\"
echo "     --rule-name 'AllowMyIP' \\"
echo "     --start-ip-address [VOTRE_IP] \\"
echo "     --end-ip-address [VOTRE_IP]"
