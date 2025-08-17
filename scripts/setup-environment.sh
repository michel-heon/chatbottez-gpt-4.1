#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: setup-environment.sh
# Complément au marketplace-api-key.sh pour setup complet
# -----------------------------------------------------------------------------

set -euo pipefail

source ./marketplace.env

echo "🔧 Configuration complète de l'environnement..."

# Générer JWT_SECRET_KEY si pas présent
if ! grep -q "JWT_SECRET_KEY" ./marketplace.env; then
    echo "Génération JWT_SECRET_KEY..."
    JWT_SECRET=$(openssl rand -hex 32)
    echo "JWT_SECRET_KEY=${JWT_SECRET}" >> ./marketplace.env
fi

# Vérifier les permissions API nécessaires
echo "🔍 Vérification des permissions API..."

# Test API Marketplace
echo "Test connection API Marketplace..."
curl -s -f -H "Authorization: Bearer ${MARKETPLACE_API_TOKEN}" \
     -H "Content-Type: application/json" \
     "${MARKETPLACE_API_BASE}/api/saas/subscriptions?api-version=${MARKETPLACE_SUBSCRIPTION_API_VERSION}" \
     > /dev/null && echo "✅ API Marketplace accessible" || echo "❌ API Marketplace inaccessible (permissions requises)"

echo "📋 Prochaines étapes:"
echo "1. Configurer DATABASE_URL dans .env"
echo "2. Configurer AZURE_STORAGE_CONNECTION_STRING"
echo "3. Configurer APPLICATION_INSIGHTS_CONNECTION_STRING"
echo "4. Dans Partner Center:"
echo "   - Accorder les permissions API nécessaires"
echo "   - Configurer les webhooks de fulfillment"
echo "   - Définir les dimensions de metered billing"
