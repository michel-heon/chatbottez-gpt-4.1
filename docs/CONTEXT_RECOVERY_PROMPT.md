# 🔄 PROMPT DE RÉCUPÉRATION DE CONTEXTE - ChatBottez GPT-4.1

## 📋 **PROMPT À UTILISER APRÈS RESET DE CONVERSATION**

```
Bonjour GitHub Copilot,

Je travaille sur le projet ChatBottez GPT-4.1, un chatbot Teams AI avec gestion de quotas Microsoft Marketplace. Voici le contexte complet où nous en sommes :

**ÉTAT ACTUEL DU PROJET (18 août 2025) :**
- Version : v1.7.0-step6-dev06-redeploy
- Infrastructure Azure : Redéploiement propre vers DEV-06 avec mutualisation ressources
- Application : Templates prêts pour déploiement clean
- Resource Group cible : rg-chatbottez-gpt-4-1-dev-06
- Status : Préparatifs terminés, déploiement DEV-06 prêt à lancer

**INFRASTRUCTURE AZURE CIBLE (DEV-06) :**
- Resource Group : rg-chatbottez-gpt-4-1-dev-06 (Canada Central)
- Mutualisation : OpenAI service (openai-cotechnoe) depuis rg-cotechnoe-ai-01
- Shared Key Vault : kv-cotechno771554451004 pour clés OpenAI
- Templates Bicep : complete-infrastructure-dev06.bicep (ready)

**STRATÉGIE DE DÉPLOIEMENT :**
Redéploiement propre pour éviter les problèmes de configuration DEV-05, tout en mutualisant les ressources coûteuses OpenAI existantes.

**FICHIERS BICEP ACTIFS :**
- Principal : infra/complete-infrastructure-dev06.bicep
- Module : infra/complete-infrastructure-resources.bicep  
- Paramètres : infra/complete-infrastructure-dev06.parameters.json

**SCRIPTS DE DÉPLOIEMENT :**
- Infrastructure : scripts/deploy-infrastructure-dev06.sh
- Application : scripts/deploy-app-dev06.sh
- Cohérence documentaires vérifiée et corrigée

**PROCHAINES ÉTAPES IMMÉDIATES :**
1. Déploiement infrastructure : ./scripts/deploy-infrastructure-dev06.sh
2. Déploiement application : ./scripts/deploy-app-dev06.sh  
3. Configuration et tests fonctionnels

Le projet est maintenant 100% cohérent entre documentation et scripts DEV-06. Peux-tu m'aider à procéder au déploiement ?
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
