# Microsoft Commercial Marketplace - Quota Management Design

## Overview

Ce projet implémente un système de quota complet pour les abonnements SaaS via le Microsoft Commercial Marketplace. Chaque utilisateur dispose de 300 questions par mois selon l'offre SaaS configurée.

## 🚀 Déploiement Rapide

### Avec Makefile (Recommandé)

```bash
# Déploiement complet avec infrastructure quota
make all

# Ou étape par étape
make setup         # Configuration (environment + database + marketplace)
make deploy        # Infrastructure Azure (APIM + PostgreSQL + Key Vault)
make configure     # Configuration quota policies
make validate      # Tests complets (15 validations)
```

### Validation de l'Infrastructure Quota

```bash
# Statut des composants quota
make status

# Tests spécifiques quota
make test-config   # Configuration
make test-db       # Base de données quota
```

## Architecture

### Components Principaux

1. **SaaS Fulfillment API** - Gestion du cycle de vie des abonnements
2. **Metered Billing API** - Publication d'événements d'usage
3. **Azure API Management (APIM)** - Enforcement du quota hard cap ✅ DÉPLOYÉ
4. **Middleware Quota** - Validation et tracking de l'usage
5. **Database Storage** - Persistance des abonnements et events ✅ DÉPLOYÉ

### Infrastructure Déployée

```
📦 rg-chatbottez-gpt-4-1-dev-02
├── 🌐 API Management (APIM)          ✅ Quota policies configurées
├── 🗄️  PostgreSQL Flexible Server    ✅ Schémas quota configurés
└── 🔐 Key Vault                     ✅ Secrets management
```

### Flux de Données

```
User Question → APIM (quota check) → Bot Endpoint → Middleware → AI Processing → Usage Event → Marketplace
```

### Hard Cap vs Overage

- **Hard Cap (défaut)** : Bloque les requêtes après 300 questions/mois (HTTP 429)
- **Overage (optionnel)** : Permet le dépassement avec facturation via metered billing

## Configuration

### Variables d'Environnement (Déployées via Makefile)

```env
# Marketplace API (configuré via make setup)
MARKETPLACE_API_BASE=https://marketplaceapi.microsoft.com
MARKETPLACE_API_KEY=your-api-key
MARKETPLACE_SUBSCRIPTION_API_VERSION=2018-08-31
MARKETPLACE_METERING_API_VERSION=2018-08-31

# Quota Settings (configuré via APIM policies)
DIMENSION_NAME=question
INCLUDED_QUOTA_PER_MONTH=300
OVERAGE_ENABLED=false
OVERAGE_PRICE_PER_QUESTION=0.01

# Database (auto-configuré via make deploy)
DATABASE_URL=postgresql://marketplace_user:***@gpt-4-1-postgres-dev-***.postgres.database.azure.com:5432/marketplace_quota?sslmode=require

# Logging
LOG_LEVEL=info
AUDIT_LOG_ENABLED=true
```

### APIM Policy

La policy APIM applique un quota strict basé sur `subscription_id` :

```xml
<policies>
  <inbound>
    <base />
    <quota-by-key calls="300" renewal-period="month"
                  counter-key="@(context.Subscription.Id)" />
    <set-header name="x-apim-subscription-id" exists-action="override">
      <value>@(context.Subscription.Id)</value>
    </set-header>
  </inbound>
  <backend><base /></backend>
  <outbound>
    <set-header name="x-quota-remaining" exists-action="override">
      <value>@(string.Concat(300 - context.Variables.GetValueOrDefault<int>("quota-counter", 0)))</value>
    </set-header>
    <base />
  </outbound>
</policies>
```

## Endpoints

### SaaS Fulfillment

- `POST /marketplace/resolve` - Résolution du token d'abonnement
- `POST /marketplace/activate` - Activation d'un abonnement
- `POST /marketplace/update` - Mise à jour d'un abonnement
- `POST /marketplace/deactivate` - Désactivation d'un abonnement

### Usage Tracking

- Middleware automatique sur `/api/messages`
- Publication d'événements vers Marketplace Metered Billing
- Retry automatique avec exponential backoff

## Database Schema

### Table: subscriptions

```sql
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY,
  marketplace_subscription_id VARCHAR(255) UNIQUE NOT NULL,
  tenant_id VARCHAR(255) NOT NULL,
  plan_id VARCHAR(255) NOT NULL,
  status VARCHAR(50) NOT NULL,
  activated_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  quantity_included INTEGER DEFAULT 300,
  dimension VARCHAR(50) DEFAULT 'question',
  overage_enabled BOOLEAN DEFAULT false
);
```

### Table: usage_events

```sql
CREATE TABLE usage_events (
  id UUID PRIMARY KEY,
  subscription_id UUID REFERENCES subscriptions(id),
  event_id VARCHAR(255) UNIQUE NOT NULL,
  dimension VARCHAR(50) NOT NULL,
  quantity INTEGER NOT NULL,
  timestamp TIMESTAMP NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  retry_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  sent_at TIMESTAMP
);
```

## Monitoring et Alertes

### Headers de Réponse

- `x-quota-remaining` : Questions restantes ce mois
- `x-quota-reset-date` : Date de reset du quota
- `x-subscription-status` : Statut de l'abonnement

### Logs d'Audit

Tous les événements incluent :
- `tenant_id`
- `user_id` 
- `subscription_id`
- `request_id`
- `timestamp`
- `action`
- `result`

### Alertes Recommandées

- Quota à 80% : Notification utilisateur
- Quota à 90% : Alerte admin
- Quota à 100% : Blocage + notification
- Échec publication usage event : Alerte technique

## Déploiement

### Prérequis

1. Azure Subscription avec APIM
2. Microsoft Partner Center configuré
3. Base de données PostgreSQL/SQL Server
4. Azure Key Vault pour les secrets

### Étapes

1. Déployer l'infrastructure APIM via Bicep
2. Configurer les variables d'environnement
3. Exécuter les migrations de base de données
4. Déployer l'application
5. Configurer le monitoring

### Tests

```bash
# Tests unitaires
npm test

# Tests d'intégration
npm run test:integration

# Test de charge quota
npm run test:quota-load
```

## Sécurité

### Authentification

- Marketplace webhooks : Validation signature JWT
- APIM : Subscription keys
- Database : Connection strings sécurisées

### Validation

- Input sanitization sur tous les endpoints
- Rate limiting global
- CORS configuré strictement

### Audit

- Logs d'accès complets
- Événements de sécurité trackés
- Conformité GDPR pour les données utilisateur

## Support et Maintenance

### Monitoring

- Application Insights pour les métriques
- Log Analytics pour les requêtes
- Alerts configurées sur les erreurs critiques

### Backup

- Base de données : Backup quotidien
- Configuration : Versioning Git
- Secrets : Azure Key Vault avec versioning
