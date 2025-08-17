# SYSTEM PROMPT - Microsoft Marketplace Quota Management

## 🎯 CONTEXTE DU PROJET

Tu travailles sur l'implémentation d'un **système de quota pour Microsoft Commercial Marketplace** dans une application **Microsoft Teams AI Bot** basée sur TypeScript/Node.js avec Teams AI Library.

### Objectif Principal
Limiter à **300 questions par mois par utilisateur** avec facturation SaaS via Microsoft Marketplace, incluant hard cap et metered billing.

## 🏗️ ARCHITECTURE IMPLEMENTÉE

### Stack Technique
- **Backend** : TypeScript + Express.js + Teams AI Library
- **Bot Framework** : Microsoft Teams Bot avec Azure OpenAI
- **Quota Enforcement** : Azure API Management (APIM) + Middleware custom
- **Billing** : Microsoft Marketplace SaaS Fulfillment + Metered Billing APIs
- **Database** : PostgreSQL (schéma défini dans `src/db/schema.sql`)
- **Infrastructure** : Azure (App Service, APIM, Event Hubs)

### Composants Clés Implémentés

1. **`src/marketplace/fulfillmentController.ts`** 
   - Webhooks SaaS Fulfillment (resolve, activate, update, deactivate)
   - Gestion cycle de vie des abonnements

2. **`src/marketplace/meteringClient.ts`**
   - Publication événements d'usage vers Marketplace
   - Retry logic avec exponential backoff
   - Batch processing

3. **`src/middleware/quotaUsage.ts`**
   - Middleware Express pour vérification quota
   - Intégration Teams Bot Context
   - Headers de quota (x-quota-remaining, etc.)

4. **`src/services/subscriptionService.ts`**
   - Gestion abonnements et usage tracking
   - Interface avec base de données

5. **`infra/apim/policy.xml`**
   - Policy APIM avec quota-by-key (300/month)
   - Gestion erreurs 429 (Quota Exceeded)

6. **`src/utils/`**
   - `logger.ts` : Logging structuré
   - `auth.ts` : Validation webhooks et APIM
   - `auditLogger.ts` : Audit trail complet

### Flux de Données Principal
```
User Question → APIM (quota check) → Bot Endpoint → Middleware → AI Processing → Usage Event → Marketplace
```

## 📋 ÉTAT ACTUEL DU PROJET

### ✅ Complété
- Architecture complète définie
- Tous les fichiers sources créés
- Base de données schema PostgreSQL
- Policy APIM avec quota enforcement
- Infrastructure as Code (Bicep)
- Tests unitaires (structure)
- Documentation complète (README_QUOTA.md, TODO.md)

### ⚠️ Actions Critiques Restantes
1. **Erreurs TypeScript à corriger** :
   - Types manquants pour Jest
   - Erreur dans `SubscriptionService.updateSubscription()` (type status)
   - Imports manquants

2. **Configuration manquante** :
   - Variables d'environnement (copier .env.example)
   - Base de données à créer et connecter
   - Clés API Marketplace à obtenir

3. **Déploiement infrastructure** :
   - Azure API Management à déployer
   - Configuration Partner Center Marketplace

## 🎛️ VARIABLES D'ENVIRONNEMENT CLÉS

```env
# Marketplace
MARKETPLACE_API_KEY=your-marketplace-api-key
MARKETPLACE_API_BASE=https://marketplaceapi.microsoft.com

# Quota
DIMENSION_NAME=question
INCLUDED_QUOTA_PER_MONTH=300
OVERAGE_ENABLED=false

# Database
DATABASE_URL=postgresql://user:pass@host:port/dbname

# Security
JWT_SECRET_KEY=your-jwt-secret-for-webhooks
```

## 🚨 POINTS D'ATTENTION CRITIQUES

### Quota Enforcement Strategy
- **Hard Cap par défaut** : Bloque à 300 questions (HTTP 429)
- **APIM Policy** : Premier niveau de protection
- **Middleware** : Deuxième niveau + usage tracking
- **Overage optionnel** : Configurable par abonnement

### Sécurité
- Validation signature webhooks Microsoft
- APIM subscription keys
- Audit logging complet
- Chiffrement données sensibles

### Performance
- Publish usage events asynchrone
- Retry avec exponential backoff
- Connection pooling database
- Caching subscription info

## 📝 ENDPOINTS PRINCIPAUX

### Bot
- `POST /api/messages` - Messages Teams (quota appliqué)

### Marketplace Webhooks
- `POST /marketplace/resolve` - Résolution token
- `POST /marketplace/{id}/activate` - Activation abonnement
- `POST /marketplace/{id}/update` - Mise à jour abonnement
- `POST /marketplace/{id}/deactivate` - Désactivation

### Monitoring
- `GET /health` - Health check

## 📊 DATABASE SCHEMA

### Tables Principales
- **subscriptions** : Abonnements Marketplace
- **usage_events** : Événements d'usage pour billing
- **audit_logs** : Logs d'audit sécurité

### Fonctions SQL
- `get_current_month_usage(sub_id)` - Usage mois courant
- `get_usage_for_period(sub_id, start, end)` - Usage période

## 🔧 COMMANDES UTILES

```bash
# Installation
npm install

# Tests
npm test
npm run test:coverage
npm run test:integration

# Build
npm run build

# Database
npm run db:migrate
npm run db:seed

# Dev
npm run dev
```

## 🎯 PROCHAINES ÉTAPES IMMÉDIATES

1. **Corriger erreurs TypeScript** - Types Jest, imports
2. **Configurer .env** - Variables d'environnement
3. **Setup database** - PostgreSQL + schema
4. **Déployer APIM** - Policy quota
5. **Tests E2E** - Workflow complet

## 🆘 EN CAS DE PERTE DE CONTEXTE

**Consulte ces fichiers pour te re-contextualiser rapidement :**
- `TODO.md` - Liste complète des tâches
- `README_QUOTA.md` - Architecture et design
- `package.json` - Dépendances et scripts
- `src/index.ts` - Point d'entrée avec middleware
- `infra/apim/policy.xml` - Policy quota APIM

**Questions clés pour te recentrer :**
1. Où en sommes-nous dans la TODO list ?
2. Quelles erreurs TypeScript restent à corriger ?
3. La base de données est-elle configurée ?
4. APIM est-il déployé avec la policy ?
5. Les webhooks Marketplace sont-ils testés ?

## 🧠 PROMPT DE RECONTEXTUALISATION

```
Tu travailles sur un système de quota Microsoft Marketplace pour un bot Teams AI. 
L'objectif : 300 questions/mois par utilisateur avec enforcement via APIM + middleware.
Architecture : TypeScript/Express + Teams AI + APIM + PostgreSQL + Marketplace APIs.
État : Code implémenté, reste corrections TypeScript + setup infrastructure.
Consulte TODO.md pour les prochaines étapes.
Priorité : Corriger erreurs compilation puis setup database.
```

---

**🔍 Utilise ce prompt pour te reconnecter instantanément au contexte du projet à tout moment !**
