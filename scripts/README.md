# Scripts

Ce dossier contient les scripts utilitaires pour le projet Microsoft 365 Agents ChatBot GPT-4.1.

## Scripts disponibles

### m365-provisioning.sh

Script de provisionnement pour Microsoft 365 Agents qui encapsule toute la logique de provisionnement Azure.

**Usage :**
```bash
# Provisionnement simple
./scripts/m365-provisioning.sh [ENVIRONMENT]

# Provisionnement avec options
./scripts/m365-provisioning.sh [ENVIRONMENT] [FORCE] [CLEAN]
```

**Paramètres :**
- `ENVIRONMENT` : Environnement cible (dev|local|playground) [défaut: dev]
- `FORCE` : Mode force pour réinstaller Bicep (true|false) [défaut: false]
- `CLEAN` : Mode nettoyage pour vider les caches (true|false) [défaut: false]

**Exemples :**
```bash
# Provisionnement dev standard
./scripts/m365-provisioning.sh dev

# Provisionnement force avec réinstallation Bicep
./scripts/m365-provisioning.sh dev true

# Provisionnement avec nettoyage des caches
./scripts/m365-provisioning.sh dev false true

# Provisionnement playground complet (force + clean)
./scripts/m365-provisioning.sh playground true true

# Aide
./scripts/m365-provisioning.sh --help
```

**Fonctionnalités :**
- ✅ Vérification automatique des prérequis
- ✅ Validation des fichiers d'environnement
- ✅ Installation automatique de Bicep CLI
- ✅ Gestion des caches TeamsFx
- ✅ Mode debug avec informations détaillées
- ✅ Support pour tous les environnements (dev/local/playground)
- ✅ Gestion des erreurs avec logs colorés

## Utilisation depuis le Makefile

Les scripts peuvent être exécutés via le Makefile :

```bash
# Provisionnement standard
make provision ENV=dev

# Provisionnement force
make provision-force ENV=dev

# Provisionnement avec nettoyage
make provision-clean ENV=dev

# Provisionnement avec debug
make provision-debug ENV=dev

# Exécution directe du script
make script-provision ENV=dev
make script-provision ENV=dev ARGS="true false"

# Aide du script
make script-help

# Liste des scripts
make scripts-list
```

## Développement

### Ajout de nouveaux scripts

1. Créer le script dans le dossier `scripts/`
2. Rendre le script exécutable : `chmod +x scripts/nom-du-script.sh`
3. Ajouter la documentation dans ce README
4. Optionnellement, ajouter des règles Makefile pour faciliter l'usage

### Conventions

- Noms de fichiers : `kebab-case.sh`
- Shebang : `#!/bin/bash`
- Options : `set -e` pour arrêter sur erreur
- Logs colorés avec les variables GREEN, YELLOW, RED, NC
- Fonctions pour la réutilisabilité
- Validation des paramètres
- Aide avec `--help`

### Structure type d'un script

```bash
#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_usage() {
    echo "Usage: $0 [options]"
    # ... help text
}

main() {
    # Main logic
}

# Execute if not sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
```
