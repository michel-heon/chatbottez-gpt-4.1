#!/bin/bash
# Deprecated wrapper. Nouveau nom: bot-credentials-setup-dev06.sh
# Cette enveloppe sera supprimée prochainement.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[DEPRECATED] Utiliser: ./scripts/bot-credentials-setup-dev06.sh" >&2
exec "${SCRIPT_DIR}/bot-credentials-setup-dev06.sh" "$@"
