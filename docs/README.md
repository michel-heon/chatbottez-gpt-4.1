# 📚 Documentation ChatBottez GPT-4.1 - Microsoft Marketplace Quota Management

## 🎯 Vue d'ensemble du Projet

**ChatBottez GPT-4.1** est un système de chatbot Teams AI avec gestion de quotas intégrée au Microsoft Commercial Marketplace. Le projet implémente une architecture complète du client Teams jusqu'à l'infrastructure Azure, avec intelligence artificielle via Azure OpenAI.

**Version actuelle** : `v1.7.0-step6-application-deployment`  
**Status** : Infrastructure Azure déployée ✅ - Application déployée ✅ - Configuration finale ⚠️

## 🚀 Guide de Démarrage Rapide

### Pour les nouveaux utilisateurs
1. 📖 **[README.md](../README.md)** - Vue d'ensemble et quick start
2. 🚀 **[MAKEFILE_GUIDE.md](MAKEFILE_GUIDE.md)** - Guide complet du Makefile (RECOMMANDÉ)
3. ✅ **[TODO.md](../TODO.md)** - État actuel et prochaines étapes
4. 🏗️ **[COMPLETE_ARCHITECTURE.md](COMPLETE_ARCHITECTURE.md)** - 🆕 Architecture complète end-to-end

### Pour le déploiement
1. 🏗️ **[DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)** - Résumé du déploiement Azure (15/15 ✅)
2. � **[AZURE_INFRASTRUCTURE.md](AZURE_INFRASTRUCTURE.md)** - 🆕 Infrastructure Azure déployée
3. �🔄 **[MIGRATION_COMPLETED.md](MIGRATION_COMPLETED.md)** - Migration PowerShell → Bash

---

## � Diagrammes d'Architecture

### 🆕 Nouveaux Diagrammes Complets
| Diagramme | Description | Format |
|-----------|-------------|--------|
| **[complete-architecture-diagram.drawio](complete-architecture-diagram.drawio)** | 🆕 **Architecture complète Client-to-Infrastructure** | Draw.io |
| **[azure-infrastructure-diagram.drawio](azure-infrastructure-diagram.drawio)** | 🆕 **Infrastructure Azure déployée** | Draw.io |
| **[COMPLETE_ARCHITECTURE.md](COMPLETE_ARCHITECTURE.md)** | 🆕 **Documentation architecture complète** | Markdown |
| **[AZURE_INFRASTRUCTURE.md](AZURE_INFRASTRUCTURE.md)** | 🆕 **Documentation infrastructure Azure** | Markdown |

### Diagrammes Existants
| Diagramme | Description | Status |
|-----------|-------------|--------|
| **[architecture-diagram.drawio](architecture-diagram.drawio)** | Architecture système original (référence) | ✅ Historique |

---

## � Documentation par Catégorie

### 🏗️ Infrastructure et Déploiement

| Document | Description | Statut |
|----------|-------------|---------|
| **[AZURE_INFRASTRUCTURE.md](AZURE_INFRASTRUCTURE.md)** | 🆕 **Infrastructure Azure complète** | ✅ Nouveau |
| **[BICEP_ARCHITECTURE.md](BICEP_ARCHITECTURE.md)** | 🆕 **Architecture des templates Bicep** | ✅ Nouveau |
| **[DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)** | Résumé déploiement (15/15 validations ✅) | ✅ À jour |
| **[MAKEFILE_GUIDE.md](MAKEFILE_GUIDE.md)** | Guide complet du Makefile avec exemples | ✅ À jour |
| **[azure-components.md](azure-components.md)** | Composants Azure déployés | ✅ À jour |
| **[INSTALL_POSTGRESQL.md](INSTALL_POSTGRESQL.md)** | Guide PostgreSQL (local vs Azure) | ✅ À jour |

### 🎯 Architecture Complète

| Document | Description | Statut |
|----------|-------------|---------|
| **[COMPLETE_ARCHITECTURE.md](COMPLETE_ARCHITECTURE.md)** | 🆕 **Architecture end-to-end complète** | ✅ Nouveau |
| **[complete-architecture-diagram.drawio](complete-architecture-diagram.drawio)** | 🆕 **Diagramme client-to-infrastructure** | ✅ Nouveau |
| **[azure-infrastructure-diagram.drawio](azure-infrastructure-diagram.drawio)** | 🆕 **Diagramme infrastructure Azure** | ✅ Nouveau |

### � Configuration et Migration

| Document | Description | Statut |
|----------|-------------|---------|
| **[MIGRATION_COMPLETED.md](MIGRATION_COMPLETED.md)** | Migration PowerShell → Bash complète | ✅ À jour |
| **[TODO.md](../TODO.md)** | État actuel et tâches restantes | ✅ À jour |
| **[CHANGELOG.md](CHANGELOG.md)** | Historique des modifications | ✅ À jour |
| **[STATUS.md](STATUS.md)** | Statut détaillé du projet | ✅ À jour |

### 📋 Fonctionnalités et Business Logic

| Document | Description | Statut |
|----------|-------------|---------|
| **[README_QUOTA.md](README_QUOTA.md)** | Système de quota et Marketplace | ✅ À jour |
| **[SYSTEM_PROMPT.md](SYSTEM_PROMPT.md)** | Configuration IA et prompts | ✅ À jour |
| **[DEPLOYMENT.md](DEPLOYMENT.md)** | Guide de déploiement détaillé | ⚠️ À vérifier |

---

## 🚀 Workflows Recommandés

### 🆕 Premier Déploiement Complet
```bash
# 1. Validation des prérequis
wsl make validate

# 2. Déploiement infrastructure Azure
wsl make deploy

# 3. Configuration post-déploiement
wsl make configure

# 4. Vérification finale
wsl make status
```

### 👨‍💻 Développement Local
```bash
# Configuration rapide développement
wsl make dev-setup

# Tests et validation
wsl make test-config
wsl make test-db

# Monitoring du statut
wsl make status
```

### 🔧 Maintenance et Monitoring
```bash
# Voir toutes les commandes disponibles
wsl make help

# Validation complète (15 tests)
wsl make validate

# Nettoyage environnement
wsl make clean
```

---

## 🎯 État Actuel du Projet (v1.6.0-step5-wsl-validation)

### ✅ Infrastructure Azure (Complète)
- **PostgreSQL Flexible Server** : Déployé et accessible ✅
- **Azure Key Vault** : Configuré avec secrets ✅
- **API Management** : Policies de quota configurées ✅
- **Monitoring** : Application Insights déployé ✅
- **Validation** : 15/15 tests passent ✅

### ⚠️ Application Deployment (En cours)
- **Azure OpenAI** : Configuration en cours
- **Teams Bot** : Registration et déploiement requis
- **Marketplace** : Tokens et configuration requis
- **Tests E2E** : Validation complète à effectuer

### 🚀 Prochaines Étapes (v1.7.0)
1. Configuration Azure OpenAI Service
2. Déploiement Teams Bot Application
3. Configuration Microsoft Marketplace
4. Tests d'intégration end-to-end

---

## 📊 Métriques de Documentation

### Couverture Complète ✅
- **Architecture** : 3 diagrammes Draw.io + documentation
- **Infrastructure** : Azure complètement documenté
- **Déploiement** : Guides step-by-step avec Makefile
- **Configuration** : Variables d'environnement documentées
- **Validation** : 15 tests automatisés documentés

### Documents Clés Mis à Jour (Août 2025)
- ✅ Architecture complète end-to-end
- ✅ Infrastructure Azure déployée
- ✅ Workflows Makefile standardisés
- ✅ Scripts bash compatibles WSL
- ✅ Système de validation 15/15

---

## � Aide et Support

### 🆘 Problèmes Courants
1. **Erreurs WSL** : Vérifier que `dos2unix` est installé
2. **Permissions scripts** : Exécuter `wsl chmod +x scripts/*.sh`
3. **Variables d'environnement** : Vérifier `env/.env.local`
4. **Azure CLI** : S'assurer d'être connecté à Azure

### 📚 Ressources Additionnelles
- **Makefile complet** : [MAKEFILE_GUIDE.md](MAKEFILE_GUIDE.md)
- **Architecture détaillée** : [COMPLETE_ARCHITECTURE.md](COMPLETE_ARCHITECTURE.md)
- **Infrastructure Azure** : [AZURE_INFRASTRUCTURE.md](AZURE_INFRASTRUCTURE.md)
- **Validation système** : `wsl make validate`

### 🏷️ Tags et Versions
- **v1.6.0-step5-wsl-validation** : Current (Infrastructure ready)
- **v1.5.0-step4-azure-database** : Azure database deployed
- **v1.4.0-step3-database** : Database configuration
- **v1.3.0-step2-environment** : Environment setup
- **v1.2.0-documentation-architecture** : Documentation restructuring

---

**Dernière mise à jour** : 18 août 2025  
**Version documentation** : v1.6.0-step5-wsl-validation  
**Infrastructure status** : ✅ Deployed and validated (15/15 tests)  
**Next milestone** : v1.7.0-step6-application-deployment

### En cas de problème
1. **Statut système** : `make status`
2. **Tests diagnostiques** : `make validate`
3. **Logs** : Vérifier sortie des commandes make
4. **Documentation** : Consulter `docs/MAKEFILE_GUIDE.md`

### Ressources externes
- **Azure CLI** : [Documentation officielle](https://docs.microsoft.com/en-us/cli/azure/)
- **Microsoft Marketplace** : [Partner Center Documentation](https://docs.microsoft.com/en-us/azure/marketplace/)
- **PostgreSQL** : [Documentation officielle](https://www.postgresql.org/docs/)
