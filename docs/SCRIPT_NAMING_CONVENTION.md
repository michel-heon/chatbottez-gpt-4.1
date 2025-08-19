# 🧷 Convention de Nommage des Scripts (`scripts/`)

Cette convention formalise la règle: **`<objet>-<action>.sh`** (et non `action-objet`).

Objectifs:
- Lecture immédiate: on voit d'abord la ressource ou le domaine concerné.
- Regroupement logique naturel (ls, autocomplétion) par objet.
- Alignement avec les artefacts d'architecture (diagrammes & Bicep).
- Réduction des renamings futurs et homogénéité Makefile.

---
## 1. Structure Générale
```
<objet>(-scope-optionnel)-<action>(-qualificateur-optionnel).sh
```

| Élément | Description | Exemples |
|---------|-------------|----------|
| objet | Domaine / ressource primaire | `bot`, `database`, `infra`, `app`, `openai`, `kv`, `apim` |
| scope optionnel | Environnement, segment ou variante | `dev06`, `shared`, `local` |
| action | Verbe principal au présent infinitif sans préfixe `do` | `deploy`, `setup`, `purge`, `sync`, `status`, `validate` |
| qualificateur optionnel | Précision | `full`, `credentials`, `schema`, `test` |

Ordre strict: OBJET → (SCOPE) → ACTION → (QUALIFICATEUR).

---
## 2. Exemples Conformes
| Correct | Raison |
|---------|-------|
| `bot-credentials-setup-dev06.sh` | Objet `bot` mis en avant, action `setup` sur credentials, scope `dev06` |
| `infra-deploy-dev06.sh` | Déploiement infra ciblé dev06 |
| `database-setup-local.sh` | Prépare la base locale |
| `openai-key-sync-dev06.sh` | Sync clé OpenAI vers dev06 |
| `apim-purge-dev06.sh` | Purge APIM soft-deleted (scope dev06) |

---
## 3. Exemples Incorrects
| Incorrect | Correction |
|-----------|-----------|
| `setup-bot-credentials-dev06.sh` | `bot-credentials-setup-dev06.sh` |
| `deploy-infra-dev06.sh` | `infra-deploy-dev06.sh` |
| `sync-openai-dev06-key.sh` | `openai-key-sync-dev06.sh` |
| `dev06-deploy-infra.sh` | `infra-deploy-dev06.sh` |

---
## 4. Règles de Style
- Minuscules uniquement.
- Séparateur unique: `-` (pas d'underscore).
- Pas de double tiret `--`.
- Verbes courts et cohérents: `deploy`, `setup`, `purge`, `sync`, `migrate`, `reset`, `status`, `validate`.
- Un seul verbe par script (sinon subdiviser ou wrapper via Makefile).
- Éviter `create` si `setup` couvre provisioning + configuration.

---
## 5. Mapping Ressources ↔ Objets
| Ressource / Domaine | Préfixe `objet` |
|---------------------|-----------------|
| Bot Service / App Registration | `bot` |
| Infrastructure globale Bicep | `infra` |
| Base de données PostgreSQL | `database` |
| Application (code / runtime) | `app` |
| Azure OpenAI / clé | `openai` |
| Key Vault opérations spécifiques | `kv` |
| API Management | `apim` |
| Scripts transverses nettoyage | `cleanup` (exception contrôlée) |

> Exception acceptée: scripts historiques utilitaires (`cleanup-before-push.sh`) conservés jusqu'à dépréciation.

---
## 6. Processus de Renommage
1. Créer le nouveau fichier avec le nom conforme.
2. Transformer l'ancien en wrapper temporaire:
   ```bash
   #!/bin/bash
   echo "[DEPRECATED] Utiliser: ./scripts/bot-credentials-setup-dev06.sh" >&2
   exec "$(dirname "$0")/bot-credentials-setup-dev06.sh" "$@"
   ```
3. Mettre à jour Makefile, docs, CI.
4. Après 2 versions mineures: supprimer le wrapper.

---
## 7. Validation Automatique (Suggestion)
Ajouter un job (Makefile ou CI) :
```bash
#!/usr/bin/env bash
invalid=$(ls scripts/*.sh | grep -Ev '(^scripts/(cleanup|README)|/[a-z0-9]+(-[a-z0-9]+)*-[a-z]+(-[a-z0-9]+)*\.sh$)')
if [[ -n "$invalid" ]]; then
  echo "Non conforme:\n$invalid"; exit 1
fi
```

---
## 8. Intégration Makefile
Toujours appeler via cibles abstraites (`make bot-credentials-setup-dev06`) plutôt qu'en dur, pour permettre refactor interne sans rupture.

---
## 9. Historique
- 2025-08-19: Formalisation et renommage `setup-bot-credentials-dev06.sh` → `bot-credentials-setup-dev06.sh`.

---
## 10. Résumé TL;DR
```
Pattern: <objet>-<action>.sh (+ segments additionnels avant l'action pour précision)
Mettre l'objet d'abord. Un verbe clair. Minuscules. Tirets simples.
```

---
Mainteneur: Architecture & Tooling
