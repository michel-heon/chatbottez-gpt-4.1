# 🏗️ Guide de Déploiement Bicep - Infrastructure Complète

## Vue d'ensemble

Ce guide vous permet de déployer l'infrastructure complète ChatBottez GPT-4.1 en utilisant Azure Bicep (Infrastructure as Code). Cette approche garantit un déploiement reproductible, versionné et maintenable.

## 📋 Architecture Déployée

### Composants qui seront créés :

#### 🧠 **Intelligence Artificielle**
- **Azure OpenAI Service** (Canada East)
  - Déploiement GPT-4 (modèle 0613)
  - 10 TPM capacity
  - Custom subdomain

#### 🌐 **Application & API**
- **Azure App Service Plan** (Basic B1)
  - Linux-based
  - Node.js 18 LTS runtime
- **Web App** (Teams Bot)
  - System-assigned managed identity
  - Key Vault integration
  - Application Insights monitoring

#### 🔒 **API Management & Security**
- **API Management** (Developer SKU)
  - Quota global: 300 appels/mois
  - Rate limiting: 10 appels/minute
  - Application Insights logging
  - Policy de sécurité TLS 1.2+

#### 📊 **Monitoring & Analytics**
- **Log Analytics Workspace**
  - 30 jours de rétention
  - PerGB2018 pricing tier
- **Application Insights**
  - Web application monitoring
  - Intégration avec Log Analytics

#### 🔐 **Sécurité & Configuration**
- **Key Vault Access Policies** (mise à jour)
  - Accès Web App pour secrets
- **Key Vault Secrets** (ajout automatique)
  - Azure OpenAI API Key
  - Azure OpenAI Endpoint
  - Application Insights Connection String

## 🚀 Procédure de Déploiement

### Prérequis

1. **Azure CLI installé et connecté**
   ```bash
   az --version
   az account show
   ```

2. **Bicep CLI installé**
   ```bash
   az bicep version
   ```

3. **Permissions Azure requises**
   - Contributor sur le groupe de ressources
   - Cognitive Services Contributor (pour OpenAI)
   - API Management Service Contributor

### Étape 1 : Configuration des Paramètres

Éditez le fichier `infra/complete-infrastructure.parameters.json` :

```json
{
  "parameters": {
    "resourceBaseName": {
      "value": "chatbottez-gpt41"
    },
    "environment": {
      "value": "dev"
    },
    "location": {
      "value": "Canada Central"
    },
    "publisherEmail": {
      "value": "votre-email@domaine.com"
    },
    "publisherName": {
      "value": "Votre Nom ou Organisation"
    }
  }
}
```

### Étape 2 : Déploiement Automatisé

```bash
# Option A : Via Makefile (recommandé)
wsl make deploy-bicep

# Option B : Script direct
wsl ./scripts/deploy-complete-infrastructure.sh

# Option C : Azure CLI manuel
az deployment group create \
  --name "complete-infrastructure-$(date +%Y%m%d)" \
  --resource-group "rg-chatbottez-gpt-4-1-dev-02" \
  --template-file "infra/complete-infrastructure.bicep" \
  --parameters "@infra/complete-infrastructure.parameters.json"
```

### Étape 3 : Validation Post-Déploiement

```bash
# Valider l'infrastructure complète
wsl make validate

# Vérifier les ressources créées
az resource list --resource-group rg-chatbottez-gpt-4-1-dev-02 --output table

# Tester la connectivité OpenAI
az cognitiveservices account list --resource-group rg-chatbottez-gpt-4-1-dev-02
```

## 📊 Ressources Créées

Après le déploiement, vous aurez ces nouvelles ressources :

| Type | Nom | Purpose |
|------|-----|---------|
| Log Analytics | `law-chatbottez-gpt41-dev-xxxxxx` | Collecte de logs centralisée |
| Application Insights | `ai-chatbottez-gpt41-dev-xxxxxx` | Monitoring application |
| API Management | `apim-chatbottez-gpt41-dev-xxxxxx` | Gateway API avec quotas |
| Cognitive Services | `openai-chatbottez-gpt41-dev-xxxxxx` | Service Azure OpenAI |
| App Service Plan | `plan-chatbottez-gpt41-dev-xxxxxx` | Hébergement application |
| Web App | `app-chatbottez-gpt41-dev-xxxxxx` | Application Teams Bot |

## 🔐 Sécurité et Configuration

### Key Vault Secrets Automatiquement Créés

- `azure-openai-key` : Clé API Azure OpenAI
- `azure-openai-endpoint` : Endpoint Azure OpenAI  
- `application-insights-connection-string` : Connection string App Insights

### Managed Identity

La Web App utilise une **System-Assigned Managed Identity** pour :
- Accéder aux secrets Key Vault de façon sécurisée
- Éviter les credentials hardcodés
- Rotation automatique des tokens

### API Management Policies

- **Quota global** : 300 appels par mois (2,629,746 secondes)
- **Rate limiting** : 10 appels par minute
- **Sécurité** : Headers sensibles supprimés
- **Monitoring** : Logs vers Application Insights

## 🧪 Tests et Validation

### Tests Automatiques

Le script inclut :
- Validation Bicep template
- What-If preview des changements
- Confirmation utilisateur
- Validation post-déploiement

### Tests Manuels

```bash
# Test connectivité OpenAI
curl -H "Ocp-Apim-Subscription-Key: YOUR_KEY" \
     "https://openai-chatbottez-gpt41-dev-xxxxxx.openai.azure.com/openai/deployments/gpt-4/chat/completions?api-version=2023-12-01-preview"

# Test Web App
curl https://app-chatbottez-gpt41-dev-xxxxxx.azurewebsites.net/health

# Test API Management
curl https://apim-chatbottez-gpt41-dev-xxxxxx.azure-api.net/
```

## 💰 Estimation des Coûts

### Coûts Mensuels Estimés (Canada Central) :

| Service | SKU | Coût Est./Mois (CAD) |
|---------|-----|---------------------|
| API Management | Developer | ~$50 |
| App Service Plan | Basic B1 | ~$18 |
| Application Insights | Pay-as-you-go | ~$5-15 |
| Log Analytics | PerGB2018 | ~$5-10 |
| Azure OpenAI | Standard (10 TPM) | Variable selon usage |

**Total estimé** : ~$80-100/mois + coûts OpenAI selon usage

## 🚫 Dépannage

### Erreurs Communes

1. **Quota OpenAI dépassé**
   ```bash
   # Vérifier les quotas disponibles
   az cognitiveservices account list-skus --kind OpenAI
   ```

2. **Permissions insuffisantes**
   ```bash
   # Vérifier les rôles assignés
   az role assignment list --assignee $(az account show --query user.name -o tsv)
   ```

3. **Noms de ressources en conflit**
   - Les noms incluent un suffixe unique basé sur le Resource Group ID
   - En cas de conflit, modifier `resourceBaseName` dans les paramètres

### Logs de Déploiement

```bash
# Voir les détails d'un déploiement
az deployment group show --name "complete-infrastructure-YYYYMMDD" \
                        --resource-group "rg-chatbottez-gpt-4-1-dev-02"

# Voir les erreurs de déploiement
az deployment operation group list --name "complete-infrastructure-YYYYMMDD" \
                                  --resource-group "rg-chatbottez-gpt-4-1-dev-02"
```

## 🔄 Prochaines Étapes

Après le déploiement réussi :

1. **Déployer le code application**
   ```bash
   wsl make deploy-app
   ```

2. **Configurer Teams Bot Framework**
   - Créer Bot registration
   - Configurer Teams app manifest
   - Publier Teams app

3. **Tests d'intégration complète**
   ```bash
   wsl make test-integration
   ```

4. **Configuration production**
   - Scaling plans
   - Backup strategies
   - Monitoring alerts

## 📞 Support

Pour le support et les questions :
- **Documentation** : [docs/README.md](../docs/README.md)
- **Issues** : GitHub Issues du projet
- **Logs** : Application Insights dashboard
