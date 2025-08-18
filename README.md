# ChatBottez GPT-4.1 - Teams AI Chatbot with Marketplace Quota Management

> **🚀 READY FOR DEPLOYMENT v1.8.0**  
> **Architecture**: Hybrid DEV-06 with shared OpenAI resources  
> **Status**: ✅ Infrastructure ready - 🚀 Ready to deploy  
> **Resource Group**: rg-chatbottez-gpt-4-1-dev-06  
> **Shared Resources**: rg-cotechnoe-ai-01 (OpenAI + Key Vault)

This app template is built on top of [Teams AI library](https://aka.ms/teams-ai-library).
It showcases an agent app that responds to user questions like ChatGPT with **Microsoft Commercial Marketplace integration** and **quota management**. This enables your users to talk with the AI agent in Teams while respecting subscription limits.

## 🎯 **Current Status v1.8.0-step7-dev06-consistency**

### ✅ **Infrastructure Ready (DEV-06)**
- **Architecture**: Hybrid deployment with resource mutualization
- **Target Resource Group**: `rg-chatbottez-gpt-4-1-dev-06`
- **Shared OpenAI**: `rg-cotechnoe-ai-01` (cost-optimized)
- **Bicep Templates**: Complete infrastructure validated
- **Security**: Dynamic passwords, managed identity ready
- **Tooling**: Optimized Makefile with env-local-create command

### 🚀 **Ready for Deployment**
```bash
# One-command deployment
make deploy-dev06-full
```

### 🎯 **Next Steps**
1. Run deployment: `make deploy-dev06-full`
2. Configure Bot Framework variables via Azure Portal
3. Test application functionality
4. Complete Teams integration

## �🆕 Marketplace Quota Features

This template now includes:
- **300 questions per month per subscription** quota enforcement
- **Microsoft Commercial Marketplace SaaS integration**
- **Azure API Management (APIM) quota policies**
- **Metered billing** for usage tracking
- **Multi-tenant support** with tenant and user-level tracking
- **Comprehensive audit logging**

For detailed information about quota management, see [README_QUOTA.md](./docs/README_QUOTA.md).

## Get started with the template

> **Prerequisites**
>
> To run the template in your local dev machine, you will need:
>
> - [Node.js](https://nodejs.org/), supported versions: 18, 20, 22.
> - [Microsoft 365 Agents Toolkit Visual Studio Code Extension](https://aka.ms/teams-toolkit) latest version or [Microsoft 365 Agents Toolkit CLI](https://aka.ms/teamsfx-toolkit-cli).
> - Prepare your own [Azure OpenAI](https://aka.ms/oai/access) resource.
> - **For production**: Azure API Management instance and Microsoft Partner Center account.

> For local debugging using Microsoft 365 Agents Toolkit CLI, you need to do some extra steps described in [Set up your Microsoft 365 Agents Toolkit CLI for local debugging](https://aka.ms/teamsfx-cli-debugging).

### Quick Start

1. First, select the Microsoft 365 Agents Toolkit icon on the left in the VS Code toolbar.
1. In file *env/.env.playground.user*, fill in your Azure OpenAI key `SECRET_AZURE_OPENAI_API_KEY=<your-key>`, endpoint `AZURE_OPENAI_ENDPOINT=<your-endpoint>`, and deployment name `AZURE_OPENAI_DEPLOYMENT_NAME=<your-deployment>`.

## 🚀 **Deployment Options**

### 🎯 **Option 1: Deploy DEV-06 Infrastructure (Recommended)**
Ready-to-deploy hybrid architecture with cost optimization:

```bash
# Complete deployment (infrastructure + application)
make deploy-dev06-full

# Or step by step:
make deploy-dev06        # Deploy Bicep infrastructure
make deploy-app-dev06    # Deploy application code
```

**Architecture DEV-06:**
- ✅ **New Resources**: PostgreSQL, App Service S1, APIM Developer, Key Vault Local
- ✅ **Shared Resources**: OpenAI Service, Key Vault Shared (cost-optimized)
- ✅ **Security**: Managed Identity, dynamic passwords, secure secrets

### 🛠️ **Option 2: Local Development**
For development and testing:

```bash
# Create local environment configuration
make env-local-create

# Start local development
make dev-start
```

### � **Option 3: Previous Infrastructure (DEV-05)**
If you prefer the previous deployment:

1. **Access Azure Portal**: Go to `chatbottez-gpt41-app-rnukfj` App Service
2. **Configure Variables**: Set environment variables via Azure Portal
3. **Test Application**: Verify functionality at https://chatbottez-gpt41-app-rnukfj.azurewebsites.net

## 📋 Manual Setup (Alternative)

If you prefer manual configuration:

### **Local Development Setup**
```bash
# 1. Create local environment (automatic tenant ID detection)
make env-local-create

# 2. Configure Azure OpenAI in .env.local
SECRET_AZURE_OPENAI_API_KEY=your-key
AZURE_OPENAI_ENDPOINT=your-endpoint
AZURE_OPENAI_DEPLOYMENT_NAME=your-deployment

# 3. Test configuration
make test-config

# 4. Start local development
make dev-start
```

### **Database Setup (if running locally)**
```bash
# Install PostgreSQL (see docs/INSTALL_POSTGRESQL.md for Windows)
make db-setup

# Test database connection
make test-db
```

## 🏭 Production Deployment

### **Option 1: DEV-06 Deployment (Recommended)**
```bash
# Complete production deployment with hybrid architecture
make deploy-dev06-full

# Includes:
# - Infrastructure deployment (Bicep)
# - Application deployment
# - Configuration validation
# - Security setup
```

### **Option 2: Makefile-based Deployment**
```bash
# Legacy deployment process
make prod-deploy

# Or step by step:
make setup       # Initial configuration
make deploy      # Azure infrastructure deployment
make configure   # APIM and services configuration
make validate    # Complete testing (15 validations)
```

### **Manual Production Configuration**

For marketplace integration, configure these variables in your production environment:

```bash
# Marketplace Configuration
MARKETPLACE_API_BASE=https://marketplaceapi.microsoft.com
MARKETPLACE_API_KEY=your-marketplace-api-key
DIMENSION_NAME=question
INCLUDED_QUOTA_PER_MONTH=300

# Bot Framework (configure via Azure Portal after deployment)
BOT_ID=<from-bot-registration>
TEAMS_APP_ID=<from-teams-app>
BOT_PASSWORD=<from-bot-registration>
MicrosoftAppId=<from-bot-registration>
MicrosoftAppPassword=<from-bot-registration>
```

## 🎯 **Quick Start Guide**

### **1. Deploy Infrastructure**
```bash
# One command to deploy everything
make deploy-dev06-full
```

### **2. Configure Teams Integration**
After deployment, configure Bot Framework variables in Azure Portal:
- Go to your App Service in `rg-chatbottez-gpt-4-1-dev-06`
- Add Bot registration variables (BOT_ID, BOT_PASSWORD, etc.)

### **3. Test Application**
```bash
# Check deployment status
make status

# Test application health
curl https://chatbottez-gpt41-app-{unique}.azurewebsites.net/api/health
```

**Congratulations**! You are running an application that can now interact with users in Microsoft 365 Agents Playground with quota management:

![Basic AI Chatbot](https://github.com/user-attachments/assets/984af126-222b-4c98-9578-0744790b103a)

## What's included in the template

| Folder       | Contents                                            |
| - | - |
| `.vscode`    | VSCode files for debugging                          |
| `appPackage` | Templates for the application manifest        |
| `env`        | Environment files                                   |
| `infra`      | Templates for provisioning Azure resources          |
| `src`        | The source code for the application                 |
| **`src/marketplace`** | **Marketplace SaaS fulfillment and metering** |
| **`src/middleware`** | **Quota enforcement middleware** |
| **`src/services`** | **Subscription and usage tracking services** |
| **`src/db`** | **Database schema and migrations** |
| **`tests`** | **Unit and integration tests** |

### Core Files

| File                                 | Contents                                           |
| - | - |
|`src/index.ts`| Sets up the agent app server with marketplace routes.|
|`src/adapter.ts`| Sets up the agent adapter.|
|`src/config.ts`| Defines the environment variables.|
|`src/prompts/chat/skprompt.txt`| Defines the prompt.|
|`src/prompts/chat/config.json`| Configures the prompt.|
|`src/app/app.ts`| Handles business logics for the Basic AI Chatbot.|

### Marketplace Quota Files

| File                                 | Contents                                           |
| - | - |
|`src/marketplace/fulfillmentController.ts`| Handles SaaS subscription lifecycle (resolve, activate, update, deactivate).|
|`src/marketplace/meteringClient.ts`| Publishes usage events to Microsoft Marketplace Metered Billing API.|
|`src/middleware/quotaUsage.ts`| Express middleware for quota enforcement and usage tracking.|
|`src/services/subscriptionService.ts`| Service for managing subscriptions and usage data.|
|`src/db/schema.sql`| Database schema for subscriptions, usage events, and audit logs.|
|`infra/apim/policy.xml`| Azure API Management policy for quota enforcement.|
|`infra/apim/apim.bicep`| Bicep template for APIM infrastructure.|

### Testing

| Command | Description |
| - | - |
|`npm test`| Run all tests |
|`npm run test:watch`| Run tests in watch mode |
|`npm run test:coverage`| Generate coverage report |
|`npm run test:integration`| Run integration tests |
|`npm run test:quota-load`| Run quota load tests |

### Marketplace Quotas Management

The application enforces a **hard cap of 300 questions per month** per subscription by default. Key features:

- **APIM Enforcement**: Azure API Management applies quota limits before requests reach your application
- **Usage Tracking**: Every successful AI question publishes a usage event to Microsoft Marketplace
- **Audit Logging**: Comprehensive logging of all quota-related events
- **Multi-tenant**: Supports multiple tenants with separate quota tracking
- **Headers**: Response includes quota information (`x-quota-remaining`, `x-quota-total`, `x-quota-reset-date`)
- **Overage Support**: Optional overage billing (disabled by default)

#### Quota Headers

All API responses include quota information:

```
x-quota-remaining: 287
x-quota-total: 300
x-quota-reset-date: 2024-02-01T00:00:00.000Z
x-quota-warning: high  # When > 80% usage
```

#### Error Responses

When quota is exceeded (HTTP 429):

```json
{
  "error": "Quota Exceeded",
  "message": "You have exceeded your monthly quota of 300 questions. Please upgrade your plan or wait for the quota to reset.",
  "details": {
    "remainingQuota": 0,
    "totalQuota": 300,
    "resetDate": "2024-02-01T00:00:00.000Z",
    "overageEnabled": false
  }
}
```

## 📚 **Documentation**

For complete documentation and guides:

- **[Deployment Guide DEV-06](./docs/DEV06_DEPLOYMENT_GUIDE.md)** - Complete deployment guide for hybrid architecture
- **[Architecture Overview](./docs/COMPLETE_ARCHITECTURE.md)** - Technical architecture and design decisions
- **[Project Status](./docs/STATUS.md)** - Current status and progress tracking
- **[Quota Management](./docs/README_QUOTA.md)** - Marketplace integration and quota features
- **[Makefile Guide](./docs/MAKEFILE_GUIDE.md)** - Available commands and workflows

## 🎯 **Microsoft 365 Agents Toolkit Files**

The following are Microsoft 365 Agents Toolkit specific project files:

| File | Contents |
| - | - |
|`m365agents.yml`|Main project file with properties and stage definitions |
|`m365agents.local.yml`|Overrides for local execution and debugging |
|`m365agents.playground.yml`|Overrides for Microsoft 365 Agents Playground debugging |

For a complete guide, visit [Microsoft 365 Agents Toolkit on Github](https://github.com/OfficeDev/TeamsFx/wiki/Teams-Toolkit-Visual-Studio-Code-v5-Guide#overview).

## 🛠️ **Extend the Template**

You can follow [Build a Basic AI Chatbot in Teams](https://aka.ms/teamsfx-basic-ai-chatbot) to extend the Basic AI Chatbot template with more AI capabilities, like:
- [Customize prompt](https://aka.ms/teamsfx-basic-ai-chatbot#customize-prompt)
- [Customize user input](https://aka.ms/teamsfx-basic-ai-chatbot#customize-user-input)
- [Customize conversation history](https://aka.ms/teamsfx-basic-ai-chatbot#customize-conversation-history)
- [Customize model type](https://aka.ms/teamsfx-basic-ai-chatbot#customize-model-type)
- [Customize model parameters](https://aka.ms/teamsfx-basic-ai-chatbot#customize-model-parameters)
- [Handle messages with image](https://aka.ms/teamsfx-basic-ai-chatbot#handle-messages-with-image)

## 📚 **Documentation Complète**

### 🎯 **État Actuel (v1.7.0-step6-application-deployment)**
- **Infrastructure**: 100% déployée ✅
- **Application**: Déployée, configuration pendante ⚠️
- **Environment**: DEV-05 Azure Canada Central ✅
- **Next Phase**: Environment variables configuration

### 📖 **Documentation Technique**
Pour une documentation détaillée, consultez le dossier `docs/` :

- **[docs/README.md](docs/README.md)** - 📚 Index de navigation de toute la documentation
- **[docs/STATUS.md](docs/STATUS.md)** - 📊 Statut détaillé v1.7.0
- **[docs/DEPLOYMENT_LOG.md](docs/DEPLOYMENT_LOG.md)** - 🚀 Log de déploiement 18 août 2025
- **[docs/COMPLETE_ARCHITECTURE.md](docs/COMPLETE_ARCHITECTURE.md)** - 🏗️ Architecture complète end-to-end
- **[docs/MAKEFILE_GUIDE.md](docs/MAKEFILE_GUIDE.md)** - 🛠️ Guide complet du Makefile avec exemples
- **[docs/README_QUOTA.md](docs/README_QUOTA.md)** - 💼 Système de quota et Marketplace
- **[COMMIT_SUMMARY.md](COMMIT_SUMMARY.md)** - 📋 Résumé des changements v1.7.0
- **[TODO.md](TODO.md)** - ✅ État actuel et prochaines étapes

## Additional information and references

- [Microsoft 365 Agents Toolkit Documentations](https://docs.microsoft.com/microsoftteams/platform/toolkit/teams-toolkit-fundamentals)
- [Microsoft 365 Agents Toolkit CLI](https://aka.ms/teamsfx-toolkit-cli)
- [Microsoft 365 Agents Toolkit Samples](https://github.com/OfficeDev/TeamsFx-Samples)
