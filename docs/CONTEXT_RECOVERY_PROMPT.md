# 🔄 PROMPT DE RÉCUPÉRATION DE CONTEXTE - ChatBottez GPT-4.1

## 📋 **PROMPT À UTILISER APRÈS RESET DE CONVERSATION**

```
Bonjour GitHub Copilot,

Je travaille sur le projet ChatBottez GPT-4.1, un chatbot Teams AI avec gestion de quotas Microsoft Marketplace. Voici le contexte complet où nous en sommes :

**ÉTAT ACTUEL DU PROJET (18 août 2025) :**
- Version : v1.7.0-step6-application-deployment
- Infrastructure Azure : DEV-05 entièrement déployée en Canada Central
- Application : Déployée sur https://chatbottez-gpt41-app-rnukfj.azurewebsites.net (HTTP 500 - config env variables requise)
- Resource Group : rg-chatbottez-gpt-4-1-dev-05
- Status : Application déployée, configuration des variables d'environnement pendante

**INFRASTRUCTURE AZURE DÉPLOYÉE :**
- App Service Plan : plan-chatbottez-gpt41-dev-rnukfj (Windows P1v2)
- Web App : chatbottez-gpt41-app-rnukfj 
- Key Vault : kv-gpt41-rnukfj (contient clé OpenAI stockée)
- PostgreSQL : psql-chatbottez-gpt41-dev-rnukfj (Flexible Server)
- Application Insights : ai-chatbottez-gpt41-dev-rnukfj
- Log Analytics : law-chatbottez-gpt41-dev-rnukfj

**PROBLÈME ACTUEL :**
Application déployée mais retourne HTTP 500 car les variables d'environnement ne se configurent pas via Azure CLI (bug connu). Configuration manuelle via Azure Portal requise.

**FICHIERS BICEP ACTIFS :**
- Principal : infra/complete-infrastructure-dev05.bicep
- Module : infra/complete-infrastructure-resources.bicep
- Paramètres : infra/complete-infrastructure-dev05.parameters.json

**DOCUMENTATION À JOUR :**
- README.md : Statut v1.7.0 avec URL live
- TODO.md : Progression actuelle et next steps
- docs/STATUS.md : État DEV-05 complet
- docs/BICEP_ARCHITECTURE.md : Architecture templates
- docs/DEPLOYMENT_LOG.md : Log session 18 août

**SÉCURITÉ :**
- Publisher email corrigé : heon@cotechnoe.net (au lieu de michel.heon@uqam.ca)
- Clés API nettoyées des fichiers .env.*.user
- .gitignore renforcé

**ENVIRONNEMENT TECHNIQUE :**
- OS : Windows 11 ARM64 VM (Parallels sur macOS ARM64)
- WSL : Ubuntu aarch64 avec Azure CLI 2.76.0
- Node.js : v22.18.0 via NVM
- Projet : TypeScript compilé, tests partiellement fonctionnels

**DERNIÈRES ACTIONS :**
- Nettoyage complet du projet pour Git push
- Correction sécurité (clés API)
- Documentation mise à jour v1.7.0
- Validation build et compilation réussies

**PROCHAINES ÉTAPES IMMÉDIATES :**
1. Git push du projet nettoyé
2. Configuration manuelle variables environnement Azure Portal
3. Test fonctionnalité application déployée

**COMMANDES DE DÉPLOIEMENT UTILISÉES :**
```bash
# Infrastructure
az deployment sub create --location "Canada Central" \
  --template-file "infra/complete-infrastructure-dev05.bicep" \
  --parameters "@infra/complete-infrastructure-dev05.parameters.json"

# Application (via script WSL)
./scripts/deploy-app-dev05-wsl.sh
```

Le projet est maintenant 100% prêt pour Git push. Peux-tu m'aider à continuer à partir de ce point ?
```

## 🎯 **INSTRUCTIONS D'UTILISATION**

1. **Copier le prompt** ci-dessus dans une nouvelle conversation
2. **Adapter si nécessaire** selon les changements récents
3. **Ajouter des détails spécifiques** selon le contexte actuel

## 📊 **INFORMATIONS CLÉS À RETENIR**

### **URLs Importantes**
- Application live : https://chatbottez-gpt41-app-rnukfj.azurewebsites.net
- Azure Portal : Resource Group "rg-chatbottez-gpt-4-1-dev-05"

### **Credentials**
- Subscription : Canada Central
- Publisher : heon@cotechnoe.net
- Environment : DEV-05

### **Structure Projet**
```
📁 Racine/
├── 📄 README.md, TODO.md (à jour v1.7.0)
├── 📁 docs/ (documentation complète)
├── 📁 infra/ (templates Bicep DEV-05)
├── 📁 src/ (code TypeScript compilé)
├── 📁 scripts/ (déploiement automatisé)
└── 📁 env/ (variables environnement)
```

### **Issues Connues**
1. **HTTP 500** : Variables environnement non configurées
2. **Azure CLI Bug** : `az webapp config appsettings set` ne fonctionne pas
3. **Solution** : Configuration manuelle via Azure Portal

## 🔄 **HISTORIQUE SESSION 18 AOÛT 2025**

**Problème initial** : ARM64 AdvSimd compatibility WSL  
**Résolution** : Azure CLI 2.76.0 reinstallation  
**Déploiement** : Infrastructure complète DEV-05  
**Application** : Build et déploiement réussis  
**Nettoyage** : Projet prêt Git push  

---

**Créé par** : GitHub Copilot  
**Date** : 18 août 2025  
**Version** : v1.7.0-step6-application-deployment  
**Status** : 📋 Prompt de récupération contexte complet
