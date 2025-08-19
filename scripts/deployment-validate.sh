#!/bin/bash
# =================================================================
# Validation complète du déploiement Azure - Bash (DEV-06 aware)
# =================================================================
# Améliorations:
#  - Suppression dépendance powershell.exe (Linux compatible)
#  - Auto-détection des ressources (Web App, Key Vault, Postgres)
#  - Paramètres CLI (--resource-group, --webapp, --kv, --postgres)
#  - Vérifications supplémentaires: App Settings, secrets KV, endpoints HTTP
#  - Résumé structuré avec sections et statut global
# =================================================================

set -euo pipefail

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() { echo -e "${CYAN}$1${NC}"; }
print_check()  { echo -e "${BLUE}[CHECK]${NC} $1"; }
print_pass()   { echo -e "${GREEN}  ✅ $1${NC}"; }
print_fail()   { echo -e "${RED}  ❌ $1${NC}"; }
print_warn()   { echo -e "${YELLOW}  ⚠️  $1${NC}"; }
print_info()   { echo -e "${YELLOW}  ℹ️  $1${NC}"; }

CHECKS_PASSED=0
CHECKS_TOTAL=0
CRITICAL_FAILED=0

RG_DEFAULT="rg-chatbottez-gpt-4-1-dev-06"
RESOURCE_GROUP="$RG_DEFAULT"
WEBAPP_NAME=""
KEY_VAULT_NAME=""
POSTGRES_NAME=""
HEALTH_PATH="/health"
SKIP_HTTP=false
OUTPUT_JSON=false

usage(){
  cat <<EOF
Usage: $0 [options]

Options:
  -g, --resource-group <name>   Resource group (default: $RG_DEFAULT)
  -w, --webapp <name>           Web App name (auto-détection si omis)
  -k, --key-vault <name>        Key Vault name (auto-détection si omis)
  -p, --postgres <name>         PostgreSQL flexible server name (auto-détection si omis)
      --health-path <path>      Endpoint santé (default: /health)
      --skip-http               Ne pas tester les endpoints HTTP
      --json                    Sortie finale JSON (résumé)
  -h, --help                    Aide

Exemples:
  $0
  $0 -g rg-chatbottez-gpt-4-1-dev-06 --json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -g|--resource-group) RESOURCE_GROUP="$2"; shift 2;;
    -w|--webapp) WEBAPP_NAME="$2"; shift 2;;
    -k|--key-vault) KEY_VAULT_NAME="$2"; shift 2;;
    -p|--postgres) POSTGRES_NAME="$2"; shift 2;;
    --health-path) HEALTH_PATH="$2"; shift 2;;
    --skip-http) SKIP_HTTP=true; shift;;
    --json) OUTPUT_JSON=true; shift;;
    -h|--help) usage; exit 0;;
    *) print_fail "Argument inconnu: $1"; usage; exit 1;;
  esac
done

RESULT_JSON_TMP=$(mktemp)

declare -A RESULTS
record_result(){
  local key="$1"; local status="$2"; RESULTS["$key"]="$status";
}

run_check(){
  local key="$1"; local description="$2"; local cmd="$3"; local critical="${4:-false}";
  CHECKS_TOTAL=$((CHECKS_TOTAL+1))
  print_check "$description"
  if eval "$cmd" &>/dev/null; then
    print_pass "$description"
    CHECKS_PASSED=$((CHECKS_PASSED+1))
    record_result "$key" "pass"
  else
    if [ "$critical" = true ]; then
      print_fail "$description"
      record_result "$key" "fail"
      CRITICAL_FAILED=1
    else
      print_warn "$description (échec non critique)"
      record_result "$key" "warn"
    fi
  fi
  return 0
}

echo ""
print_header "================================================================="
print_header "🔍 Validation Complète du Déploiement Azure (DEV-06)"
print_header "================================================================="

# 1. Pré-requis
run_check prereq_az "Azure CLI installé" "command -v az" true
run_check prereq_login "Connexion Azure active" "az account show" true
run_check rg_exists "Groupe de ressources existe ($RESOURCE_GROUP)" "az group show -n '$RESOURCE_GROUP'" true

# Auto-détection ressources si non fournies
if [[ -z "$WEBAPP_NAME" ]]; then
  WEBAPP_NAME=$(az webapp list -g "$RESOURCE_GROUP" --query "[0].name" -o tsv 2>/dev/null || true)
fi
if [[ -z "$KEY_VAULT_NAME" ]]; then
  KEY_VAULT_NAME=$(az keyvault list -g "$RESOURCE_GROUP" --query "[0].name" -o tsv 2>/dev/null || true)
fi
if [[ -z "$POSTGRES_NAME" ]]; then
  POSTGRES_NAME=$(az postgres flexible-server list -g "$RESOURCE_GROUP" --query "[0].name" -o tsv 2>/dev/null || true)
fi

print_header "📋 Ressources détectées"
echo "  Resource Group : $RESOURCE_GROUP"
echo "  Web App        : ${WEBAPP_NAME:-<non trouvé>}"
echo "  Key Vault      : ${KEY_VAULT_NAME:-<non trouvé>}"
echo "  PostgreSQL     : ${POSTGRES_NAME:-<non trouvé>}"

# 2. Ressources principales
[[ -n "$WEBAPP_NAME" ]] && run_check webapp_exists "Web App existe" "az webapp show -g '$RESOURCE_GROUP' -n '$WEBAPP_NAME'" true || record_result webapp_exists fail
[[ -n "$KEY_VAULT_NAME" ]] && run_check kv_exists "Key Vault existe" "az keyvault show -n '$KEY_VAULT_NAME'" true || record_result kv_exists fail
[[ -n "$POSTGRES_NAME" ]] && run_check pg_exists "PostgreSQL existe" "az postgres flexible-server show -g '$RESOURCE_GROUP' -n '$POSTGRES_NAME'" true || record_result pg_exists fail

# 3. Secrets Key Vault
if [[ -n "$KEY_VAULT_NAME" ]]; then
  run_check kv_secret_pg_conn "Secret Chaîne Connexion (postgres-app-connection-string)" "az keyvault secret show --vault-name '$KEY_VAULT_NAME' --name 'postgres-app-connection-string'" false
  run_check kv_secret_openai "Secret OpenAI (azure-openai-key)" "az keyvault secret show --vault-name '$KEY_VAULT_NAME' --name 'azure-openai-key'" false
  run_check kv_secret_bot "Secret Bot (bot-client-secret)" "az keyvault secret show --vault-name '$KEY_VAULT_NAME' --name 'bot-client-secret'" false
fi

# 4. App Settings
if [[ -n "$WEBAPP_NAME" ]]; then
  run_check appsetting_openai "AppSetting AZURE_OPENAI_API_KEY présent" "az webapp config appsettings list -g '$RESOURCE_GROUP' -n '$WEBAPP_NAME' --query "[?name=='AZURE_OPENAI_API_KEY']" -o tsv" false
  run_check appsetting_appid "AppSetting MICROSOFT_APP_ID présent" "az webapp config appsettings list -g '$RESOURCE_GROUP' -n '$WEBAPP_NAME' --query "[?name=='MICROSOFT_APP_ID']" -o tsv" false
  run_check appsetting_apppw "AppSetting MICROSOFT_APP_PASSWORD présent" "az webapp config appsettings list -g '$RESOURCE_GROUP' -n '$WEBAPP_NAME' --query "[?name=='MICROSOFT_APP_PASSWORD']" -o tsv" false
  run_check appsetting_port "AppSetting PORT présent" "az webapp config appsettings list -g '$RESOURCE_GROUP' -n '$WEBAPP_NAME' --query "[?name=='PORT']" -o tsv" false
fi

# 5. Tests HTTP
HTTP_STATUS_MAIN=""
HTTP_STATUS_HEALTH=""
if ! $SKIP_HTTP && [[ -n "$WEBAPP_NAME" ]]; then
  BASE_URL="https://${WEBAPP_NAME}.azurewebsites.net"
  print_header "🌐 Tests HTTP ($BASE_URL)"
  if command -v curl >/dev/null; then
    print_check "Endpoint racine"; HTTP_STATUS_MAIN=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL" || echo "000")
    if [[ "$HTTP_STATUS_MAIN" =~ ^2|3[0-9]{2}$ ]]; then print_pass "HTTP / => $HTTP_STATUS_MAIN"; CHECKS_PASSED=$((CHECKS_PASSED+1)); record_result http_root pass; else print_warn "HTTP / => $HTTP_STATUS_MAIN"; CHECKS_TOTAL=$((CHECKS_TOTAL+1)); record_result http_root warn; fi
    print_check "Endpoint santé ($HEALTH_PATH)"; HTTP_STATUS_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$HEALTH_PATH" || echo "000")
    if [[ "$HTTP_STATUS_HEALTH" =~ ^2|3[0-9]{2}$ ]]; then print_pass "HTTP $HEALTH_PATH => $HTTP_STATUS_HEALTH"; CHECKS_PASSED=$((CHECKS_PASSED+1)); record_result http_health pass; else print_warn "HTTP $HEALTH_PATH => $HTTP_STATUS_HEALTH"; CHECKS_TOTAL=$((CHECKS_TOTAL+1)); record_result http_health warn; fi
  else
    print_warn "curl non installé - tests HTTP ignorés"; record_result http_root skipped; record_result http_health skipped
  fi
fi

# 6. Résumé
SUCCESS=false
if [[ $CHECKS_PASSED -eq $CHECKS_TOTAL ]]; then
  STATUS_GLOBAL="OK"
  SUCCESS=true
elif [[ $CHECKS_PASSED -ge $(( CHECKS_TOTAL * 3 / 4 )) ]]; then
  STATUS_GLOBAL="PARTIEL"
else
  STATUS_GLOBAL="ECHEC"
fi

print_header "📊 Résumé de la Validation"
echo "  Vérifications passées : $CHECKS_PASSED/$CHECKS_TOTAL"
echo "  Statut global         : $STATUS_GLOBAL"

if $SUCCESS; then
  print_header "🎉 TOUS LES TESTS CRITIQUES RÉUSSIS"
else
  print_header "⚠️  VALIDATION INCOMPLETE"
fi

print_header "🛠️ Recommandations"
if [[ "$STATUS_GLOBAL" != "OK" ]]; then
  [[ -n "$WEBAPP_NAME" && "$HTTP_STATUS_MAIN" == "500" ]] && print_info "Analyser les logs: az webapp log tail -g $RESOURCE_GROUP -n $WEBAPP_NAME"
  print_info "Vérifier App Settings manquants dans le portail Azure"
  print_info "Exécuter: ./scripts/sync-openai-key-dev06.sh pour synchroniser la clé OpenAI"
  print_info "Exécuter: ./scripts/bot-credentials-setup-dev06.sh pour configurer le bot"
else
  print_info "Exécuter les tests applicatifs: npm test"
  print_info "Procéder aux tests E2E Teams et quotas"
fi

# 7. Sortie JSON optionnelle
if $OUTPUT_JSON; then
  {
    echo '{'
    echo "  \"resourceGroup\": \"${RESOURCE_GROUP}\"," 
    echo "  \"webApp\": \"${WEBAPP_NAME}\"," 
    echo "  \"keyVault\": \"${KEY_VAULT_NAME}\"," 
    echo "  \"postgres\": \"${POSTGRES_NAME}\"," 
    echo "  \"http\": { \"root\": \"$HTTP_STATUS_MAIN\", \"health\": \"$HTTP_STATUS_HEALTH\" },"
    echo "  \"checksPassed\": $CHECKS_PASSED,"
    echo "  \"checksTotal\": $CHECKS_TOTAL,"
    echo "  \"status\": \"$STATUS_GLOBAL\","
    echo '  "results": {'
    first=true
    for k in "${!RESULTS[@]}"; do
      if $first; then first=false; else echo ','; fi
      echo -n "    \"$k\": \"${RESULTS[$k]}\""
    done
    echo ''
    echo '  }'
    echo '}'
  } > "$RESULT_JSON_TMP"
  print_header "📄 Résultats JSON enregistrés: $RESULT_JSON_TMP"
fi

print_header "================================================================="

exit 0
