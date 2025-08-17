#!/bin/bash
# =================================================================
# Test de la Configuration Azure - Script Bash
# =================================================================

set -e

# Charger le module de configuration
source scripts/config-loader.sh

echo "=================================="
echo "Test de Configuration Azure (Bash)"
echo "=================================="

# Test du module de configuration
echo ""
echo "1. Test du chargement de configuration..."
if load_azure_config; then
    echo "✅ Configuration chargée"
else
    echo "❌ Échec du chargement"
    exit 1
fi

echo ""
echo "2. Test de validation..."
if validate_azure_config; then
    echo "✅ Configuration validée"
else
    echo "❌ Échec de validation"
    exit 1
fi

echo ""
echo "3. Affichage de la configuration:"
show_azure_config

echo ""
echo "4. Test de génération JSON:"
echo ""
export_azure_config_json

echo ""
echo "5. Vérification des noms générés:"
echo "   Resource Group: $RESOURCE_GROUP_NAME"
echo "   Server Name: $SERVER_NAME"
echo "   Key Vault: $KEY_VAULT_NAME"

echo ""
echo "6. Test Azure CLI (si disponible):"
if command -v az &> /dev/null; then
    echo "   Azure CLI: ✅ Installé"
    if az account show &> /dev/null; then
        account_name=$(az account show --query name -o tsv)
        subscription_id=$(az account show --query id -o tsv)
        echo "   Connexion: ✅ Connecté à '$account_name'"
        echo "   Subscription: $subscription_id"
    else
        echo "   Connexion: ❌ Non connecté (az login requis)"
    fi
else
    echo "   Azure CLI: ❌ Non installé"
fi

echo ""
echo "=================================="
echo "✅ Test terminé avec succès!"
echo "=================================="
echo ""
echo "Pour déployer avec Bash:"
echo "  chmod +x scripts/deploy-azure-database.sh"
echo "  ./scripts/deploy-azure-database.sh --show-config --create-resource-group"
