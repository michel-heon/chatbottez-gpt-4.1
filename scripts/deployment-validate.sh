#!/bin/bash
# =================================================================
# Validation complète du déploiement Azure - Bash
# =================================================================

set -e

source scripts/config-loader.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}$1${NC}"
}

print_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}  ✅ $1${NC}"
}

print_fail() {
    echo -e "${RED}  ❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}  ℹ️  $1${NC}"
}

CHECKS_PASSED=0
CHECKS_TOTAL=0

run_check() {
    local description="$1"
    local command="$2"
    
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    print_check "$description"
    
    if eval "$command" &> /dev/null; then
        print_pass "OK"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        return 0
    else
        print_fail "ÉCHEC"
        return 1
    fi
}

echo ""
print_header "================================================================="
print_header "🔍 Validation Complète du Déploiement Azure"
print_header "================================================================="
echo ""

# Charger la configuration
if ! load_azure_config &> /dev/null; then
    print_fail "Impossible de charger la configuration"
    exit 1
fi

print_header "📋 Résumé de la Configuration"
echo "   Projet: $PROJECT_NAME"
echo "   Environnement: $ENVIRONMENT"
echo "   Région: $AZURE_LOCATION"
echo "   Groupe de ressources: $RESOURCE_GROUP_NAME"
echo ""

print_header "🔧 Validation de l'Infrastructure"

# Tests de base
run_check "Azure CLI installé" "command -v az"
run_check "Connexion à Azure active" "az account show"
run_check "Groupe de ressources existe" "az group show --name '$RESOURCE_GROUP_NAME'"

# Extraire les informations du déploiement
if [ -f "deployment-outputs.json" ]; then
    KEY_VAULT_NAME=$(powershell.exe -Command "(Get-Content deployment-outputs.json | ConvertFrom-Json).keyVaultName.value" | tr -d '\r')
    SERVER_NAME=$(powershell.exe -Command "(Get-Content deployment-outputs.json | ConvertFrom-Json).serverName.value" | tr -d '\r')
    SERVER_FQDN=$(powershell.exe -Command "(Get-Content deployment-outputs.json | ConvertFrom-Json).serverFQDN.value" | tr -d '\r')
    
    print_header "🗄️  Validation des Ressources"
    
    # Tests des ressources
    run_check "Serveur PostgreSQL existe" "az postgres flexible-server show --name '$SERVER_NAME' --resource-group '$RESOURCE_GROUP_NAME'"
    run_check "Key Vault existe" "az keyvault show --name '$KEY_VAULT_NAME'"
    run_check "Permissions Key Vault configurées" "az keyvault secret show --vault-name '$KEY_VAULT_NAME' --name 'postgres-app-connection-string'"
    
    print_header "🔗 Validation de la Configuration"
    
    # Tests de configuration
    run_check "Fichier .env.local existe" "[ -f '.env.local' ]"
    run_check "DATABASE_URL configuré" "grep -q '^DATABASE_URL=' .env.local"
    run_check "Variables Azure configurées" "grep -q '^AZURE_DATABASE_SERVER=' .env.local"
    
    # Test de connectivité réseau
    print_header "🌐 Tests de Connectivité"
    
    print_check "Résolution DNS du serveur PostgreSQL"
    if nslookup "$SERVER_FQDN" &> /dev/null; then
        print_pass "Résolution DNS OK"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        print_fail "Résolution DNS échouée"
    fi
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    
    print_check "Port PostgreSQL accessible"
    if timeout 5 bash -c "</dev/tcp/$SERVER_FQDN/5432" &> /dev/null; then
        print_pass "Port 5432 accessible"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        print_info "Port 5432 non accessible (firewall Azure)"
    fi
    CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    
    # Test de connexion à la base
    if [ -f ".env.local" ]; then
        DATABASE_URL=$(grep '^DATABASE_URL=' .env.local | cut -d'=' -f2)
        
        print_header "💾 Test de Base de Données"
        
        print_check "Chaîne de connexion valide"
        if [[ "$DATABASE_URL" =~ ^postgresql:// ]]; then
            print_pass "Format de chaîne de connexion correct"
            CHECKS_PASSED=$((CHECKS_PASSED + 1))
        else
            print_fail "Format de chaîne de connexion incorrect"
        fi
        CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
    fi
    
else
    print_fail "Fichier deployment-outputs.json non trouvé"
    print_info "Exécutez d'abord le déploiement"
fi

# Validation des scripts
print_header "📜 Validation des Scripts"

run_check "Script de déploiement exécutable" "[ -x 'scripts/deploy-azure-hybrid.sh' ]"
run_check "Script de configuration exécutable" "[ -x 'scripts/post-deploy-config.sh' ]"
run_check "Module de configuration disponible" "[ -f 'scripts/config-loader.sh' ]"

# Résumé final
echo ""
print_header "📊 Résumé de la Validation"
echo ""

if [ $CHECKS_PASSED -eq $CHECKS_TOTAL ]; then
    print_header "🎉 TOUS LES TESTS RÉUSSIS!"
    echo -e "${GREEN}   $CHECKS_PASSED/$CHECKS_TOTAL vérifications passées${NC}"
    echo ""
    print_header "✨ Système prêt pour utilisation"
    echo ""
    echo -e "${CYAN}Commandes suivantes recommandées:${NC}"
    echo "1. Configurer l'accès réseau:"
    echo "   ./scripts/setup-database-firewall.sh"
    echo ""
    echo "2. Créer les schémas de base de données:"
    echo "   npm run db:migrate"
    echo ""
    echo "3. Démarrer l'application:"
    echo "   npm run dev"
    
elif [ $CHECKS_PASSED -gt $((CHECKS_TOTAL * 3 / 4)) ]; then
    print_header "⚠️  DÉPLOIEMENT PARTIELLEMENT FONCTIONNEL"
    echo -e "${YELLOW}   $CHECKS_PASSED/$CHECKS_TOTAL vérifications passées${NC}"
    echo ""
    echo -e "${YELLOW}Actions requises:${NC}"
    echo "- Vérifier les permissions d'accès réseau"
    echo "- Configurer les règles de pare-feu Azure"
    
else
    print_header "❌ DÉPLOIEMENT INCOMPLET"
    echo -e "${RED}   $CHECKS_PASSED/$CHECKS_TOTAL vérifications passées${NC}"
    echo ""
    echo -e "${RED}Actions critiques requises:${NC}"
    echo "- Revoir la configuration du déploiement"
    echo "- Vérifier les permissions Azure"
    echo "- Relancer le processus de déploiement"
fi

echo ""
print_header "================================================================="

exit 0
