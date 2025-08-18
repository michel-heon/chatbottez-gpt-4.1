# 📁 Structure de Fichiers - ChatBottez GPT-4.1 v1.7.0

## 🎯 **Fichiers Principaux à Conserver**

### 📚 **Documentation (mis à jour)**
```
docs/
├── README.md                     ✅ Guide principal documentation
├── STATUS.md                     ✅ Statut projet v1.7.0
├── DEPLOYMENT_LOG.md             🆕 Log déploiement 18 août 2025
├── COMPLETE_ARCHITECTURE.md      ✅ Architecture complète
├── MAKEFILE_GUIDE.md            ✅ Guide Makefile
├── AZURE_INFRASTRUCTURE.md      ✅ Infrastructure Azure
└── DEPLOYMENT_SUMMARY.md        ✅ Résumé déploiement
```

### 🏗️ **Infrastructure (actuelle)**
```
infra/
├── complete-infrastructure-dev05.bicep        ✅ Infrastructure actuelle
├── complete-infrastructure-dev05.parameters.json ✅ Paramètres dev05
├── azure.bicep                               ✅ Configuration Azure
├── azure.parameters.json                    ✅ Paramètres Azure
└── botRegistration/                          ✅ Bot registration
```

### 🚀 **Scripts de Déploiement**
```
scripts/
├── deploy-app-dev05-wsl.sh      ✅ Script déploiement WSL actuel
├── cleanup-before-push.sh       🆕 Script nettoyage pré-push
└── [autres scripts utilitaires]
```

### 💻 **Code Source Application**
```
src/
├── index.ts                      ✅ Point d'entrée application
├── app/                          ✅ Logique application Teams
├── marketplace/                  ✅ Intégration Marketplace
├── middleware/                   ✅ Middleware quota/auth
├── services/                     ✅ Services métier
├── utils/                        ✅ Utilitaires
└── prompts/                      ✅ Prompts AI
```

### ⚙️ **Configuration**
```
env/
├── .env.local                    ✅ Config locale
├── .env.playground               ✅ Config playground
├── .env.example                  ✅ Template config
└── [autres fichiers env]
```

### 📱 **Teams App Package**
```
appPackage/
├── manifest.json                 ✅ Manifest Teams
├── color.png                     ✅ Icône couleur
└── outline.png                   ✅ Icône outline
```

### 🔧 **Configuration Projet**
```
/
├── package.json                  ✅ Dépendances Node.js
├── tsconfig.json                 ✅ Config TypeScript
├── web.config                    ✅ Config IIS Azure
├── Makefile                      ✅ Commandes automation
├── README.md                     ✅ README principal
├── TODO.md                       ✅ Liste des tâches
└── .gitignore                    ✅ Fichiers à ignorer
```

---

## 🗑️ **Fichiers Supprimés/Désuets**

### ❌ **Scripts PowerShell Remplacés**
- `deploy-simple.ps1` → remplacé par WSL script
- `deploy-app-dev05.ps1` → remplacé par WSL script
- `temp_deploy.ps1` → script temporaire

### ❌ **Infrastructure Désuète**
- `infra/complete-infrastructure-dev01.*` → remplacé par dev05
- `infra/complete-infrastructure-dev02.*` → remplacé par dev05
- `infra/complete-infrastructure-dev03.*` → remplacé par dev05
- `infra/complete-infrastructure-dev04.*` → remplacé par dev05

### ❌ **Fichiers Temporaires**
- `deploy.zip` → généré à la volée
- `deployment-outputs.json` → sortie temporaire
- `app-settings.json` → config temporaire
- `lib/` → dossier de build (recompilé)
- `node_modules/` → dépendances (réinstallées)

### ❌ **Logs et Configs Sensibles**
- `devTools/m365agentsplayground.log` → logs temporaires
- `.localConfigs` → configuration locale sensible
- `.localConfigs.playground` → configuration locale sensible

---

## 📊 **Statistiques du Nettoyage**

### **Avant Nettoyage**
- **Fichiers totaux** : ~500+ fichiers
- **Taille** : ~100+ MB (avec node_modules)
- **Fichiers désuets** : ~20 fichiers

### **Après Nettoyage**
- **Fichiers essentiels** : ~80 fichiers
- **Taille** : ~5-10 MB
- **Focus** : Code source, config, documentation

---

**Last Updated** : 18 août 2025  
**Version** : v1.7.0-step6-application-deployment  
**Status** : Prêt pour push Git propre
