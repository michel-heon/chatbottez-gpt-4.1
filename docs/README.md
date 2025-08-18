# 📚 Documentation ChatBottez GPT-4.1 - Microsoft Marketplace Quota Management

## 🎯 Vue d'ensemble du Projet

**ChatBottez GPT-4.1** est un système de chatbot Teams AI avec gestion de quotas intégrée au Microsoft Commercial Marketplace. Le projet implémente une architecture complète du client Teams jusqu'à l'infrastructure Azure, avec intelligence artificielle via Azure OpenAI.

**Version actuelle** : `v1.8.0-step7-dev06-consistency`  
**Status** : Infrastructure hybride DEV-06 prête ✅ - Déploiement automatisé ✅ - Ready to deploy 🚀

## 🚀 Guide de Démarrage Rapide

### Pour les nouveaux utilisateurs
1. 📖 **[README.md](../README.md)** - Vue d'ensemble et quick start v1.8.0
2. 🚀 **[DEV06_DEPLOYMENT_GUIDE.md](DEV06_DEPLOYMENT_GUIDE.md)** - 🆕 Guide de déploiement DEV-06 (RECOMMANDÉ)
3. 🏗️ **[COMPLETE_ARCHITECTURE.md](COMPLETE_ARCHITECTURE.md)** - Architecture hybride avec mutualisation
4. 🔧 **[MAKEFILE_GUIDE.md](MAKEFILE_GUIDE.md)** - Guide complet du Makefile optimisé

### Pour le déploiement immédiat
```bash
# Déploiement complet en une commande
make deploy-dev06-full
```

1. � **[DEV06_DEPLOYMENT_GUIDE.md](DEV06_DEPLOYMENT_GUIDE.md)** - 🆕 Guide complet DEV-06
2. ✅ **[STATUS.md](STATUS.md)** - État v1.8.0 et architecture hybride
3. 🏗️ **[COMPLETE_ARCHITECTURE.md](COMPLETE_ARCHITECTURE.md)** - Architecture avec mutualisation des ressources

---

## 🏗️ Diagrammes d'Architecture DEV-06

### 🆕 Architecture Hybride avec Mutualisation
| Diagramme | Description | Format |
|-----------|-------------|--------|
| **[DEV06_DEPLOYMENT_GUIDE.md](DEV06_DEPLOYMENT_GUIDE.md)** | 🆕 **Guide complet déploiement DEV-06** | Guide |
| **[complete-architecture-diagram.drawio](complete-architecture-diagram.drawio)** | Architecture hybride avec ressources partagées | Draw.io |
| **[azure-infrastructure-diagram.drawio](azure-infrastructure-diagram.drawio)** | Infrastructure Azure détaillée | Draw.io |

### Architecture DEV-06 : Ressources
```
📦 rg-chatbottez-gpt-4-1-dev-06 (Nouvelles)
├── 🔐 Managed Identity + PostgreSQL + Key Vault Local
├── 🚀 App Service S1 + Application Insights
└── 🛡️ API Management Developer

📦 rg-cotechnoe-ai-01 (Partagées - optimisation coûts)
├── 🤖 OpenAI Service (gpt-4o)
└── 🔐 Key Vault Partagé
```

---

## 📚 Documentation par Catégorie

### 🏗️ Infrastructure et Déploiement

| Document | Description | Statut |
|----------|-------------|---------|
| **[DEV06_DEPLOYMENT_GUIDE.md](DEV06_DEPLOYMENT_GUIDE.md)** | 🆕 **Guide déploiement DEV-06 complet** | ✅ Nouveau |
| **[COMPLETE_ARCHITECTURE.md](COMPLETE_ARCHITECTURE.md)** | Architecture hybride avec mutualisation | ✅ Mis à jour |
| **[STATUS.md](STATUS.md)** | Statut v1.8.0 et progress DEV-06 | ✅ Mis à jour |
| **[BICEP_ARCHITECTURE.md](BICEP_ARCHITECTURE.md)** | Architecture des templates Bicep | ✅ Existant |
| **[MAKEFILE_GUIDE.md](MAKEFILE_GUIDE.md)** | Guide Makefile avec env-local-create | ✅ Mis à jour |

### 🎯 Architecture Complète et Business

| Document | Description | Statut |
|----------|-------------|---------|
| **[COMPLETE_ARCHITECTURE.md](COMPLETE_ARCHITECTURE.md)** | Architecture hybride end-to-end avec DEV-06 | ✅ Mis à jour |
| **[README_QUOTA.md](README_QUOTA.md)** | Système de quota et Marketplace | ✅ Existant |
| **[SYSTEM_PROMPT.md](SYSTEM_PROMPT.md)** | Configuration IA et prompts | ✅ Existant |

### 🔧 Configuration et Migration

| Document | Description | Statut |
|----------|-------------|---------|
| **[MIGRATION_COMPLETED.md](MIGRATION_COMPLETED.md)** | Migration PowerShell → Bash complète | ✅ Existant |
| **[CHANGELOG.md](CHANGELOG.md)** | Historique des modifications | ✅ Existant |
| **[INSTALL_POSTGRESQL.md](INSTALL_POSTGRESQL.md)** | Guide PostgreSQL pour Windows | ✅ Existant |

---

## 🚀 Workflows Recommandés

### 🆕 Déploiement DEV-06 (Recommandé)
```bash
# Déploiement complet hybride en une commande
make deploy-dev06-full

# Ou étape par étape
make deploy-dev06        # Infrastructure Bicep
make deploy-app-dev06    # Application
make status             # Vérification
```

### 👨‍💻 Développement Local
```bash
# Configuration automatique avec tenant ID
make env-local-create

# Tests et validation
make test-config
make test-db

# Démarrage développement
make dev-start
```

### 🔧 Maintenance et Monitoring
```bash
# Voir toutes les commandes disponibles
make help

# Statut complet du système
make status

# Validation des déploiements Azure
make status-deployment
```

---

## 🎯 État Actuel du Projet (v1.8.0-step7-dev06-consistency)

### ✅ Infrastructure DEV-06 (Prête)
- **Architecture Hybride** : Templates Bicep validés ✅
- **Mutualisation OpenAI** : Optimisation coûts ✅  
- **Sécurité** : Managed Identity + mots de passe dynamiques ✅
- **Tooling** : Makefile optimisé avec env-local-create ✅
- **Documentation** : Guides complets mis à jour ✅

### 🚀 Prêt pour Déploiement
- **Bicep Templates** : complete-infrastructure-dev06.bicep validé ✅
- **Paramètres** : complete-infrastructure-dev06.parameters.json ✅
- **Scripts** : Commandes de déploiement disponibles ✅
- **Validation** : Audit sécurité terminé ✅

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
