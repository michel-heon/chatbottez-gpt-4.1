# Azure Infrastructure Architecture - ChatBottez GPT-4.1

## 📋 Vue d'ensemble

Ce diagramme présente l'architecture d'infrastructure Azure déployée pour le projet **ChatBottez GPT-4.1**, un système de chatbot Teams AI avec gestion de quotas via Microsoft Commercial Marketplace.

## 🏗️ Architecture Déployée

### 📦 **Groupe de Ressources**
- **Nom** : `rg-chatbottez-gpt-4-1-dev-02`
- **Région** : Canada Central
- **Environnement** : Développement
- **Abonnement** : Microsoft Azure Sponsorship

### 🔧 **Composants Infrastructure**

#### 🌐 **Réseau et Sécurité**
- **Virtual Network** : `chatbottez-vnet`
- **Network Security Group** : Règles d'accès à la base de données
- **Firewall Rules** :
  - Développement : Tous les IPs autorisés
  - Production : IPs restreints
  - SSL requis pour toutes les connexions

#### 🗄️ **Services de Base de Données**
- **PostgreSQL Flexible Server** : `gpt-4-1-postgres-dev-rdazbuglrttd6`
  - Version : PostgreSQL 16
  - SKU : Standard_B1ms
  - Stockage : 32 GB
  - Rétention backup : 7 jours
  - Base de données : `marketplace_quota`
  - Utilisateurs :
    - `pgadmin` (administrateur)
    - `marketplace_user` (application)

#### 🔐 **Sécurité et Gestion des Secrets**
- **Azure Key Vault** : `kvgpt41devrdazbuglrttd6`
  - SKU : Standard
  - Soft Delete activé
  - Secrets stockés :
    - `postgres-admin-connection-string`
    - `postgres-app-connection-string`
    - Futurs tokens Marketplace

#### 🚀 **API Management**
- **APIM Instance** : `apim-chatbottez-gpt-4-1-dev-02`
  - Tier : Consumption
  - Politique de quota : 300 requêtes/mois
  - Rate limiting configuré
  - Gestion des clés d'abonnement

#### 📊 **Monitoring et Observabilité**
- **Application Insights** : `gpt41-appinsights-dev`
- **Azure Monitor** : Métriques et alertes
- **Azure Storage** : Archive des logs et événements échoués

#### ⚙️ **Déploiement et Gestion**
- **Infrastructure as Code** : Templates Azure Bicep
- **Scripts d'automatisation** :
  - `azure-deploy.sh`
  - `azure-configure.sh` 
  - `database-setup.sh`
  - `environment-setup.sh`
- **Système de validation** : 15 vérifications automatisées

## 🔗 **Flux de Données**

1. **Utilisateur Teams** → **APIM** (vérification quota)
2. **APIM** → **Application Bot** (requêtes autorisées)
3. **Application** → **PostgreSQL** (stockage usage)
4. **Application** → **Key Vault** (récupération secrets)
5. **Monitoring** → **Application Insights** (télémétrie)

## 🏷️ **Tags et Métadonnées**

Toutes les ressources sont tagguées avec :
- **Environment** : dev
- **Project** : chatbottez-gpt-4-1
- **Purpose** : marketplace-quota-management

## 📋 **État Actuel**

- **Version** : v1.6.0-step5-wsl-validation
- **Status** : Infrastructure déployée ✅
- **Validation** : 15/15 tests passés ✅
- **Prochaine étape** : Déploiement application Teams

## 🔧 **Configuration d'Environnement**

### Développement
- Accès réseau : Tous les IPs autorisés
- Backup : 7 jours de rétention
- Haute disponibilité : Désactivée
- Géo-redondance : Désactivée

### Production (Futur)
- Accès réseau : IPs restreints
- Backup : 30 jours de rétention
- Haute disponibilité : Activée
- Géo-redondance : Activée

## 📁 **Fichiers de Configuration**

- `config/azure.env` : Configuration centralisée Azure
- `env/.env.local` : Variables d'environnement locales
- `infra/azure.bicep` : Template Infrastructure as Code
- `Makefile` : Orchestration des déploiements

## 🚀 **Commandes de Déploiement**

```bash
# Validation complète
wsl make validate

# Statut du système
wsl make status

# Déploiement complet
wsl make deploy

# Configuration post-déploiement
wsl make configure
```

## 📝 **Notes de Sécurité**

- Toutes les connexions utilisent SSL/TLS
- Les secrets sont stockés dans Azure Key Vault
- L'accès à la base de données est restreint par NSG
- Les tokens et clés API ne sont jamais exposés en plaintext
- Audit logging activé pour toutes les opérations critiques

---

**Dernière mise à jour** : 18 août 2025  
**Version du diagramme** : v1.6.0-step5-wsl-validation
