#!/bin/bash
# ============================================================================
# purge-infra-dev-06.sh
# Purge des ressources soft-deleted (API Management / Key Vault) pour DEV-06
# Usage:
#   ./scripts/purge-infra-dev-06.sh [-l canadacentral] [-p dev-06] [--auto] [--dry-run]
# Options:
#   -l, --location <loc>    Région Azure (default: canadacentral)
#   -p, --pattern <text>    Mot/fragment pour filtrer (dans ServiceId APIM ou nom KV) (default: dev-06)
#   --purge-all-kv          Purger tous les Key Vault correspondant au préfixe (danger)
#   --auto                  Pas de confirmation interactive
#   -n, --dry-run           Affiche les commandes sans exécuter les purges
# ============================================================================
set -euo pipefail

LOCATION="canadacentral"
PATTERN="dev-06"
AUTO=false
PURGE_ALL_KV=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -l|--location) LOCATION="$2"; shift 2;;
    -p|--pattern) PATTERN="$2"; shift 2;;
    --purge-all-kv) PURGE_ALL_KV=true; shift;;
    --auto) AUTO=true; shift;;
    -n|--dry-run) DRY_RUN=true; shift;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# //'; exit 0;;
    *) echo "Argument inconnu: $1"; exit 1;;
  esac
done

command -v az >/dev/null || { echo "❌ Azure CLI manquant"; exit 1; }
az account show >/dev/null 2>&1 || { echo "❌ az login requis"; exit 1; }
command -v jq >/dev/null || { echo "❌ jq requis (sudo apt install jq)"; exit 1; }

echo "======================================================"
echo "♻ Purge soft-deleted ressources (DEV-06 pattern: $PATTERN) (dry-run=$DRY_RUN)"
echo "======================================================"

# ------------------------------------------------------------------
# API MANAGEMENT (soft-deleted)
# ------------------------------------------------------------------
APIM_JSON=$(az apim deletedservice list -o json 2>/dev/null || echo '[]')
# Null-safe: certaines entrées peuvent avoir ServiceId = null -> on protège test()
APIM_MATCHES=$(echo "$APIM_JSON" | jq -r --arg P "$PATTERN" '.[] | select(.ServiceId? != null and (.ServiceId | test($P; "i"))) | .Name' || true)

if [[ -n "${APIM_MATCHES}" ]]; then
  echo "🔍 APIM soft-deleted correspondant au pattern '$PATTERN':"
  echo "$APIM_MATCHES" | sed 's/^/  - /'
  if [[ "$AUTO" == false && "$DRY_RUN" == false ]]; then
    read -rp "Confirmer la purge APIM (y/N)? " RESP
    [[ "$RESP" =~ ^[Yy]$ ]] || { echo "⏭️  Skip purge APIM"; APIM_MATCHES=""; }
  fi
  for name in $APIM_MATCHES; do
    if [[ "$DRY_RUN" == true ]]; then
      echo "🧪 Dry-run: az apim deletedservice purge --service-name '$name' --location '$LOCATION'"
    else
      echo "➡ Purge APIM: $name"
      az apim deletedservice purge --service-name "$name" --location "$LOCATION"
    fi
  done
else
  echo "✅ Aucun APIM soft-deleted à purger pour pattern '$PATTERN'"
fi

# ------------------------------------------------------------------
# KEY VAULT (soft-deleted)
# ------------------------------------------------------------------
KV_JSON=$(az keyvault list-deleted -o json 2>/dev/null || echo '[]')
if [[ "$PURGE_ALL_KV" == true ]]; then
  KV_MATCHES=$(echo "$KV_JSON" | jq -r '.[] | select(.name | startswith("kv-gpt41-")) | .name' || true)
else
  # Null-safe .name (normalement toujours présent)
  KV_MATCHES=$(echo "$KV_JSON" | jq -r --arg P "$PATTERN" '.[] | select(.name? != null and (.name | test($P; "i"))) | .name' || true)
fi

if [[ -n "$KV_MATCHES" ]]; then
  echo "🔍 Key Vault soft-deleted candidats:"
  echo "$KV_MATCHES" | sed 's/^/  - /'
  if [[ "$AUTO" == false && "$DRY_RUN" == false ]]; then
    read -rp "Confirmer la purge Key Vault (y/N)? " RESP2
    [[ "$RESP2" =~ ^[Yy]$ ]] || { echo "⏭️  Skip purge Key Vault"; KV_MATCHES=""; }
  fi
  for kv in $KV_MATCHES; do
    if [[ "$DRY_RUN" == true ]]; then
      echo "🧪 Dry-run: az keyvault purge --name '$kv' --location '$LOCATION'"
    else
      echo "➡ Purge Key Vault: $kv"
      az keyvault purge --name "$kv" --location "$LOCATION" || echo "⚠️  Purge échouée pour $kv"
    fi
  done
else
  echo "✅ Aucun Key Vault soft-deleted à purger (pattern=$PATTERN, purge_all=$PURGE_ALL_KV)"
fi

echo "------------------------------------------------------"
if [[ "$DRY_RUN" == true ]]; then
  echo "✅ Dry-run terminé (aucune purge effectuée)"
else
  echo "✅ Purge terminée"
fi
echo "💡 Relancer ensuite: make deploy-dev06"
echo "======================================================"
