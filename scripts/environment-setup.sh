#!/bin/bash
# =================================================================
# Script: setup-environment.sh
# Configuration simplifiée de l'environnement de développement
# =================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}$1${NC}"
}

print_step() {
    echo -e "${MAGENTA}[STEP $1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

echo ""
print_header "================================================================="
print_header "Configuration Environnement Microsoft Marketplace Quota"
print_header "================================================================="
echo ""

# Step 1: Check prerequisites
print_step "1" "Vérification des prérequis..."

# Check Azure CLI
if command -v az &> /dev/null; then
    AZ_VERSION=$(az --version 2>/dev/null | head -n1)
    print_success "Azure CLI trouvé"
else
    print_error "Azure CLI n'est pas installé"
    print_info "Installation: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_success "Node.js $NODE_VERSION trouvé"
else
    print_error "Node.js n'est pas installé"
    print_info "Installation: https://nodejs.org/"
    exit 1
fi

# Check npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    print_success "npm $NPM_VERSION trouvé"
else
    print_error "npm n'est pas installé"
    exit 1
fi

# Step 2: Azure login check
print_step "2" "Vérification connexion Azure..."

if az account show &> /dev/null; then
    TENANT_ID=$(az account show --query tenantId -o tsv)
    ACCOUNT_NAME=$(az account show --query name -o tsv)
    print_success "Connecté - Tenant: $TENANT_ID"
    print_info "Abonnement: $ACCOUNT_NAME"
else
    print_warn "Non connecté à Azure CLI"
    print_info "Ouverture de la page de connexion Azure..."
    
    if az login; then
        TENANT_ID=$(az account show --query tenantId -o tsv)
        ACCOUNT_NAME=$(az account show --query name -o tsv)
        print_success "Connexion réussie - Tenant: $TENANT_ID"
    else
        print_error "Échec de la connexion Azure"
        exit 1
    fi
fi

# Step 3: Create env/.env.local
print_step "3" "Création du fichier env/.env.local..."

if [ -f "env/.env.local" ]; then
    echo ""
    read -p "Le fichier env/.env.local existe. Remplacer? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Conservation du fichier existant"
        
        # Vérifier si TENANT_ID est déjà configuré
        if grep -q "^TENANT_ID=" env/.env.local && ! grep -q "your-azure-tenant-id" env/.env.local; then
            print_info "TENANT_ID déjà configuré dans env/.env.local"
        else
            # Mettre à jour seulement TENANT_ID
            if grep -q "your-azure-tenant-id" env/.env.local; then
                sed -i.backup "s/your-azure-tenant-id/$TENANT_ID/g" env/.env.local
                print_success "TENANT_ID mis à jour: $TENANT_ID"
            fi
        fi
        
        echo ""
        print_info "Validation du fichier existant..."
        validate_env_file
        exit 0
    fi
    echo ""
fi

if [ ! -f "env/.env.example" ]; then
    print_error "Fichier env/.env.example non trouvé"
    print_info "Assurez-vous d'être dans le répertoire racine du projet"
    exit 1
fi

# Copy template
cp "env/env/.env.example" "env/.env.local"
print_success "Fichier env/.env.local créé"

# Replace TENANT_ID
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '.backup' "s/your-azure-tenant-id/$TENANT_ID/g" env/.env.local
else
    # Linux/WSL
    sed -i.backup "s/your-azure-tenant-id/$TENANT_ID/g" env/.env.local
fi
print_success "TENANT_ID configuré: $TENANT_ID"

# Step 4: Generate JWT Secret
print_step "4" "Génération du secret JWT..."

if command -v openssl &> /dev/null; then
    JWT_SECRET=$(openssl rand -hex 32)
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '.backup' "s/your-jwt-secret-key-64-characters-long/$JWT_SECRET/g" env/.env.local
    else
        sed -i.backup "s/your-jwt-secret-key-64-characters-long/$JWT_SECRET/g" env/.env.local
    fi
    
    print_success "JWT_SECRET_KEY généré"
elif command -v node &> /dev/null; then
    # Fallback with Node.js
    JWT_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '.backup' "s/your-jwt-secret-key-64-characters-long/$JWT_SECRET/g" env/.env.local
    else
        sed -i.backup "s/your-jwt-secret-key-64-characters-long/$JWT_SECRET/g" env/.env.local
    fi
    
    print_success "JWT_SECRET_KEY généré (via Node.js)"
else
    print_warn "openssl et Node.js non disponibles - JWT secret non généré"
    print_info "Génération manuelle requise pour JWT_SECRET_KEY"
fi

# Nettoyer les fichiers de backup
rm -f env/.env.local.backup

# Step 5: Manual configuration guidance
print_step "5" "Variables à configurer manuellement..."

echo ""
echo -e "${YELLOW}Variables nécessitant une configuration manuelle dans env/.env.local:${NC}"
echo ""
echo -e "${CYAN}🔧 Infrastructure Azure:${NC}"
echo -e "   DATABASE_URL - Base de données PostgreSQL (Azure ou local)"
echo -e "   AZURE_STORAGE_CONNECTION_STRING - Compte Azure Storage"
echo -e "   APPLICATION_INSIGHTS_CONNECTION_STRING - Application Insights"
echo ""
echo -e "${CYAN}🤖 Bot Configuration:${NC}"
echo -e "   BOT_ID, BOT_PASSWORD - Azure Bot Service"
echo ""
echo -e "${CYAN}🧠 AI Services:${NC}"
echo -e "   AZURE_OPENAI_API_KEY, AZURE_OPENAI_ENDPOINT - Azure OpenAI"
echo ""
echo -e "${CYAN}💼 Marketplace API:${NC}"
echo -e "   MARKETPLACE_API_KEY - Clé API Microsoft Marketplace"
echo ""

# Step 6: Run marketplace script if available
print_step "6" "Configuration Marketplace..."

if [ -f "scripts/marketplace-api-key.sh" ]; then
    print_info "Script marketplace-api-key.sh trouvé"
    echo ""
    print_info "Pour configurer les credentials Marketplace, exécutez:"
    echo -e "   ${CYAN}./scripts/marketplace-api-key.sh -C -n 'chatbottez-marketplace' -o marketplace.env${NC}"
    echo -e "   Puis copiez les valeurs dans env/.env.local"
    echo ""
    
    read -p "Voulez-vous exécuter le script marketplace maintenant? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        chmod +x scripts/marketplace-api-key.sh
        if ./scripts/marketplace-api-key.sh -C -n 'chatbottez-marketplace' -o marketplace.env; then
            print_success "Configuration Marketplace terminée"
            print_info "Vérifiez marketplace.env et copiez les valeurs vers env/.env.local"
        else
            print_warn "Échec de la configuration Marketplace"
        fi
    fi
else
    print_warn "Script marketplace-api-key.sh non trouvé"
fi

# Step 7: Database configuration check
print_step "7" "Vérification configuration base de données..."

if [ -f "config/azure.env" ]; then
    print_info "Configuration Azure trouvée"
    if [ -f "deployment-outputs.json" ]; then
        print_info "Déploiement Azure détecté"
        echo -e "   Pour utiliser la base Azure déployée, votre DATABASE_URL est:"
        
        # Tenter de récupérer la chaîne de connexion depuis les outputs
        if command -v jq &> /dev/null && [ -f "deployment-outputs.json" ]; then
            echo -e "   ${GREEN}$(jq -r '.appConnectionString.value // empty' deployment-outputs.json)${NC}"
        else
            echo -e "   Voir deployment-outputs.json ou Azure Key Vault"
        fi
    else
        print_info "Pour déployer Azure Database, exécutez:"
        echo -e "   ${CYAN}./scripts/deploy-azure-hybrid.sh${NC}"
    fi
else
    print_info "Pour configurer Azure Database, voir la documentation"
fi

# Function to validate env/.env.local file
validate_env_file() {
    local missing_vars=()
    local configured_vars=()
    
    # Variables critiques à vérifier
    local critical_vars=("TENANT_ID" "JWT_SECRET_KEY")
    
    for var in "${critical_vars[@]}"; do
        if grep -q "^${var}=" env/.env.local; then
            local value=$(grep "^${var}=" env/.env.local | cut -d'=' -f2)
            if [[ "$value" != *"your-"* ]] && [ -n "$value" ]; then
                configured_vars+=("$var")
            else
                missing_vars+=("$var")
            fi
        else
            missing_vars+=("$var")
        fi
    done
    
    echo ""
    print_info "État de la configuration:"
    
    if [ ${#configured_vars[@]} -gt 0 ]; then
        echo -e "${GREEN}✅ Variables configurées:${NC}"
        for var in "${configured_vars[@]}"; do
            echo -e "   ✓ $var"
        done
    fi
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Variables à configurer:${NC}"
        for var in "${missing_vars[@]}"; do
            echo -e "   ○ $var"
        done
    fi
}

echo ""
print_success "Configuration de base terminée!"
echo ""

# Validation finale
validate_env_file

echo ""
print_header "🚀 Prochaines étapes:"
echo ""
echo -e "${CYAN}1.${NC} Éditer env/.env.local pour compléter les variables manquantes"
echo -e "${CYAN}2.${NC} Installer les dépendances: ${GREEN}npm install${NC}"
echo -e "${CYAN}3.${NC} Tester l'application: ${GREEN}npm run dev${NC}"
echo -e "${CYAN}4.${NC} Configurer la base de données (voir documentation)"
echo ""
print_header "================================================================="
