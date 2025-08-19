#!/bin/bash
# ============================================================================
# bot-credentials-setup-dev06.sh
# Génère (reset) les identifiants du Bot (App Registration) et configure
# l'App Service + Key Vault + fichier env/.env.dev pour l'environnement DEV-06.
# (Ancien nom: setup-bot-credentials-dev06.sh)
#
# Prérequis:
#   - az CLI connecté (az login)
#   - Permissions pour: Bot Service (lecture), App Registration (credential reset), Key Vault (set secret), Web App (config)
#   - jq installé (apt install jq)
#
# Usage:
#   ./scripts/bot-credentials-setup-dev06.sh [options]
#
# Options:
#   -g, --resource-group <rg>    Resource group cible (default: rg-chatbottez-gpt-4-1-dev-06)
#   -b, --bot-name <name>        Nom du Bot Service (default: chatbottez-gpt41)
#   -w, --webapp-name <name>     Nom du Web App (auto-détecté si omis)
#   -k, --keyvault-name <name>   Nom du Key Vault local (auto-détecté si omis)
#       --no-reset               N'essaie pas de régénérer le secret (impossible de relire l'ancien) -> échoue si on ne peut pas créer.
#       --plain-password         Stocke le mot de passe en clair dans l'app setting (sinon Key Vault reference)
#       --env-file <path>        Fichier env à mettre à jour (default: env/.env.dev)
#       --dry-run                Affiche les actions sans les exécuter
#       --verbose                Verbose
#   -h, --help                   Aide
#
# Sorties:
#   - Affiche MICROSOFT_APP_ID et (nouveau) MICROSOFT_APP_PASSWORD
#   - Met à jour: Key Vault (secret bot-client-secret), App Service settings, env/.env.dev
# ============================================================================
set -euo pipefail

RG="rg-chatbottez-gpt-4-1-dev-06"
BOT_NAME="chatbottez-gpt41"
WEBAPP_NAME=""
KEYVAULT_NAME=""
RESET_SECRET=true
PLAIN_PASSWORD=false
ENV_FILE="env/.env.dev"
DRY_RUN=false
VERBOSE=false

log(){ echo -e "$1"; }
info(){ log "📘 $1"; }
ok(){ log "✅ $1"; }
warn(){ log "⚠️  $1"; }
err(){ log "❌ $1"; }
run(){ if $DRY_RUN; then echo "🧪 DRY-RUN: $*"; else eval "$*"; fi }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -g|--resource-group) RG="$2"; shift 2;;
    -b|--bot-name) BOT_NAME="$2"; shift 2;;
    -w|--webapp-name) WEBAPP_NAME="$2"; shift 2;;
    -k|--keyvault-name) KEYVAULT_NAME="$2"; shift 2;;
    --no-reset) RESET_SECRET=false; shift;;
    --plain-password) PLAIN_PASSWORD=true; shift;;
    --env-file) ENV_FILE="$2"; shift 2;;
    --dry-run) DRY_RUN=true; shift;;
    --verbose) VERBOSE=true; shift;;
    -h|--help) grep '^# ' "$0" | sed 's/^# //'; exit 0;;
    *) err "Argument inconnu: $1"; exit 1;;
  esac
done

command -v az >/dev/null || { err "Azure CLI requis"; exit 1; }
az account show >/dev/null 2>&1 || { err "az login requis"; exit 1; }
command -v jq >/dev/null || { err "jq requis (sudo apt install jq)"; exit 1; }

info "Configuration: RG=$RG BOT=$BOT_NAME RESET_SECRET=$RESET_SECRET PLAIN_PASSWORD=$PLAIN_PASSWORD DRY_RUN=$DRY_RUN"

# 1. Récupérer WebApp si nécessaire
if [[ -z "$WEBAPP_NAME" ]]; then
  WEBAPP_NAME=$(az webapp list -g "$RG" --query "[0].name" -o tsv 2>/dev/null || true)
  [[ -n "$WEBAPP_NAME" ]] || { err "Impossible de détecter le Web App dans $RG"; exit 1; }
fi
ok "Web App: $WEBAPP_NAME"

# 2. Récupérer Key Vault local
if [[ -z "$KEYVAULT_NAME" ]]; then
  KEYVAULT_NAME=$(az keyvault list -g "$RG" --query "[0].name" -o tsv 2>/dev/null || true)
  [[ -n "$KEYVAULT_NAME" ]] || { err "Impossible de détecter le Key Vault dans $RG"; exit 1; }
fi
ok "Key Vault: $KEYVAULT_NAME"

# 3. Récupérer MICROSOFT_APP_ID depuis le Bot Service
info "Récupération du Bot Service (msaAppId)..."
APP_ID=$(az bot show -g "$RG" -n "$BOT_NAME" --query "properties.msaAppId" -o tsv 2>/dev/null || true)
if [[ -z "$APP_ID" ]]; then
  err "Impossible de récupérer l'App ID du bot ($BOT_NAME). Vérifier le nom ou la ressource."
  exit 1
fi
ok "MICROSOFT_APP_ID = $APP_ID"

# 4. Reset / création d'un nouveau secret (client secret) dans l'App Registration
APP_PASSWORD=""
if $RESET_SECRET; then
  info "Génération d'un nouveau client secret (az ad app credential reset) ..."
  set +e
  RESET_OUTPUT=$(az ad app credential reset --id "$APP_ID" --display-name dev06-bot-secret --years 1 -o json 2>&1)
  STATUS=$?
  set -e
  if [[ $STATUS -ne 0 ]]; then
    err "Échec de la génération du secret. Sortie:\n$RESET_OUTPUT"
    if $RESET_SECRET; then
      exit 1
    fi
  else
    APP_PASSWORD=$(echo "$RESET_OUTPUT" | jq -r '.password // .')
    if [[ -z "$APP_PASSWORD" || "$APP_PASSWORD" == "null" ]]; then
      err "Secret généré introuvable dans la sortie CLI."
      exit 1
    fi
    ok "Nouveau client secret généré."
  fi
else
  err "--no-reset spécifié, mais on ne peut pas relire un secret existant. Abandon."
  exit 1
fi

# 5. Stockage du secret dans Key Vault (optionnel si PLAIN_PASSWORD)
SECRET_NAME="bot-client-secret"
if ! $PLAIN_PASSWORD; then
  info "Stockage du secret dans Key Vault ($KEYVAULT_NAME) sous '$SECRET_NAME'..."
  run "az keyvault secret set --vault-name '$KEYVAULT_NAME' --name '$SECRET_NAME' --value '$APP_PASSWORD' >/dev/null"
  ok "Secret stocké."
fi

# 6. Mise à jour des App Settings du Web App
info "Mise à jour des App Settings..."
if $PLAIN_PASSWORD; then
  PW_VALUE="$APP_PASSWORD"
else
  PW_VALUE="@Microsoft.KeyVault(VaultName=$KEYVAULT_NAME;SecretName=$SECRET_NAME)"
fi
run "az webapp config appsettings set -g '$RG' -n '$WEBAPP_NAME' --settings MICROSOFT_APP_ID='$APP_ID' MICROSOFT_APP_PASSWORD='$PW_VALUE' >/dev/null"
ok "App Settings mis à jour."

# 7. Mise à jour du fichier env (.env.dev)
if [[ -f "$ENV_FILE" ]]; then
  info "Mise à jour du fichier $ENV_FILE"
  if $DRY_RUN; then
    echo "🧪 DRY-RUN: (Mise à jour MICROSOFT_APP_ID / MICROSOFT_APP_PASSWORD)"
  else
    grep -q '^MICROSOFT_APP_ID=' "$ENV_FILE" && sed -i "s|^MICROSOFT_APP_ID=.*|MICROSOFT_APP_ID=$APP_ID|" "$ENV_FILE" || echo "MICROSOFT_APP_ID=$APP_ID" >> "$ENV_FILE"
    if $PLAIN_PASSWORD; then
      grep -q '^MICROSOFT_APP_PASSWORD=' "$ENV_FILE" && sed -i "s|^MICROSOFT_APP_PASSWORD=.*|MICROSOFT_APP_PASSWORD=$APP_PASSWORD|" "$ENV_FILE" || echo "MICROSOFT_APP_PASSWORD=$APP_PASSWORD" >> "$ENV_FILE"
    else
      grep -q '^MICROSOFT_APP_PASSWORD=' "$ENV_FILE" && sed -i "s|^MICROSOFT_APP_PASSWORD=.*|MICROSOFT_APP_PASSWORD=$PW_VALUE|" "$ENV_FILE" || echo "MICROSOFT_APP_PASSWORD=$PW_VALUE" >> "$ENV_FILE"
    fi
  fi
  ok "Fichier env mis à jour."
else
  warn "Fichier $ENV_FILE introuvable - ignoré."
fi

# 8. Redémarrage du Web App
info "Redémarrage du Web App..."
run "az webapp restart -g '$RG' -n '$WEBAPP_NAME' >/dev/null"
ok "Web App redémarré."

# 9. Récapitulatif
cat <<EOF
======================================================
Bot Credentials Setup (DEV-06) Terminé
------------------------------------------------------
MICROSOFT_APP_ID      : $APP_ID
MICROSOFT_APP_PASSWORD: (masqué)
Stockage secret KV    : $( $PLAIN_PASSWORD && echo 'Non (en clair dans App Setting)' || echo "$KEYVAULT_NAME/$SECRET_NAME" )
Web App               : $WEBAPP_NAME
Key Vault             : $KEYVAULT_NAME
Env File              : $ENV_FILE
Dry-Run               : $DRY_RUN
======================================================
⚠️  Le mot de passe NE PEUT PAS être relu ultérieurement. Conservez-le si vous l'avez utilisé en clair.
EOF

if $PLAIN_PASSWORD; then
  echo "Mot de passe (plain) : $APP_PASSWORD"
fi
