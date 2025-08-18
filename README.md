# ChatBottez GPT-4.1 - Teams AI Chatbot with Marketplace Quota Management

> **🚀 DEPLOYED VERSION v1.7.0**  
> **Application Status**: ✅ Deployed to Azure - ⚠️ Configuration pending  
> **Live URL**: https://chatbottez-gpt41-app-rnukfj.azurewebsites.net  
> **Infrastructure**: Azure Canada Central (dev-05)

This app template is built on top of [Teams AI library](https://aka.ms/teams-ai-library).
It showcases an agent app that responds to user questions like ChatGPT with **Microsoft Commercial Marketplace integration** and **quota management**. This enables your users to talk with the AI agent in Teams while respecting subscription limits.

## � **Current Status v1.7.0**

### ✅ **Deployed Infrastructure**
- **Azure Environment**: DEV-05 (Canada Central)
- **Resource Group**: `rg-chatbottez-gpt-4-1-dev-05`
- **Web Application**: https://chatbottez-gpt41-app-rnukfj.azurewebsites.net
- **Database**: PostgreSQL Flexible Server (operational)
- **Key Vault**: OpenAI keys securely stored
- **Monitoring**: Application Insights configured

### ⚠️ **Known Issues**
- **Environment Variables**: Configuration pending via Azure Portal
- **Application Status**: HTTP 500 (config required)

### 🎯 **Next Steps**
1. Configure environment variables via Azure Portal
2. Test application functionality
3. Complete Teams Bot registration

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

### 🎯 **Option 1: Use Deployed Application (Recommended)**
The application is already deployed and ready! You just need to configure environment variables:

1. **Access Azure Portal**: Go to `chatbottez-gpt41-app-rnukfj` App Service
2. **Configure Variables**: Set environment variables via Azure Portal
3. **Test Application**: Verify functionality at https://chatbottez-gpt41-app-rnukfj.azurewebsites.net

### 🛠️ **Option 2: Local Development**
For development and testing:

1. First, select the Microsoft 365 Agents Toolkit icon on the left in the VS Code toolbar.
1. In file *env/.env.playground.user*, fill in your Azure OpenAI key `SECRET_AZURE_OPENAI_API_KEY=<your-key>`, endpoint `AZURE_OPENAI_ENDPOINT=<your-endpoint>`, and deployment name `AZURE_OPENAI_DEPLOYMENT_NAME=<your-deployment>`.

### 🔧 **Option 3: Deploy New Infrastructure**
If you want to deploy your own infrastructure, use the WSL deployment script:

```bash
# Deploy complete infrastructure and application
./scripts/deploy-app-dev05-wsl.sh

# Or use Makefile commands (alternative)
make help

# Déploiement complet (setup + deploy + configure + validate)
make all

# Ou étape par étape :
make setup      # Configuration initiale (environnement + base de données + marketplace)
make deploy     # Déploiement infrastructure Azure
make configure  # Configuration post-déploiement
make validate   # Validation complète du système

# Commandes de développement
make dev-setup  # Configuration rapide pour développement
make test-config # Tester la configuration
make status     # Afficher le statut du système
```

## 📋 Configuration Manuelle (Alternative)

Si vous préférez configurer manuellement :

1. **Environment Setup**: Run the environment configuration script:
   ```bash
   # Bash/WSL (Recommandé)
   ./scripts/environment-setup.sh
   ```
   This will create `.env.local` with your Azure tenant ID and generate a JWT secret.
1. **Database Setup**:
   - Install PostgreSQL (see [docs/INSTALL_POSTGRESQL.md](./docs/INSTALL_POSTGRESQL.md) for Windows guide)
   - Run the database setup script:
     ```bash
     # Bash/WSL (Recommandé)
     ./scripts/database-setup.sh
     
     ```
   - Test the database connection: `npm run test:db`
1. Configure remaining variables in `.env.local` (marketplace credentials, Azure services, etc.)
1. Press F5 to start debugging which launches your app in Microsoft 365 Agents Playground using a web browser. Select `Debug in Microsoft 365 Agents Playground`.
1. You can send any message to get a response from the agent.

## 🏭 Déploiement Production

### Avec Makefile (Recommandé)

```bash
# Déploiement production complet avec validation
make prod-deploy

# Ou pour plus de contrôle :
make setup       # Configuration initiale
make deploy      # Déploiement Azure infrastructure
make configure   # Configuration APIM et services
make validate    # Tests complets (15 validations)
```

### Configuration Manuelle Production

For production deployment with marketplace integration:

1. **Configure Marketplace Variables**: Copy `.env.example` to your production environment and fill in:
   ```bash
   MARKETPLACE_API_BASE=https://marketplaceapi.microsoft.com
   MARKETPLACE_API_KEY=your-marketplace-api-key
   DIMENSION_NAME=question
   INCLUDED_QUOTA_PER_MONTH=300
   ```

2. **Deploy APIM Infrastructure**: Use the provided deployment scripts:
   ```bash
   # Déploiement automatisé
   ./scripts/azure-deploy.sh --show-config --create-resource-group
     --parameters publisherEmail=your@email.com publisherName="Your Company"
   ```

3. **Setup Database**: Run the database schema:
   ```bash
   psql -d your_database -f src/db/schema.sql
   ```

4. **Deploy Application**: Follow standard Microsoft 365 Agents Toolkit deployment process.

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

The following are Microsoft 365 Agents Toolkit specific project files. You can [visit a complete guide on Github](https://github.com/OfficeDev/TeamsFx/wiki/Teams-Toolkit-Visual-Studio-Code-v5-Guide#overview) to understand how Microsoft 365 Agents Toolkit works.

| File                                 | Contents                                           |
| - | - |
|`m365agents.yml`|This is the main Microsoft 365 Agents Toolkit project file. The project file defines two primary things:  Properties and configuration Stage definitions. |
|`m365agents.local.yml`|This overrides `m365agents.yml` with actions that enable local execution and debugging.|
|`m365agents.playground.yml`| This overrides `m365agents.yml` with actions that enable local execution and debugging in Microsoft 365 Agents Playground.|

| File                                 | Contents                                           |
| - | - |
|`m365agents.yml`|This is the main Microsoft 365 Agents Toolkit project file. The project file defines two primary things:  Properties and configuration Stage definitions. |
|`m365agents.local.yml`|This overrides `m365agents.yml` with actions that enable local execution and debugging.|
|`m365agents.playground.yml`| This overrides `m365agents.yml` with actions that enable local execution and debugging in Microsoft 365 Agents Playground.|

## Extend the template

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
