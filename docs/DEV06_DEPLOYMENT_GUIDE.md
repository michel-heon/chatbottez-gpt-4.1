# 🎯 Guide de Déploiement DEV-06 - Architecture Hybride

## 📋 Vue d'ensemble

**Version :** v1.8.0-step7-dev06-consistency  
**Architecture :** Hybride avec mutualisation des ressources OpenAI  
**Resource Group Cible :** `rg-chatbottez-gpt-4-1-dev-06`  
**Ressources Partagées :** `rg-cotechnoe-ai-01`

## 🏗️ Architecture Déployée

### **Ressources Créées (Nouvelles)**
```
📦 rg-chatbottez-gpt-4-1-dev-06
├── 🔐 Managed Identity (chatbottez-gpt41-identity)
├── 🐘 PostgreSQL Flexible Server (chatbottez-gpt41-pg-{unique})
├── 🔑 Key Vault Local (kv-gpt41-{unique})
├── 🚀 App Service Plan S1 (chatbottez-gpt41-plan-{unique})
├── 🌐 Web App (chatbottez-gpt41-app-{unique})
├── 📊 Application Insights (chatbottez-gpt41-ai-{unique})
├── 📈 Log Analytics Workspace (chatbottez-gpt41-law-{unique})
└── 🛡️ API Management Developer (chatbottez-gpt41-apim-{unique})
```

### **Ressources Partagées (Mutualisées)**
```
📦 rg-cotechnoe-ai-01
├── 🤖 OpenAI Service (openai-cotechnoe) - gpt-4o
└── 🔐 Key Vault Partagé (kv-cotechno771554451004)
```

## 🚀 Guide de Déploiement

### **Étape 1 : Préparation**
```bash
# 1. Vérifier l'état du système
make status

# 2. Créer la configuration locale (si pas déjà fait)
make env-local-create

# 3. Vérifier la connexion Azure
az account show
```

### **Étape 2 : Déploiement Complet**
```bash
# Déploiement infrastructure + application
make deploy-dev06-full
```

Cette commande exécute automatiquement :
1. `make deploy-dev06` : Déploie l'infrastructure Bicep
2. `make deploy-app-dev06` : Configure et déploie l'application

### **Étape 3 : Validation Post-Déploiement**
```bash
# Vérifier l'état du déploiement
make status

# Vérifier les déploiements Azure
make status-deployment

# Tester la configuration
make test-config
```

## 🔧 Configuration Manuelle Requise

### **Variables à Compléter dans Azure Portal**

Après déploiement, configurer ces variables dans l'App Service :

```bash
# Bot Framework (depuis Azure Portal)
BOT_ID=<bot-registration-id>
TEAMS_APP_ID=<teams-app-id>
BOT_PASSWORD=<bot-password>
MicrosoftAppId=<bot-app-id>
MicrosoftAppPassword=<bot-app-password>

# Endpoints (auto-configurés)
BOT_DOMAIN=chatbottez-gpt41-app-{unique}.azurewebsites.net
BOT_ENDPOINT=https://chatbottez-gpt41-app-{unique}.azurewebsites.net

# Marketplace (future phase)
MARKETPLACE_API_KEY=<marketplace-api-key>
```

## 💰 Stratégie de Coûts

### **Coûts Optimisés par Mutualisation**
- ✅ **OpenAI Service** : Coût partagé entre projets
- ✅ **Key Vault Partagé** : Transactions mutualisées
- 🆕 **Nouveaux coûts** : PostgreSQL, App Service, APIM uniquement

### **Estimation Mensuelle DEV-06**
| Service | SKU | Coût Estimé (CAD) |
|---------|-----|-------------------|
| PostgreSQL Flexible | Standard_B1ms | ~50 CAD |
| App Service Plan | S1 | ~100 CAD |
| API Management | Developer | ~65 CAD |
| Application Insights | Pay-as-you-go | ~10 CAD |
| Key Vault | Standard | ~5 CAD |
| **Total Nouveau** | | **~230 CAD/mois** |
| **OpenAI (Partagé)** | GPT-4o | Coût réparti |

## 🔐 Sécurité et Permissions

### **Managed Identity Permissions**
- ✅ Key Vault Local : Get/List secrets
- ✅ Key Vault Partagé : Get azure-openai-api-key
- ✅ PostgreSQL : Connect as marketplace_user
- ✅ Application Insights : Write telemetry

### **Secrets Management**
```bash
# Key Vault Local (kv-gpt41-{unique})
- database-url
- app-insights-connection-string

# Key Vault Partagé (kv-cotechno771554451004)
- azure-openai-api-key
```

## 🧪 Tests et Validation

### **Tests Automatisés Disponibles**
```bash
# Test configuration
make test-config

# Test base de données
make test-db

# Vérification des dépendances
make check-deps
```

### **URLs de Test**
```bash
# Application Web
https://chatbottez-gpt41-app-{unique}.azurewebsites.net

# API Gateway
https://chatbottez-gpt41-apim-{unique}.azure-api.net

# Health Check
https://chatbottez-gpt41-app-{unique}.azurewebsites.net/api/health
```

## 🚨 Dépannage

### **Erreurs Communes**
1. **Bicep Validation Error** : Vérifier les paramètres dans `complete-infrastructure-dev06.parameters.json`
2. **Managed Identity Access** : Attendre 5-10 min pour propagation des permissions
3. **OpenAI Access** : Vérifier l'existence des ressources partagées dans rg-cotechnoe-ai-01

### **Commandes de Diagnostic**
```bash
# Voir les logs de déploiement
az deployment sub list --query "[?contains(name, 'chatbottez')].{Name:name, State:properties.provisioningState}"

# Vérifier les ressources partagées
az resource list --resource-group rg-cotechnoe-ai-01 --output table

# Nettoyer en cas d'erreur
make clean
```

## 📞 Support

En cas de problème :
1. Consulter les logs : `make status`
2. Vérifier la documentation : `docs/STATUS.md`
3. Revoir l'architecture : `docs/COMPLETE_ARCHITECTURE.md`

---

**Documentation générée pour v1.8.0-step7-dev06-consistency**  
**Dernière mise à jour :** Août 18, 2025
