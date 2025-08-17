# 📚 Index Documentation - Microsoft Marketplace Quota Management

## 🎯 Guide de Démarrage Rapide

### Pour les nouveaux utilisateurs
1. 📖 **[README.md](../README.md)** - Vue d'ensemble et démarrage rapide
2. 🚀 **[MAKEFILE_GUIDE.md](MAKEFILE_GUIDE.md)** - Guide complet du Makefile (RECOMMANDÉ)
3. ✅ **[TODO.md](../TODO.md)** - État actuel et prochaines étapes

### Pour le déploiement
1. 🏗️ **[DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)** - Résumé du déploiement Azure
2. 🔄 **[MIGRATION_COMPLETED.md](MIGRATION_COMPLETED.md)** - Migration PowerShell → Bash
3. 📋 **[azure-components.md](azure-components.md)** - Liste des composants Azure

---

## 📁 Documentation par Catégorie

### 🏗️ Infrastructure et Déploiement

| Document | Description | Statut |
|----------|-------------|---------|
| **[MAKEFILE_GUIDE.md](MAKEFILE_GUIDE.md)** | Guide complet du Makefile avec exemples | ✅ À jour |
| **[DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)** | Résumé du déploiement infrastructure Azure | ✅ À jour |
| **[azure-components.md](azure-components.md)** | Composants Azure déployés et à venir | ✅ À jour |
| **[INSTALL_POSTGRESQL.md](INSTALL_POSTGRESQL.md)** | Guide PostgreSQL (local vs Azure) | ✅ À jour |

### 🔧 Configuration et Migration

| Document | Description | Statut |
|----------|-------------|---------|
| **[MIGRATION_COMPLETED.md](MIGRATION_COMPLETED.md)** | Migration et standardisation complète | ✅ À jour |
| **[TODO.md](../TODO.md)** | État actuel et tâches restantes | ✅ À jour |
| **[CHANGELOG.md](CHANGELOG.md)** | Historique des modifications récentes | ✅ À jour |

### 📋 Fonctionnalités et Business Logic

| Document | Description | Statut |
|----------|-------------|---------|
| **[README_QUOTA.md](README_QUOTA.md)** | Système de quota et Marketplace | ✅ À jour |
| **[SYSTEM_PROMPT.md](SYSTEM_PROMPT.md)** | Configuration IA et prompts | ✅ À jour |

### 📐 Architecture

| Document | Description | Statut |
|----------|-------------|---------|
| **[architecture-diagram.drawio](architecture-diagram.drawio)** | Diagramme d'architecture système | ✅ Référence |
| **[azure-components.md](azure-components.md)** | Mapping des composants Azure | ✅ À jour |

---

## 🚀 Workflows Recommandés

### Premier Déploiement
```bash
# 1. Lire la documentation
cat README.md
cat docs/MAKEFILE_GUIDE.md

# 2. Vérifier les prérequis
make check-deps

# 3. Déploiement complet
make all

# 4. Vérifier le statut
make status
```

### Développement Quotidien
```bash
# Configuration rapide
make dev-setup

# Tests réguliers
make test-config
make test-db

# Statut du système
make status
```

### Maintenance
```bash
# Voir l'aide
make help

# Nettoyer
make clean

# Valider l'infrastructure
make validate
```

---

## 📊 Statut des Documents

### ✅ À jour (Dernière mise à jour: 2025-08-17)
- **README.md** - Instructions Makefile prioritaires
- **MAKEFILE_GUIDE.md** - Guide complet nouvellement créé
- **DEPLOYMENT_SUMMARY.md** - Infrastructure complète documentée
- **MIGRATION_COMPLETED.md** - Migration et standardisation
- **TODO.md** - État actuel avec infrastructure déployée
- **README_QUOTA.md** - Workflows Makefile ajoutés
- **INSTALL_POSTGRESQL.md** - Azure PostgreSQL prioritaire
- **azure-components.md** - Liste complète des composants
- **CHANGELOG.md** - Historique des modifications

### ⚠️ À vérifier/mettre à jour
- **DEPLOYMENT.md** - Possiblement obsolète (vérifier vs DEPLOYMENT_SUMMARY.md)

### 📋 Documentation technique
- **infra/botRegistration/readme.md** - Documentation Azure Bot Service
- **architecture-diagram.drawio** - Diagramme de référence

---

## 🔍 Recherche Rapide

### Commandes Makefile
- **Aide** : `make help`
- **Déploiement** : `make all`
- **Tests** : `make validate`
- **Statut** : `make status`

### Fichiers de Configuration
- **Azure** : `config/azure.env`
- **Application** : `.env.local`
- **Marketplace** : `marketplace.env`

### Scripts
- **Scripts directory** : `scripts/`
- **Nomenclature** : `<objet>-<action>.sh`
- **Configuration** : Tous sourcent `config/azure.env`

### Infrastructure
- **Resource Group** : `rg-chatbottez-gpt-4-1-dev-02`
- **PostgreSQL** : Azure Flexible Server PostgreSQL 16
- **APIM** : Policies quota configurées
- **Key Vault** : Secrets management

---

## 💡 Conseils d'Utilisation

### Pour les développeurs
1. **Commencer par** : `make help` pour voir toutes les options
2. **Configuration rapide** : `make dev-setup` pour développement local
3. **Tests réguliers** : `make test-config` pendant développement

### Pour le déploiement
1. **Prérequis** : `make check-deps` avant tout déploiement
2. **Déploiement complet** : `make all` pour nouveau projet
3. **Validation** : `make validate` pour vérifier infrastructure

### Pour la maintenance
1. **Statut** : `make status` pour vue d'ensemble
2. **Nettoyage** : `make clean` pour maintenance
3. **Documentation** : Ce fichier pour navigation

---

## 📞 Support

### En cas de problème
1. **Statut système** : `make status`
2. **Tests diagnostiques** : `make validate`
3. **Logs** : Vérifier sortie des commandes make
4. **Documentation** : Consulter `docs/MAKEFILE_GUIDE.md`

### Ressources externes
- **Azure CLI** : [Documentation officielle](https://docs.microsoft.com/en-us/cli/azure/)
- **Microsoft Marketplace** : [Partner Center Documentation](https://docs.microsoft.com/en-us/azure/marketplace/)
- **PostgreSQL** : [Documentation officielle](https://www.postgresql.org/docs/)
