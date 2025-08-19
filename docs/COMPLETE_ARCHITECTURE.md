# Architecture Complète - ChatBottez GPT-4.1 v2.0 (DEV-06)
## Du Client à l'Infrastructure Hybride avec TeamsFx

## 📋 Vue d'ensemble

**Version :** v2.0.0-teamsfx-integrated
**Architecture :** Hybride avec mutualisation optimisée et double approche de déploiement

Ce document présente l'**architecture complète end-to-end** du système ChatBottez GPT-4.1 version v2.0, intégrant le **Microsoft 365 Agents Toolkit (TeamsFx)** comme méthode de déploiement native, tout en préservant l'approche legacy par scripts personnalisés.

## 🌟 Nouveautés v2.0 - TeamsFx Integration

### **🚀 Double Approche de Déploiement**
```
┌─ TeamsFx Natif (Recommandé) ──────┐   ┌─ Scripts Legacy (Compatible) ──┐
│  • Configuration déclarative      │   │  • Scripts Bicep personnalisés  │
│  • m365agents.dev06.yml          │   │  • Contrôle granulaire          │
│  • Authentification intégrée      │   │  • deploy-app-dev06.sh          │
│  • make teamsfx-dev06-full       │   │  • make deploy-dev06-full       │
└────────────────────────────────────┘   └──────────────────────────────────┘
```

### **📝 Configuration TeamsFx**
```
📁 Configuration TeamsFx
├── m365agents.dev06.yml          # Déploiement déclaratif
├── env/.env.dev06               # Variables TeamsFx
├── .vscode/tasks.json           # Tâches VS Code
└── .webappignore               # Exclusions déploiement
```

## 🏗️ Architecture Hybride DEV-06 v2.0

### 🔗 **Stratégie de Mutualisation avec TeamsFx**
```
┌─ rg-chatbottez-gpt-4-1-dev-06 ────┐   ┌─ rg-cotechnoe-ai-01 (Partagé) ─┐
│  • PostgreSQL                     │◄──┤  • OpenAI Service (gpt-4.1)     │
│  • App Service (TeamsFx managed)  │   │  • Key Vault (secrets OpenAI)   │
│  • Key Vault (local)              │   │  • Coût mutualisé               │
│  • APIM + Monitoring              │   └──────────────────────────────────┘
│  • Managed Identity               │
│  • TeamsFx App Registration       │   ┌─ Microsoft 365 Services ───────┐
└────────────────────────────────────┘   │  • Teams App Store             │
                                         │  • Bot Framework               │
                                         │  • M365 Admin Center           │
                                         └──────────────────────────────────┘
```

### 👥 **Couche Client** - Microsoft Teams Users (Inchangée)

#### **Clients Teams Supportés**
- **Teams Desktop Client** : Application native Windows/Mac
- **Teams Web Client** : Navigateur web (teams.microsoft.com)
- **Teams Mobile App** : iOS et Android

#### **Expérience Utilisateur**
- **Interface conversationnelle** : Chat naturel avec le bot
- **Gestion de quota** : Affichage en temps réel (X/300 questions restantes)
- **Feedback instantané** : Réponses rapides via OpenAI partagé (gpt-4.1)
- **Multi-plateforme** : Expérience cohérente sur tous les appareils
- **🌟 Prévisualisation TeamsFx** : Test immédiat avec `make teamsfx-preview-dev06`

#### **Intégration Marketplace**
- **Microsoft Commercial Marketplace** : Modèle SaaS avec abonnement mensuel
- **Plan recommandé** : 35-40$/mois (analyse coûts OpenAI incluse)
- **Quota par défaut** : 300 questions/mois par utilisateur
- **Billing automatique** : Facturation Microsoft directe
- **Partner Center** : Gestion des offres et analytics

---

### 🤖 **Couche Application** - ChatBottez GPT-4.1 Bot v2.0 (DEV-06)

#### **Bot Framework & Runtime avec TeamsFx**
- **Microsoft Bot Framework** : SDK et services de base
- **Teams AI Library** : Extensions spécialisées Teams
- **🌟 TeamsFx Integration** : Gestion automatique des ressources et authentification
- **Express.js Server** : Runtime Node.js sur port 3978
- **App Service Plan** : S1 Standard (auto-scaling disponible)
- **URL** : `https://chatbottez-gpt41-app-{unique}.azurewebsites.net`

#### **Stack Middleware & Architecture**
```
📨 Request → 🛡️ Quota Check (APIM) → 🔐 Auth (MI) → 📊 Audit → 🤖 OpenAI (Partagé) → 📤 Response
```

**🛡️ Quota Usage Middleware**
- Vérification quota restant avant traitement
- Tracking automatique des événements d'usage
- Blocage des requêtes dépassant la limite (HTTP 429)
- Headers de réponse avec statut quota

**🔐 Authentication Middleware**
- Validation des tokens Teams
- Authentification webhooks Marketplace
- Sécurisation des endpoints sensibles

**📊 Audit Logging Middleware**
- Logging structuré de toutes les requêtes/réponses
- Tracking des événements de sécurité
- Conformité et traçabilité complète

#### **Services Métier**

**🎯 Chat Processing Service**
- Compréhension du langage naturel
- Gestion du contexte de conversation
- Génération de réponses personnalisées
- Intégration with Teams conversation flow

**📊 Subscription Service**
- Lookup des abonnements utilisateur
- Gestion centralisée des quotas
- Tracking en temps réel de l'usage
- Synchronisation avec Marketplace

**🔄 Metering Client**
- Publication d'événements d'usage vers Marketplace
- Traitement par batch pour optimisation
- Retry logic avec exponential backoff
- Gestion des erreurs et fallback

#### **API Endpoints**

**📨 /api/messages** (Teams Bot Endpoint)
- Point d'entrée principal pour messages Teams
- Enforcement du quota en temps réel
- Traitement conversationnel

**🔗 Marketplace Webhooks**
- `/marketplace/resolve` : Résolution des tokens
- `/marketplace/{id}/activate` : Activation d'abonnement
- `/marketplace/{id}/update` : Modification d'abonnement  
- `/marketplace/{id}/deactivate` : Désactivation

**🔍 /health** : Health check et monitoring

#### **Déploiement d'Application**

**☁️ Azure App Service** (Recommandé)
- Runtime Node.js 18+
- Auto-scaling intégré
- Certificats SSL automatiques
- Intégration Azure Key Vault

**🐳 Alternative Container**
- Support Docker natif
- Azure Container Apps
- Kubernetes compatible

**🔧 Configuration**
- Variables d'environnement sécurisées
- Intégration Key Vault pour secrets
- Application Insights pour monitoring

#### **Teams App Package**

**📱 App Manifest**
- Déclaration des capacités bot
- Permissions et scopes requis
- Métadonnées et icônes

**🔐 App Registration**
- Azure AD application
- Bot Framework registration
- OAuth permissions configurées

**📦 Distribution**
- App catalog d'entreprise
- Soumission Teams Store (optionnel)
- Side-loading pour développement

---

### 🧠 **Couche Intelligence Artificielle**

#### **Azure OpenAI Service**
- **Service managé** : GPT-4 dernière génération
- **Models disponibles** :
  - `gpt-4` (latest)
  - `gpt-4-turbo` (plus rapide)
  - Fine-tuned models (personnalisés)

#### **Configuration IA**

**⚙️ Paramètres de Modèle**
- **Temperature** : 0.7 (équilibre créativité/précision)
- **Max tokens** : 2048 (réponses détaillées)
- **System prompt** : Contexte spécialisé chatbot

**🎯 Prompt Engineering**
- Injection de contexte métier
- Prompts basés sur les rôles utilisateur
- Formatage de réponse structuré
- Gestion de la mémoire conversationnelle

**📊 Gestion des Tokens**
- Optimisation des coûts automatique
- Tracking détaillé de l'usage
- Rate limiting intelligent

#### **Sécurité du Contenu**

**🛡️ Azure Content Safety**
- Détection de contenu nuisible automatique
- Détection PII (informations personnelles)
- Filtrage de contenu en temps réel

**🔍 Filtres Personnalisés**
- Application des politiques d'entreprise
- Vérification de conformité
- Protection de marque et réputation

#### **Base de Connaissances**

**🔍 Azure Cognitive Search**
- Index vectoriel pour recherche sémantique
- Embeddings de documents d'entreprise
- Recherche contextuelle avancée

**📚 Sources de Données**
- Documents d'entreprise internes
- FAQs et bases de connaissances
- Catalogues produits
- Documentation technique

#### **Analytics IA**

**📊 Usage Analytics**
- Patterns de requêtes utilisateur
- Qualité des réponses (feedback)
- Satisfaction utilisateur (surveys)

**🎯 Performance Monitoring**
- Latence des requêtes IA
- Métriques de précision
- Analyse des coûts en temps réel

**🔄 Apprentissage Continu**
- Boucles de feedback utilisateur
- Mise à jour de modèles
- A/B testing de prompts

---

### 🌐 **Couche API Management & Gateway**

#### **Azure API Management**
- **Instance** : `apim-chatbottez-gpt-4-1-dev-02`
- **Tier** : Consumption (auto-scaling)
- **Gateway centralisé** : Point d'entrée unique

#### **Gestion des Quotas**

**📊 Configuration des Politiques**
- Policy `quota-by-key` basée sur l'abonnement
- Limite de 300 requêtes par mois
- Fenêtre glissante avec reset mensuel

**🚫 Enforcement**
- Retour HTTP 429 en cas de dépassement
- Dégradation gracieuse du service
- Headers de réponse avec statut quota

#### **Rate Limiting & Protection**

**⚡ Throttling**
- 10 requêtes par minute par utilisateur
- Gestion des pics de trafic (burst)
- Circuit breaker automatique

**🔧 Load Balancing**
- Pools de backend multiples
- Health checks automatiques
- Logique de failover

#### **Sécurité API**

**🔐 Authentication & Authorization**
- Validation JWT en temps réel
- Gestion des clés API
- Flux OAuth 2.0 complets

**🛡️ Protection**
- Politiques CORS configurées
- Filtrage IP dynamique
- Protection DDoS intégrée

#### **Analytics API**

**📈 Métriques d'Usage**
- Volume de requêtes en temps réel
- Temps de réponse par endpoint
- Taux d'erreur et patterns

**👥 Analytics Utilisateur**
- Usage par abonnement
- Endpoints populaires
- Distribution géographique

---

### 🏗️ **Couche Infrastructure Azure**

Référence complète dans : [`azure-infrastructure-diagram.drawio`](./azure-infrastructure-diagram.drawio)

**Composants principaux** :
- **PostgreSQL Flexible Server** : Base de données quotas et usage
- **Azure Key Vault** : Gestion sécurisée des secrets
- **Application Insights** : Monitoring et télémétrie
- **Azure Storage** : Archivage logs et événements
- **Virtual Network** : Sécurisation réseau

---

## 🔄 **Flux de Données End-to-End**

### 1. **Interaction Utilisateur** 
```
👤 User → 💬 Teams Client → 🌐 Microsoft Teams Service
```

### 2. **Routing & Quota Check**
```
🌐 Teams Service → 🛡️ APIM Gateway → 📊 Quota Validation → ✅/❌ Allow/Block
```

### 3. **Processing Workflow**
```
✅ Authorized Request → 🤖 Bot Framework → 🛡️ Middleware Stack → 🎯 Business Logic
```

### 4. **AI Processing**
```
🎯 Business Logic → 🧠 Azure OpenAI → 📝 Response Generation → 🛡️ Content Safety
```

### 5. **Response & Billing**
```
📝 Safe Response → 📊 Usage Tracking → 💰 Marketplace Billing → 💬 User Response
```

### 6. **Monitoring & Analytics**
```
📊 All Layers → 📈 Application Insights → 🔍 Analytics Dashboard → 📋 Business Intelligence
```

---

## 📋 **État Actuel vs Futur**

### ✅ **Complété (v1.6.0)**
- Infrastructure Azure déployée et validée
- Base de données PostgreSQL opérationnelle
- Scripts d'automatisation fonctionnels
- Système de validation 15/15 tests

### ⚠️ **En Cours (v1.7.0)**
- Configuration Azure OpenAI
- Déploiement application Teams bot
- Registration Teams App Package
- Configuration Marketplace SaaS

### 🚀 **Prochaines Étapes**
- Tests d'intégration end-to-end
- Optimisation performance IA
- Mise en production progressive
- Monitoring et analytics avancés

---

## 🔧 **Configuration Requise**

### **Azure OpenAI**
```env
AZURE_OPENAI_API_KEY=your-azure-openai-api-key
AZURE_OPENAI_ENDPOINT=https://your-openai-service.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT_NAME=your-gpt-model-deployment
```

### **Microsoft Marketplace**
```env
MARKETPLACE_API_TOKEN=your-oauth2-token
CLIENT_ID=your-client-app-id
CLIENT_SECRET=your-client-secret
```

### **Teams Bot**
```env
BOT_ID=your-teams-bot-id
BOT_PASSWORD=your-bot-password
TEAMS_APP_ID=your-teams-app-id
```

---

## 📊 **Métriques de Succès**

### **Performance**
- Latence de réponse < 3 secondes
- Disponibilité > 99.5%
- Précision des réponses > 90%

### **Usage**
- Adoption utilisateur > 70%
- Satisfaction > 4/5
- Quota utilization > 60%

### **Business**
- ROI positif dans 6 mois
- Réduction support tickets 30%
- Amélioration productivité 25%

---

**Dernière mise à jour** : 18 août 2025  
**Version** : v1.7.0-step6-dev06-redeploy  
**Prochaine étape** : Déploiement infrastructure DEV-06 avec mutualisation
