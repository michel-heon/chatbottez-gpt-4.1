# 📋 Guide d'utilisation du Makefile

Ce document décrit l'utilisation du Makefile pour orchestrer le déploiement et la configuration du système Microsoft Marketplace Quota Management.

## 🎯 Vue d'ensemble

Le Makefile fournit une interface unifiée pour :
- **Configuration initiale** (environnement, base de données, marketplace)
- **Déploiement Azure** (infrastructure, APIM, Key Vault)
- **Configuration post-déploiement** (policies, secrets, connexions)
- **Validation et tests** (15 tests de validation complète)

## 🚀 Commandes principales

### Déploiement complet

```bash
# Processus complet automatisé (recommandé pour nouveaux déploiements)
make all
```

Cette commande exécute dans l'ordre :
1. `make setup` - Configuration initiale
2. `make deploy` - Déploiement Azure
3. `make configure` - Configuration post-déploiement
4. `make validate` - Validation complète

### Commandes par étapes

```bash
# 1. Configuration initiale (prérequis)
make setup

# 2. Déploiement infrastructure Azure
make deploy

# 3. Configuration des services déployés
make configure

# 4. Validation du système complet
make validate
```

## 🔧 Commandes de développement

### Configuration rapide pour développement

```bash
# Configuration minimale pour développement local
make dev-setup

# Équivaut à : make environment + make test-config
```

### Tests et diagnostics

```bash
# Tester la configuration
make test-config

# Tester la connexion base de données
make test-db

# Afficher le statut du système
make status

# Vérifier les dépendances
make check-deps

# Informations sur l'architecture
make info
```

## 📋 Commandes individuelles

### Configuration par composants

```bash
# Configuration environnement seulement
make environment

# Configuration base de données seulement  
make database

# Configuration Marketplace API seulement
make marketplace
```

## 🧹 Maintenance

```bash
# Nettoyer les fichiers temporaires
make clean

# Nettoyer les scripts obsolètes
make scripts-cleanup
```

## 🏭 Déploiement production

```bash
# Déploiement production avec validation complète
make prod-deploy

# Équivaut à : make setup + make deploy + make configure + make validate
```

## 🔍 Diagnostics et help

```bash
# Afficher l'aide complète
make help

# Statut détaillé du système
make status

# Informations architecture
make info
```

## 📊 Structure des scripts appelés

Le Makefile orchestre les scripts suivants (nomenclature `<objet>-<action>.sh`) :

### Scripts de configuration (setup)
- `environment-setup.sh` - Configuration environnement de développement
- `database-setup.sh` - Configuration PostgreSQL et schémas
- `marketplace-setup.sh` - Configuration API Marketplace

### Scripts de déploiement (deploy)
- `azure-deploy.sh` - Déploiement infrastructure Azure (APIM, Key Vault, PostgreSQL)

### Scripts de configuration (configure)
- `azure-configure.sh` - Configuration post-déploiement (policies, secrets)

### Scripts de validation (validate)
- `deployment-validate.sh` - Validation complète (15 tests)
- `config-test.sh` - Tests configuration seulement

### Scripts utilitaires
- `config-loader.sh` - Chargement configuration centralisée
- `scripts-cleanup.sh` - Nettoyage scripts obsolètes

## ⚙️ Variables d'environnement

Le Makefile utilise la configuration centralisée :

```bash
# Configuration principale
CONFIG_DIR := config              # Répertoire config/azure.env
SCRIPTS_DIR := scripts           # Répertoire des scripts

# Fichiers de configuration attendus
config/azure.env                 # Configuration Azure centralisée
.env.local                      # Variables environnement application
marketplace.env                 # Configuration Marketplace (optionnel)
```

## 🎨 Codes couleur

Le Makefile utilise des couleurs pour améliorer la lisibilité :
- **🔵 CYAN** : En-têtes et sections
- **🟢 GREEN** : Succès et commandes
- **🟡 YELLOW** : Avertissements et informations
- **🔴 RED** : Erreurs

## 🛠️ Prérequis

Avant d'utiliser le Makefile, assurez-vous d'avoir :

### Outils système
- **Azure CLI** : `az login` effectué
- **Node.js** : Version 18, 20 ou 22
- **npm** : Pour les dépendances Node.js
- **Git** : Pour le contrôle de version
- **WSL/Bash** : Pour l'exécution des scripts

### Vérification des prérequis
```bash
# Vérifier automatiquement toutes les dépendances
make check-deps
```

## 🔄 Flux de travail recommandé

### Premier déploiement

```bash
# 1. Vérifier les prérequis
make check-deps

# 2. Déploiement complet
make all

# 3. Vérifier le statut
make status
```

### Développement

```bash
# Configuration rapide
make dev-setup

# Tests réguliers
make test-config
make test-db
```

### Production

```bash
# Déploiement production
make prod-deploy

# Validation continue
make validate
```

## 🐛 Dépannage

### Erreurs communes

1. **Azure CLI non connecté**
   ```bash
   az login
   make status  # Vérifier la connexion
   ```

2. **Scripts non exécutables**
   ```bash
   chmod +x scripts/*.sh
   ```

3. **Configuration manquante**
   ```bash
   make setup  # Reconfigurer
   ```

4. **Échec de validation**
   ```bash
   make validate  # Voir les détails des erreurs
   make clean     # Nettoyer et recommencer
   ```

### Logs et debugging

```bash
# Statut détaillé
make status

# Tests individuels
make test-config
make test-db

# Informations système
make info
```

## 📚 Documentation associée

- **Architecture** : `docs/architecture-diagram.drawio`
- **Déploiement** : `DEPLOYMENT_SUMMARY.md`
- **Migration** : `MIGRATION_COMPLETED.md`
- **Quotas** : `README_QUOTA.md`
- **Marketplace** : `docs/MARKETPLACE_INTEGRATION.md`

## 🎯 Exemples d'utilisation

### Nouveau projet
```bash
git clone <repository>
cd <project>
make all           # Déploiement complet
npm run dev        # Démarrer l'application
```

### Développement quotidien
```bash
make dev-setup     # Configuration rapide
make test-config   # Vérifier config
npm run dev        # Développer
```

### Mise en production
```bash
make prod-deploy   # Déploiement production
make validate      # Validation complète
```

## 💡 Conseils

1. **Toujours commencer par** : `make help`
2. **Vérifier le statut** : `make status` avant déploiement
3. **Tester régulièrement** : `make test-config` pendant développement
4. **Validation complète** : `make validate` avant production
5. **Nettoyer régulièrement** : `make clean` pour maintenance

---

📝 **Note** : Ce Makefile suit la nomenclature `<objet>-<action>.sh` basée sur le diagramme d'architecture et fournit une interface unifiée pour tous les workflows de déploiement et configuration.
