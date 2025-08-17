#!/usr/bin/env bash
# =================================================================
# Script: configure-environment.sh
# Objet: Configuration automatique de l'environnement de développement
# Usage: ./scripts/configure-environment.sh
# =================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
step() { echo -e "${PURPLE}[STEP]${NC} $*"; }

echo -e "${CYAN}"
echo "================================================================="
echo "🔧 Configuration Environnement Microsoft Marketplace Quota"
echo "================================================================="
echo -e "${NC}"

# Check prerequisites
step "1. Vérification des prérequis..."

# Check if Azure CLI is installed
if ! command -v az >/dev/null 2>&1; then
    error "Azure CLI (az) n'est pas installé."
    error "Installer depuis: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi
success "Azure CLI trouvé"

# Check if Node.js is installed
if ! command -v node >/dev/null 2>&1; then
    error "Node.js n'est pas installé."
    exit 1
fi
success "Node.js $(node --version) trouvé"

# Check if OpenSSL is available for JWT secret generation
if ! command -v openssl >/dev/null 2>&1; then
    warn "OpenSSL non trouvé. JWT_SECRET_KEY devra être généré manuellement."
    JWT_AVAILABLE=false
else
    success "OpenSSL trouvé"
    JWT_AVAILABLE=true
fi

# Check Azure login
step "2. Vérification connexion Azure..."
if ! az account show >/dev/null 2>&1; then
    warn "Non connecté à Azure CLI. Connexion requise..."
    az login
fi

TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
USER_EMAIL=$(az account show --query user.name -o tsv)

success "Connecté en tant que: $USER_EMAIL"
success "Tenant ID: $TENANT_ID"
success "Subscription ID: $SUBSCRIPTION_ID"

# Step 3: Create .env.local from template
step "3. Configuration du fichier .env.local..."

if [[ -f ".env.local" ]]; then
    warn "Le fichier .env.local existe déjà."
    read -p "Voulez-vous le remplacer? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Conservation du fichier existant."
        ENV_CREATED=false
    else
        cp .env.example .env.local
        ENV_CREATED=true
    fi
else
    cp .env.example .env.local
    ENV_CREATED=true
fi

if [[ $ENV_CREATED == true ]]; then
    success "Fichier .env.local créé depuis .env.example"
    
    # Replace basic values
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/your-azure-tenant-id/$TENANT_ID/g" .env.local
    else
        # Linux/Windows
        sed -i "s/your-azure-tenant-id/$TENANT_ID/g" .env.local
    fi
    
    success "TENANT_ID configuré: $TENANT_ID"
fi

# Step 4: Generate JWT Secret
step "4. Génération du secret JWT..."

if [[ $JWT_AVAILABLE == true ]]; then
    JWT_SECRET=$(openssl rand -hex 32)
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/your-jwt-secret-key-64-characters-long/$JWT_SECRET/g" .env.local
    else
        sed -i "s/your-jwt-secret-key-64-characters-long/$JWT_SECRET/g" .env.local
    fi
    
    success "JWT_SECRET_KEY généré et configuré"
else
    warn "Veuillez générer manuellement JWT_SECRET_KEY dans .env.local"
    warn "Utilisez: openssl rand -hex 32"
fi

# Step 5: Run marketplace-api-key.sh if available
step "5. Configuration des credentials Microsoft Marketplace..."

if [[ -f "scripts/marketplace-api-key.sh" ]]; then
    info "Script marketplace-api-key.sh trouvé. Configuration automatique..."
    
    # Make script executable
    chmod +x scripts/marketplace-api-key.sh
    
    # Run the script to create marketplace credentials
    APP_NAME="chatbottez-marketplace-$(date +%Y%m%d%H%M)"
    
    info "Création de l'application Azure AD: $APP_NAME"
    info "Cela va créer une application avec les permissions nécessaires..."
    
    # Run marketplace-api-key.sh
    if ./scripts/marketplace-api-key.sh -C -n "$APP_NAME" -o marketplace-temp.env -v 3; then
        success "Credentials Marketplace générés avec succès"
        
        # Extract values from marketplace-temp.env and update .env.local
        if [[ -f "marketplace-temp.env" ]]; then
            source marketplace-temp.env
            
            # Update .env.local with marketplace values
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s/your-client-app-id/$CLIENT_ID/g" .env.local
                sed -i '' "s/your-client-secret/$CLIENT_SECRET/g" .env.local
                sed -i '' "s/your-oauth2-token/$MARKETPLACE_API_TOKEN/g" .env.local
                sed -i '' "s/2025-08-18T12:00:00Z/$MARKETPLACE_TOKEN_EXPIRES_ON/g" .env.local
            else
                sed -i "s/your-client-app-id/$CLIENT_ID/g" .env.local
                sed -i "s/your-client-secret/$CLIENT_SECRET/g" .env.local
                sed -i "s/your-oauth2-token/$MARKETPLACE_API_TOKEN/g" .env.local
                sed -i "s/2025-08-18T12:00:00Z/$MARKETPLACE_TOKEN_EXPIRES_ON/g" .env.local
            fi
            
            success "Credentials Marketplace intégrés dans .env.local"
            
            # Clean up temporary file
            rm marketplace-temp.env
        fi
    else
        warn "Échec de génération des credentials Marketplace"
        warn "Veuillez les configurer manuellement dans .env.local"
    fi
else
    warn "Script marketplace-api-key.sh non trouvé"
    warn "Veuillez configurer manuellement MARKETPLACE_API_KEY dans .env.local"
fi

# Step 6: Configuration guidance
step "6. Configuration manuelle requise..."

echo -e "${YELLOW}"
cat <<EOF
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

EOF
echo -e "${NC}"

# Step 7: Next steps
step "7. Prochaines étapes..."

echo -e "${GREEN}"
cat <<EOF
✅ Configuration de base terminée!

🔧 Prochaines actions:
   1. Éditer .env.local pour compléter les variables manquantes
   2. Exécuter: npm run dev pour tester l'application
   3. Vérifier les logs pour identifier les problèmes de configuration
   4. Passer à l'étape 3 du TODO: Configuration de la base de données

📁 Fichiers créés/modifiés:
   - .env.local (configuration principale)
   - Application Azure AD: $APP_NAME (credentials Marketplace)

📖 Documentation:
   - README_QUOTA.md pour plus de détails
   - TODO.md pour les prochaines étapes

EOF
echo -e "${NC}"

success "Configuration terminée! Vérifiez .env.local et complétez les variables manquantes."
