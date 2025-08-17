#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script: marketplace-api-key.sh
# Objet : Créer (ou réutiliser) une app Entra ID (service principal) et obtenir
#         un jeton OAuth2 pour les API Marketplace/Partner Center via Azure CLI.
# Auteur: Michel Héon PhD: Cotechnoe inc. (c) 2025; pour JAF Perma 2.0
# -----------------------------------------------------------------------------
# Prérequis:
#   - Azure CLI installé et connecté: az login
#   - Droits pour créer une App/Service Principal dans le tenant (si -C)
# -----------------------------------------------------------------------------
# Options:
#   -n  Nom de l'application (par défaut: mktp-api-$(date +%Y%m%d%H%M%S))
#   -t  TENANT_ID (si omis: détecté via az)
#   -i  CLIENT_ID existant (pour réutiliser une app)
#   -x  CLIENT_SECRET existant (sinon le script le génère si -C)
#   -S  Scope OAuth2 (défaut: https://marketplaceapi.microsoft.com/.default)
#   -P  Scope prédéfini Partner Center: https://api.partnercenter.microsoft.com/.default
#   -C  Créer l'application/secret si non existants
#   -o  Fichier .env de sortie (défaut: ./marketplace.env)
#   -v  Verbosité (0=silence,1=erreurs,2=warn,3=info-min,4=info,5=debug) [def:4]
#   -h  Aide
# -----------------------------------------------------------------------------

set -euo pipefail

# ------------------- Journalisation -------------------
VERBOSITY=4
info()  { [[ ${VERBOSITY} -ge 4 ]] && echo "[INFO] $*"; }
infom() { [[ ${VERBOSITY} -ge 3 ]] && echo "[INFO] $*"; }
warn()  { [[ ${VERBOSITY} -ge 2 ]] && echo "[WARN] $*" 1>&2; }
error() { echo "[ERROR] $*" 1>&2; }
debug() { [[ ${VERBOSITY} -ge 5 ]] && echo "[DEBUG] $*"; }

# ------------------- Valeurs par défaut -------------------
APP_NAME="mktp-api-$(date +%Y%m%d%H%M%S)"
TENANT_ID=""
CLIENT_ID=""
CLIENT_SECRET=""
SCOPE="https://marketplaceapi.microsoft.com/.default"
CREATE_APP=0
ENV_OUT="./marketplace.env"

usage() {
  cat <<EOF
Usage: $0 [-n APP_NAME] [-t TENANT_ID] [-i CLIENT_ID] [-x CLIENT_SECRET] \\
          [-S SCOPE] [-P] [-C] [-o ENV_FILE] [-v N] [-h]

Exemples:
  # Créer app + secret et obtenir un jeton pour Azure Marketplace
  $0 -C -n "cotechnoe-mktp" -o marketplace.env

  # Réutiliser une app existante (CLIENT_ID/SECRET connus)
  $0 -i <appId> -x <secret> -S "https://marketplaceapi.microsoft.com/.default"

  # Utiliser Partner Center comme scope
  $0 -C -P

Scopes prédéfinis:
  - Azure Marketplace APIs:   https://marketplaceapi.microsoft.com/.default
  - Partner Center API:       https://api.partnercenter.microsoft.com/.default
EOF
}

# ------------------- getopts -------------------
while getopts ":n:t:i:x:S:PCo:v:h" opt; do
  case $opt in
    n) APP_NAME="$OPTARG" ;;
    t) TENANT_ID="$OPTARG" ;;
    i) CLIENT_ID="$OPTARG" ;;
    x) CLIENT_SECRET="$OPTARG" ;;
    S) SCOPE="$OPTARG" ;;
    P) SCOPE="https://api.partnercenter.microsoft.com/.default" ;;
    C) CREATE_APP=1 ;;
    o) ENV_OUT="$OPTARG" ;;
    v) VERBOSITY="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) error "Option invalide: -$OPTARG"; usage; exit 2 ;;
    :)  error "Option -$OPTARG requiert une valeur"; usage; exit 2 ;;
  esac
done

# ------------------- Vérifs préliminaires -------------------
if ! command -v az >/dev/null 2>&1; then
  error "Azure CLI (az) n'est pas installé."
  exit 1
fi

# Vérifier la connexion
if ! az account show >/dev/null 2>&1; then
  warn "Non connecté à Azure CLI. Tentative de connexion..."
  az login >/dev/null
fi

# Déterminer TENANT_ID si absent
if [[ -z "${TENANT_ID}" ]]; then
  TENANT_ID=$(az account show --query tenantId -o tsv)
  infom "TENANT_ID détecté: ${TENANT_ID}"
fi

# ------------------- Création / réutilisation App -------------------
if [[ ${CREATE_APP} -eq 1 ]]; then
  info "Création d'une application/service principal: ${APP_NAME}"

  # Remarque: create-for-rbac crée automatiquement SP + secret (password)
  # Convient pour flux client credentials. Les permissions API spécifiques
  # (ex: Partner Center) devront être accordées séparément par un admin.
  SP_JSON=$(az ad sp create-for-rbac --name "${APP_NAME}" --skip-assignment --years 2 -o json)
  CLIENT_ID=$(echo "${SP_JSON}" | jq -r '.appId')
  CLIENT_SECRET=$(echo "${SP_JSON}" | jq -r '.password')
  infom "CLIENT_ID créé: ${CLIENT_ID}"

else
  # Réutilisation d'une app existante: vérifier présences
  if [[ -z "${CLIENT_ID}" ]]; then
    error "CLIENT_ID requis si non -C."
    exit 2
  fi
  if [[ -z "${CLIENT_SECRET}" ]]; then
    warn "CLIENT_SECRET manquant. Tentative de régénération du secret..."
    # Régénérer un secret si l'utilisateur a les droits sur l'app
    CLIENT_SECRET=$(az ad app credential reset --id "${CLIENT_ID}" --years 2 --query password -o tsv) || {
      error "Impossible de régénérer le secret. Fournir -x CLIENT_SECRET."
      exit 1
    }
    info "Nouveau CLIENT_SECRET généré."
  fi
fi

# ------------------- Obtenir un jeton OAuth2 -------------------
info "Obtention d'un jeton OAuth2 (flux client credentials)..."
# Utilise l'endpoint v2 (scope = <ressource>/.default)
ACCESS_TOKEN_JSON=$(az account get-access-token \
  --tenant "${TENANT_ID}" \
  --client-id "${CLIENT_ID}" \
  --client-secret "${CLIENT_SECRET}" \
  --scope "${SCOPE}" \
  -o json)

ACCESS_TOKEN=$(echo "${ACCESS_TOKEN_JSON}" | jq -r '.accessToken')
EXPIRES_ON=$(echo "${ACCESS_TOKEN_JSON}" | jq -r '.expiresOn')

if [[ -z "${ACCESS_TOKEN}" || "${ACCESS_TOKEN}" == "null" ]]; then
  error "Échec de récupération du jeton. Vérifier le scope et les consentements d'API."
  exit 1
fi

# ------------------- Écrire le .env -------------------
cat > "${ENV_OUT}" <<EOF
# Variables API Marketplace / Partner Center
TENANT_ID=${TENANT_ID}
CLIENT_ID=${CLIENT_ID}
CLIENT_SECRET=${CLIENT_SECRET}
SCOPE=${SCOPE}
# Jeton courant (expirera automatiquement)
MARKETPLACE_API_TOKEN=${ACCESS_TOKEN}
MARKETPLACE_TOKEN_EXPIRES_ON=${EXPIRES_ON}
EOF

info "Fichier .env écrit: ${ENV_OUT}"

# ------------------- Affichage résumé + exemple cURL -------------------
cat <<EOF

Résumé:
  TENANT_ID      = ${TENANT_ID}
  CLIENT_ID      = ${CLIENT_ID}
  SCOPE          = ${SCOPE}
  TOKEN_EXPIRES  = ${EXPIRES_ON}

Exemple cURL (remplacez l'URL selon l'API ciblée):
  export AUTH="Authorization: Bearer ${ACCESS_TOKEN}"
  # Azure Marketplace Fulfillment/Metering (exemple générique):
  curl -sS -H "\$AUTH" -H "Content-Type: application/json" \\
       https://marketplaceapi.microsoft.com/api/saas/subscriptions?api-version=2022-09-15

  # Partner Center (exemple générique):
  curl -sS -H "\$AUTH" -H "Content-Type: application/json" \\
       https://api.partnercenter.microsoft.com/v1/customers

Notes:
  - Si l'appel renvoie 401/403, un consentement admin ou des permissions API
    spécifiques sont requis côté Entra ID / Partner Center.
  - Vous pouvez relancer ce script pour régénérer un secret (-C) ou changer de SCOPE (-S/-P).
EOF
