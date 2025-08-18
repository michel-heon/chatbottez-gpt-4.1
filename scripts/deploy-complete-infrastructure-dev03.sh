#!/bin/bash

# =================================================================
# Script de Déploiement Infrastructure Complète - Dev-03
# ChatBottez GPT-4.1 - Nouveau groupe de ressources complet
# =================================================================

set -euo pipefail

# Configuration
TARGET_RESOURCE_GROUP="rg-chatbottez-gpt-4-1-dev-03"
LOCATION="Canada Central"
DEPLOYMENT_NAME="complete-infrastructure-dev03-$(date +%Y%m%d-%H%M%S)"
BICEP_FILE="infra/complete-infrastructure-dev03.bicep"
PARAMETERS_FILE="infra/complete-infrastructure-dev03.parameters.json"

# Couleurs pour l'output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}=================================================================${NC}"
echo -e "${CYAN}🚀 Déploiement Infrastructure Complète ChatBottez GPT-4.1 Dev-03${NC}"
echo -e "${CYAN}=================================================================${NC}"
echo ""

# Vérifications préalables
echo -e "${YELLOW}🔍 Vérifications préalables...${NC}"

# Vérifier Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI n'est pas installé${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Azure CLI disponible${NC}"

# Vérifier la connexion Azure
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Non connecté à Azure${NC}"
    echo "Veuillez vous connecter avec: az login"
    exit 1
fi
echo -e "${GREEN}✅ Connecté à Azure${NC}"

# Vérifier que les fichiers Bicep existent
if [[ ! -f "$BICEP_FILE" ]]; then
    echo -e "${RED}❌ Fichier Bicep $BICEP_FILE introuvable${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Fichier Bicep trouvé${NC}"

if [[ ! -f "$PARAMETERS_FILE" ]]; then
    echo -e "${RED}❌ Fichier de paramètres $PARAMETERS_FILE introuvable${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Fichier de paramètres trouvé${NC}"

# Vérifier que le groupe de ressources partagé existe
if ! az group show --name "rg-cotechnoe-ai-01" &> /dev/null; then
    echo -e "${RED}❌ Groupe de ressources partagé rg-cotechnoe-ai-01 n'existe pas${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Groupe de ressources partagé accessible${NC}"

echo ""

# Demander confirmation de l'utilisateur
echo -e "${YELLOW}📋 Résumé du déploiement:${NC}"
echo "   • Nouveau groupe de ressources: $TARGET_RESOURCE_GROUP"
echo "   • Région: $LOCATION"
echo "   • Nom du déploiement: $DEPLOYMENT_NAME"
echo "   • Fichier Bicep: $BICEP_FILE"
echo "   • Paramètres: $PARAMETERS_FILE"
echo ""

# Composants qui seront déployés
echo -e "${YELLOW}🏗️  Composants qui seront créés:${NC}"
echo "   • Nouveau Resource Group"
echo "   • PostgreSQL Flexible Server + Database"
echo "   • Key Vault local"
echo "   • Log Analytics Workspace"
echo "   • Application Insights"
echo "   • API Management (Developer SKU)"
echo "   • App Service Plan (Basic B1)"
echo "   • Web App pour Teams Bot"
echo "   • Key Vault Access Policies"
echo "   • Secrets dans Key Vault"
echo ""

echo -e "${YELLOW}🔗 Ressources mutualisées réutilisées:${NC}"
echo "   • Azure OpenAI Service (openai-cotechnoe)"
echo "   • Key Vault partagé (kv-cotechno771554451004)"
echo "   • Depuis: rg-cotechnoe-ai-01"
echo ""

read -p "Voulez-vous continuer avec le déploiement? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ Déploiement annulé par l'utilisateur${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}🚀 Démarrage du déploiement...${NC}"

# Valider le template Bicep
echo -e "${YELLOW}🔍 Validation du template Bicep...${NC}"
if az deployment sub validate \
    --location "$LOCATION" \
    --template-file "$BICEP_FILE" \
    --parameters "@$PARAMETERS_FILE" \
    --output none; then
    echo -e "${GREEN}✅ Template Bicep valide${NC}"
else
    echo -e "${RED}❌ Erreur de validation du template Bicep${NC}"
    exit 1
fi

# Prévisualiser les changements (What-If)
echo -e "${YELLOW}🔍 Prévisualisation des changements (What-If)...${NC}"
az deployment sub what-if \
    --location "$LOCATION" \
    --template-file "$BICEP_FILE" \
    --parameters "@$PARAMETERS_FILE"

echo ""
read -p "Les changements ci-dessus vous conviennent-ils? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ Déploiement annulé après aperçu${NC}"
    exit 0
fi

# Déploiement effectif
echo ""
echo -e "${CYAN}🚀 Déploiement en cours...${NC}"
echo "⏱️  Ceci peut prendre 20-35 minutes..."

START_TIME=$(date +%s)

if az deployment sub create \
    --name "$DEPLOYMENT_NAME" \
    --location "$LOCATION" \
    --template-file "$BICEP_FILE" \
    --parameters "@$PARAMETERS_FILE" \
    --output json > deployment_output_dev03.json; then
    
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    echo -e "${GREEN}✅ Déploiement terminé avec succès!${NC}"
    echo "⏱️  Durée: ${MINUTES}m ${SECONDS}s"
    
    # Afficher les outputs
    echo ""
    echo -e "${CYAN}📋 Informations de déploiement:${NC}"
    
    # Extraire les outputs du déploiement
    if command -v jq &> /dev/null; then
        echo "📋 Ressources déployées:"
        jq -r '.properties.outputs | to_entries[] | "   • \(.key): \(.value.value)"' deployment_output_dev03.json 2>/dev/null || true
    else
        echo "   Consultez deployment_output_dev03.json pour les détails complets"
    fi
    
else
    echo -e "${RED}❌ Erreur durant le déploiement${NC}"
    echo "Consultez les logs Azure pour plus de détails"
    exit 1
fi

echo ""
echo -e "${CYAN}🎉 Infrastructure complète déployée avec succès!${NC}"
echo ""
echo -e "${YELLOW}📋 Prochaines étapes:${NC}"
echo "   1. Vérifier le déploiement: az deployment sub show --name $DEPLOYMENT_NAME"
echo "   2. Configurer la clé API OpenAI dans le Key Vault"
echo "   3. Tester la connectivité: make validate"
echo "   4. Déployer le code de l'application"
echo "   5. Configurer Teams Bot Framework"
echo "   6. Tester l'intégration complète"

echo ""
echo -e "${YELLOW}🔐 Configuration manuelle requise:${NC}"
echo "   • Ajouter la clé API OpenAI au Key Vault local:"
echo "     az keyvault secret set --vault-name \$(jq -r '.properties.outputs.keyVaultName.value' deployment_output_dev03.json) --name 'azure-openai-key' --value 'YOUR_OPENAI_API_KEY'"

echo ""
echo -e "${GREEN}✨ Déploiement terminé!${NC}"
