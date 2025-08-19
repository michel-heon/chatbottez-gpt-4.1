#!/bin/bash
# ============================================================================
# Sync Azure OpenAI API Key from Shared Key Vault to Local DEV-06 Key Vault
# Usage: ./scripts/sync-openai-key-dev06.sh [-g <local_resource_group>] [-s <shared_resource_group>]
# Requires: Azure CLI logged in with access to both KVs.
# ============================================================================
set -euo pipefail

LOCAL_RG_DEFAULT="rg-chatbottez-gpt-4-1-dev-06"
SHARED_RG_DEFAULT="rg-cotechnoe-ai-01"
SECRET_TARGET_NAME="azure-openai-key"
SHARED_SECRET_CANDIDATES=("azure-openai-key" "openai-api-key")

LOCAL_RG="$LOCAL_RG_DEFAULT"
SHARED_RG="$SHARED_RG_DEFAULT"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -g|--group) LOCAL_RG="$2"; shift 2;;
    -s|--shared-group) SHARED_RG="$2"; shift 2;;
    -h|--help)
      echo "Usage: $0 [-g <local_resource_group>] [-s <shared_resource_group>]"; exit 0;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

echo "=== 🔐 Sync OpenAI Key (DEV-06) ==="

# 1. Preconditions
command -v az >/dev/null || { echo "❌ Azure CLI absent"; exit 1; }
az account show >/dev/null 2>&1 || { echo "❌ az login requis"; exit 1; }

# 2. Resolve local Key Vault
LOCAL_KV=$(az keyvault list --resource-group "$LOCAL_RG" --query "[0].name" -o tsv 2>/dev/null || true)
[[ -z "$LOCAL_KV" ]] && { echo "❌ Key Vault local introuvable dans $LOCAL_RG"; exit 1; }

echo "Local KV : $LOCAL_KV" 

# 3. Resolve shared Key Vault (explicit name if already known)
SHARED_KV=$(az keyvault list --resource-group "$SHARED_RG" --query "[0].name" -o tsv 2>/dev/null || true)
[[ -z "$SHARED_KV" ]] && { echo "❌ Key Vault partagé introuvable dans $SHARED_RG"; exit 1; }

echo "Shared KV: $SHARED_KV"

# 4. Fetch secret from shared (first candidate that exists)
OPENAI_KEY=""
for cand in "${SHARED_SECRET_CANDIDATES[@]}"; do
  val=$(az keyvault secret show --vault-name "$SHARED_KV" --name "$cand" --query value -o tsv 2>/dev/null || true)
  if [[ -n "$val" ]]; then
    OPENAI_KEY="$val"
    echo "✅ Secret trouvé dans KV partagé: $cand"
    break
  fi
done
[[ -z "$OPENAI_KEY" ]] && { echo "❌ Aucun secret OpenAI trouvé dans $SHARED_KV (candidats: ${SHARED_SECRET_CANDIDATES[*]})"; exit 1; }

# 5. Upsert secret into local KV
az keyvault secret set --vault-name "$LOCAL_KV" --name "$SECRET_TARGET_NAME" --value "$OPENAI_KEY" --query name -o tsv >/dev/null
echo "✅ Secret synchronisé vers local: $SECRET_TARGET_NAME"

# 6. Display App Service info & optional restart
WEBAPP=$(az webapp list --resource-group "$LOCAL_RG" --query "[0].name" -o tsv 2>/dev/null || true)
if [[ -n "$WEBAPP" ]]; then
  echo "🔄 Redémarrage Web App pour forcer rechargement éventuel..."
  az webapp restart --resource-group "$LOCAL_RG" --name "$WEBAPP" >/dev/null || echo "⚠️ Redémarrage échoué (non bloquant)"
  echo "🌐 Web App: $WEBAPP"
fi

# 7. Verify Key Vault reference (optional)
if [[ -n "$WEBAPP" ]]; then
  REF_PRESENT=$(az webapp config appsettings list --resource-group "$LOCAL_RG" --name "$WEBAPP" --query "[?name=='AZURE_OPENAI_API_KEY']|length(@)" -o tsv 2>/dev/null || echo 0)
  if [[ "$REF_PRESENT" -eq 0 ]]; then
    echo "⚠️ App setting AZURE_OPENAI_API_KEY absent. Ajout de la référence Key Vault..."
    az webapp config appsettings set --resource-group "$LOCAL_RG" --name "$WEBAPP" --settings AZURE_OPENAI_API_KEY="@Microsoft.KeyVault(SecretUri=https://$LOCAL_KV.vault.azure.net/secrets/$SECRET_TARGET_NAME/)" >/dev/null || echo "⚠️ Impossible d'ajouter l'app setting automatiquement"
  fi
fi

echo "🎉 Synchronisation terminée. Test: curl -I https://$WEBAPP.azurewebsites.net/health"
