# =================================================================
# Makefile - Microsoft Marketplace Quota Management System
# Orchestration des scripts de déploiement et configuration
# =================================================================

.PHONY: help setup deploy configure validate clean test-config test-db status status-deployment deploy-dev06 deploy-app-dev06 deploy-dev06-full check-deps all env-local-create bot-credentials-setup-dev06 reset teamsfx-set-subscription

# Configuration
SCRIPTS_DIR := scripts
CONFIG_DIR := config

# Azure Configuration - Microsoft Azure Sponsorship
AZURE_SUBSCRIPTION_ID := 0f1323ea-0f29-4187-9872-e1cf15d677de
AZURE_SUBSCRIPTION_NAME := Microsoft Azure Sponsorship
AZURE_TENANT_ID := aba0984a-85a2-4fd4-9ae5-0a45d7efc9d2
AZURE_TENANT_ID := aba0984a-85a2-4fd4-9ae5-0a45d7efc9d2

# Couleurs pour l'output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

# ==================================================================
# 🎯 COMMANDES PRINCIPALES
# ==================================================================

## help: 📋 Afficher cette aide
help:
	@echo ""
	@echo "$(CYAN)=================================================================$(NC)"
	@echo "$(CYAN)📚 CHATBOTTEZ GPT-4.1 - SYSTÈME DE GESTION$(NC)"
	@echo "$(CYAN)=================================================================$(NC)"
	@echo ""
	@echo "$(YELLOW)⚡ COMMANDES RAPIDES:$(NC)"
	@echo "  $(GREEN)make setup$(NC)                     🔧 Configuration initiale complète"
	@echo "  $(GREEN)make teamsfx-dev06-full$(NC)        🌟 Déploiement complet avec TeamsFx (RECOMMANDÉ)"
	@echo "  $(GREEN)make deploy-dev06-full$(NC)         � Déploiement complet legacy (scripts personnalisés)"
	@echo "  $(GREEN)make status$(NC)                    📊 Vérifier l'état du système"
	@echo ""
	@echo "$(YELLOW)🌟 MICROSOFT 365 AGENTS TOOLKIT (MÉTHODE NATIVE):$(NC)"
	@echo "  $(GREEN)make teamsfx-install$(NC)           📦 Installer TeamsFx CLI"
	@echo "  $(GREEN)make teamsfx-login$(NC)             🔐 Se connecter aux services M365 (Azure Sponsorship)"
	@echo "  $(GREEN)make teamsfx-set-subscription$(NC)  ⚙️ Configurer subscription Azure Sponsorship"
	@echo "  $(GREEN)make teamsfx-env-check$(NC)         ✅ Vérifier l'environnement TeamsFx"
	@echo "  $(GREEN)make teamsfx-build$(NC)             🔨 Construire l'application"
	@echo "  $(GREEN)make teamsfx-provision-dev06$(NC)   🏗️ Provisionner l'infrastructure"
	@echo "  $(GREEN)make teamsfx-deploy-dev06$(NC)      🚀 Déployer l'application"
	@echo "  $(GREEN)make teamsfx-publish-dev06$(NC)     📱 Publier dans Teams"
	@echo "  $(GREEN)make teamsfx-preview-dev06$(NC)     👀 Prévisualiser dans Teams"
	@echo "  $(GREEN)make teamsfx-status-dev06$(NC)      📊 Statut de l'application"
	@echo "  $(GREEN)make teamsfx-logs-dev06$(NC)        📋 Consulter les logs"
	@echo "  $(GREEN)make teamsfx-clean-dev06$(NC)       🧹 Nettoyer l'environnement"
	@echo ""
	@echo "$(YELLOW)🏗️ CONFIGURATION & ENVIRONNEMENT:$(NC)"
	@echo "  $(GREEN)make env-local-create$(NC)          🔑 Créer le fichier .env.local automatiquement"
	@echo "  $(GREEN)make environment$(NC)               🌍 Configuration environnement"
	@echo "  $(GREEN)make database$(NC)                  💾 Configuration base de données"
	@echo "  $(GREEN)make marketplace$(NC)               💼 Configuration API Marketplace"
	@echo ""
	@echo "$(YELLOW)� DÉPLOIEMENT LEGACY (Scripts personnalisés):$(NC)"
	@echo "  $(GREEN)make deploy$(NC)                    🚀 Déploiement infrastructure Azure"
	@echo "  $(GREEN)make configure$(NC)                 ⚙️ Configuration post-déploiement"
	@echo "  $(GREEN)make deploy-dev06$(NC)              🆕 Déploiement infrastructure dev-06"
	@echo "  $(GREEN)make deploy-app-dev06$(NC)          � Déployer application dev-06"
	@echo "  $(GREEN)make bot-credentials-setup-dev06$(NC) 🔐 Régénérer credentials Bot (dev-06)"
	@echo ""
	@echo "$(YELLOW)✅ VALIDATION & TESTS:$(NC)"
	@echo "  $(GREEN)make validate$(NC)                  ✅ Validation complète du système"
	@echo "  $(GREEN)make test-config$(NC)               🧪 Tester la configuration"
	@echo "  $(GREEN)make test-db$(NC)                   💾 Tester la connexion DB"
	@echo "  $(GREEN)make check-deps$(NC)                🔍 Vérifier les dépendances"
	@echo ""
	@echo "$(YELLOW)📊 MONITORING & DIAGNOSTIC:$(NC)"
	@echo "  $(GREEN)make status$(NC)                    📊 Statut général du système"
	@echo "  $(GREEN)make status-deployment$(NC)         📊 État des déploiements Azure"
	@echo "  $(GREEN)make teamsfx-account-status$(NC)    � Statut des comptes TeamsFx"
	@echo ""
	@echo "$(YELLOW)🛠️ UTILITAIRES:$(NC)"
	@echo "  $(GREEN)make clean$(NC)                     🧹 Nettoyer fichiers temporaires"
	@echo "  $(GREEN)make scripts-cleanup$(NC)          🧹 Nettoyer scripts obsolètes"
	@echo "  $(GREEN)make reset$(NC)                     🔄 RESET COMPLET - Tout remettre à neuf"
	@echo "  $(GREEN)make purge-dev06$(NC)               ♻ Purger ressources soft-deleted"
	@echo ""
	@echo "$(CYAN)=================================================================$(NC)"
	@echo "$(YELLOW)💡 WORKFLOW RECOMMANDÉ (Microsoft 365 Agents Toolkit):$(NC)"
	@echo "$(CYAN)=================================================================$(NC)"
	@echo "  1. $(GREEN)make setup$(NC)                   # Configuration initiale"
	@echo "  2. $(GREEN)make teamsfx-install$(NC)         # Installer TeamsFx CLI"
	@echo "  3. $(GREEN)make teamsfx-login$(NC)           # Se connecter aux services"
	@echo "  4a. $(GREEN)make teamsfx-provision-dev06$(NC) # Provisionner infrastructure"
	@echo "  4b. $(GREEN)make teamsfx-deploy-dev06$(NC)    # Déployer application"
	@echo "  4c. $(GREEN)make teamsfx-publish-dev06$(NC)   # Publier dans Teams"
	@echo "  OU  $(GREEN)make teamsfx-dev06-full$(NC)      # Déploiement complet (4a+4b+4c)"
	@echo "  5. $(GREEN)make teamsfx-preview-dev06$(NC)   # Tester dans Teams"
	@echo ""
	@echo "$(CYAN)=================================================================$(NC)"
	@echo "$(YELLOW)💡 WORKFLOW LEGACY (Scripts personnalisés):$(NC)"
	@echo "$(CYAN)=================================================================$(NC)"
	@echo "  1. $(GREEN)make setup$(NC)                   # Configuration initiale"
	@echo "  2a. $(GREEN)make provision-dev06$(NC)        # Provisionner infrastructure"
	@echo "  2b. $(GREEN)make deploy-dev06$(NC)           # Déployer application (inclut 2a)"
	@echo "  OU  $(GREEN)make deploy-dev06-full$(NC)       # Déploiement complet (2a+2b)"
	@echo "  3. $(GREEN)make validate$(NC)                # Validation finale"
	@echo ""
	@echo "$(BLUE)📖 Documentation: docs/README.md$(NC)"
	@echo "$(BLUE)🔧 Aide technique: docs/DEV06_DEPLOYMENT_GUIDE.md$(NC)"
	@echo ""

## all: 🎉 Processus de déploiement complet
all: setup deploy configure validate
	@echo ""
	@echo "$(GREEN)=================================================================$(NC)"
	@echo "$(GREEN)🎉 DÉPLOIEMENT COMPLET TERMINÉ AVEC SUCCÈS!$(NC)"
	@echo "$(GREEN)=================================================================$(NC)"
	@echo ""
	@echo "$(CYAN)🚀 Votre système est maintenant prêt à utiliser!$(NC)"
	@echo ""
	@echo "$(YELLOW)Prochaines étapes:$(NC)"
	@echo "  1. Démarrer l'application: $(GREEN)npm run dev$(NC)"
	@echo "  2. Tester les fonctionnalités Microsoft Teams"
	@echo "  3. Vérifier les quotas dans Azure Portal"
	@echo ""

# ==================================================================
# 🔧 COMMANDES DE CONFIGURATION
# ==================================================================

## setup: 🔧 Configuration initiale complète (environnement + database + marketplace)
setup: environment database marketplace
	@echo ""
	@echo "$(GREEN)✅ Configuration initiale terminée!$(NC)"
	@echo "$(YELLOW)Prochaine étape: $(GREEN)make deploy$(NC)"

## env-local-create: 🔑 Créer le fichier .env.local avec valeurs générées automatiquement
env-local-create:
	@echo "$(CYAN)Création du fichier env/.env.local...$(NC)"
	@if [ -f "env/.env.local" ]; then \
		echo "$(YELLOW)⚠️  Le fichier env/.env.local existe déjà!$(NC)"; \
		echo "$(YELLOW)Voulez-vous le remplacer? (y/N):$(NC)"; \
		read -r response; \
		if [ "$$response" != "y" ] && [ "$$response" != "Y" ]; then \
			echo "$(RED)❌ Opération annulée$(NC)"; \
			exit 1; \
		fi; \
		cp env/.env.local env/.env.local.backup; \
		echo "$(GREEN)✅ Sauvegarde créée: env/.env.local.backup$(NC)"; \
	fi
	@echo "$(CYAN)🔑 Génération de la clé JWT sécurisée...$(NC)"
	@JWT_KEY=$$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"); \
	TENANT_ID=$$(az account show --query "tenantId" -o tsv 2>/dev/null || echo "to-be-configured"); \
	echo "$(CYAN)📝 Création du fichier de configuration...$(NC)"; \
	printf '%s\n' \
		'# =================================================================' \
		'# Microsoft Teams AI Chatbot - Configuration Locale' \
		'# =================================================================' \
		'# ⚠️ IMPORTANT: Ce fichier contient des secrets - Ne jamais commiter !' \
		"# Généré automatiquement le $$(date '+%Y-%m-%d %H:%M:%S')" \
		'' \
		'# =================================================================' \
		'# Microsoft Teams Framework - Built-in Variables' \
		'# =================================================================' \
		'TEAMSFX_ENV=local' \
		'APP_NAME_SUFFIX=local' \
		'' \
		'# Azure Tenant Configuration' \
		"TENANT_ID=$$TENANT_ID" \
		'' \
		'# Teams App Configuration (À compléter après déploiement)' \
		'BOT_ID=to-be-filled-after-deployment' \
		'TEAMS_APP_ID=to-be-filled-after-deployment' \
		'BOT_DOMAIN=to-be-filled-with-ngrok-or-azure-domain' \
		'BOT_ENDPOINT=https://to-be-filled-with-ngrok-or-azure-domain' \
		'' \
		'# =================================================================' \
		'# Security - JWT Secret Key (Généré automatiquement)' \
		'# =================================================================' \
		"JWT_SECRET_KEY=$$JWT_KEY" \
		'' \
		'# =================================================================' \
		'# Database Configuration (Local Development)' \
		'# =================================================================' \
		'DB_TYPE=postgresql' \
		'DB_HOST=localhost' \
		'DB_PORT=5432' \
		'DB_NAME=marketplace_quota' \
		'DB_USER=marketplace_user' \
		'DB_PASSWORD=local-dev-password-123' \
		'' \
		'# Database connection string for application' \
		'DATABASE_URL=postgresql://marketplace_user:local-dev-password-123@localhost:5432/marketplace_quota' \
		'' \
		'# =================================================================' \
		'# Azure Database Configuration (Production - DEV-06)' \
		'# =================================================================' \
		'AZURE_DATABASE_SERVER=to-be-filled-after-deployment' \
		'AZURE_DATABASE_NAME=marketplace_quota' \
		'AZURE_KEY_VAULT_NAME=to-be-filled-after-deployment' \
		'AZURE_RESOURCE_GROUP=rg-chatbottez-gpt-4-1-dev-06' \
		'AZURE_LOCATION=Canada Central' \
		'' \
		'# =================================================================' \
		'# Azure OpenAI Configuration (À configurer)' \
		'# =================================================================' \
		'AZURE_OPENAI_API_KEY=to-be-filled-from-keyvault-or-shared-service' \
		'AZURE_OPENAI_ENDPOINT=https://to-be-filled.openai.azure.com/' \
		'AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4' \
		'AZURE_OPENAI_API_VERSION=2024-02-15-preview' \
		'' \
		'# =================================================================' \
		'# Microsoft Marketplace Configuration' \
		'# =================================================================' \
		'MARKETPLACE_API_BASE=https://marketplaceapi.microsoft.com' \
		'MARKETPLACE_API_KEY=to-be-filled-with-marketplace-key' \
		'MARKETPLACE_SUBSCRIPTION_API_VERSION=2018-08-31' \
		'MARKETPLACE_METERING_API_VERSION=2018-08-31' \
		'' \
		'# Quota Settings' \
		'DIMENSION_NAME=question' \
		'INCLUDED_QUOTA_PER_MONTH=300' \
		'OVERAGE_ENABLED=false' \
		'OVERAGE_PRICE_PER_QUESTION=0.01' \
		'' \
		'# =================================================================' \
		'# Monitoring & Logging' \
		'# =================================================================' \
		'LOG_LEVEL=info' \
		'AUDIT_LOG_ENABLED=true' \
		'APPLICATION_INSIGHTS_CONNECTION_STRING=to-be-filled-after-deployment' \
		'' \
		'# =================================================================' \
		'# Environment & Development' \
		'# =================================================================' \
		'NODE_ENV=development' \
		'PORT=3978' \
		'' \
		'# =================================================================' \
		'# Microsoft Bot Framework' \
		'# =================================================================' \
		'MicrosoftAppType=MultiTenant' \
		'MicrosoftAppId=to-be-filled-after-deployment' \
		'MicrosoftAppPassword=to-be-filled-after-deployment' \
		'BOT_PASSWORD=to-be-filled-after-deployment' \
		'' \
		'# =================================================================' \
		'# NOTES DE CONFIGURATION:' \
		'# =================================================================' \
		'# 1. Ce fichier est créé automatiquement avec des valeurs par défaut' \
		'# 2. Les valeurs "to-be-filled-*" doivent être complétées après le déploiement' \
		'# 3. Les secrets doivent être récupérés depuis Azure Key Vault en production' \
		'# 4. JWT_SECRET_KEY et TENANT_ID sont déjà configurés automatiquement' \
		'# 5. Utilisez '"'"'make deploy-dev06-full'"'"' pour déployer l'"'"'infrastructure' \
		> env/.env.local
	@echo "$(GREEN)✅ Fichier env/.env.local créé avec succès!$(NC)"
	@echo "$(YELLOW)🔑 JWT Secret Key générée automatiquement$(NC)"
	@echo "$(YELLOW)🏢 Tenant ID configuré automatiquement$(NC)"
	@echo "$(CYAN)📝 Prochaines étapes:$(NC)"
	@echo "  1. $(GREEN)make deploy-dev06-full$(NC) pour déployer l'infrastructure"
	@echo "  2. Compléter les valeurs manquantes après le déploiement"
	@echo "  3. $(GREEN)make status$(NC) pour vérifier la configuration"

## environment: 🌍 Configuration de l'environnement de développement
environment:
	@echo "$(CYAN)[1/3] Configuration de l'environnement...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/environment-setup.sh
	@$(SCRIPTS_DIR)/environment-setup.sh

## database: 💾 Configuration de la base de données
database:
	@echo "$(CYAN)[2/3] Configuration de la base de données...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/database-setup.sh
	@$(SCRIPTS_DIR)/database-setup.sh

## marketplace: 💼 Configuration de l'API Marketplace
marketplace:
	@echo "$(CYAN)[3/3] Configuration Marketplace API...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/marketplace-setup.sh
	@$(SCRIPTS_DIR)/marketplace-setup.sh -C -n 'chatbottez-marketplace' -o marketplace.env

# ==================================================================
# 🚀 COMMANDES DE DÉPLOIEMENT
# ==================================================================

## deploy: 🚀 Déploiement de l'infrastructure Azure (méthode legacy)
deploy:
	@echo "$(CYAN)Déploiement de l'infrastructure Azure (méthode legacy)...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/azure-deploy.sh
	@$(SCRIPTS_DIR)/azure-deploy.sh --show-config --create-resource-group

## configure: ⚙️ Configuration post-déploiement Azure
configure:
	@echo "$(CYAN)Configuration post-déploiement...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/azure-configure.sh
	@$(SCRIPTS_DIR)/azure-configure.sh

# ==================================================================
# 🌟 MICROSOFT 365 AGENTS TOOLKIT - DÉPLOIEMENT NATIF
# ==================================================================

## teamsfx-env-check: ✅ Vérifier l'environnement TeamsFx
teamsfx-env-check:
	@echo "$(CYAN)Vérification de l'environnement Microsoft 365 Agents Toolkit...$(NC)"
	@echo ""
	@echo "$(YELLOW)🔍 Vérification des fichiers de configuration:$(NC)"
	@if [ -f "env/.env.dev06" ]; then \
		echo "  ✅ env/.env.dev06 présent"; \
		if grep -q "AZURE_OPENAI_API_KEY=" env/.env.dev06 && [ "$$(grep -c '^AZURE_OPENAI_API_KEY=.*[a-zA-Z0-9]' env/.env.dev06)" -gt 0 ]; then \
			echo "  ✅ Clé API OpenAI configurée"; \
		else \
			echo "  ⚠️  Clé API OpenAI non configurée"; \
		fi; \
	else \
		echo "  ❌ env/.env.dev06 manquant"; \
		exit 1; \
	fi
	@if [ -f "m365agents.dev06.yml" ]; then \
		echo "  ✅ m365agents.dev06.yml présent"; \
	else \
		echo "  ❌ m365agents.dev06.yml manquant"; \
		exit 1; \
	fi
	@if [ -f ".vscode/tasks.json" ]; then \
		echo "  ✅ VS Code tasks configurées"; \
	else \
		echo "  ⚠️  VS Code tasks non configurées"; \
	fi
	@echo ""
	@echo "$(YELLOW)🛠️  Outils TeamsFx:$(NC)"
	@if command -v teamsfx >/dev/null 2>&1; then \
		echo "  ✅ TeamsFx CLI installé"; \
		teamsfx --version | sed 's/^/    Version: /'; \
	else \
		echo "  ❌ TeamsFx CLI manquant"; \
		echo "    📦 Installation: npm install -g @microsoft/teamsfx-cli"; \
	fi
	@echo ""

## teamsfx-build: 🔨 Construire l'application pour TeamsFx
teamsfx-build:
	@echo "$(CYAN)Construction de l'application pour TeamsFx...$(NC)"
	@echo ""
	@echo "$(YELLOW)📦 Installation des dépendances...$(NC)"
	@npm install || { echo "$(RED)❌ Échec installation npm$(NC)"; exit 1; }
	@echo ""
	@echo "$(YELLOW)🔨 Compilation TypeScript...$(NC)"
	@npm run build || { echo "$(RED)❌ Échec compilation TypeScript$(NC)"; exit 1; }
	@echo ""
	@echo "$(YELLOW)✅ Vérification des fichiers de sortie...$(NC)"
	@if [ -f "lib/src/index.js" ]; then \
		echo "  ✅ lib/src/index.js généré"; \
	else \
		echo "  ❌ lib/src/index.js manquant"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Construction terminée!$(NC)"

## teamsfx-provision-dev06: 🏗️ Provisionner l'infrastructure avec TeamsFx (DEV-06)
teamsfx-provision-dev06: teamsfx-env-check teamsfx-build
	@echo "$(CYAN)Provisionnement de l'infrastructure DEV-06 avec TeamsFx...$(NC)"
	@echo ""
	@echo "$(YELLOW)🏗️ Démarrage du provisionnement...$(NC)"
	@if command -v teamsfx >/dev/null 2>&1; then \
		teamsfx provision --env dev06 --verbose || { \
			echo "$(RED)❌ Échec du provisionnement TeamsFx$(NC)"; \
			echo "$(YELLOW)💡 Vérifiez vos permissions Microsoft 365$(NC)"; \
			echo "$(YELLOW)💡 Utilisez: teamsfx account login$(NC)"; \
			exit 1; \
		}; \
	else \
		echo "$(RED)❌ TeamsFx CLI non installé$(NC)"; \
		echo "$(YELLOW)📦 Installation: npm install -g @microsoft/teamsfx-cli$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Provisionnement terminé!$(NC)"

## teamsfx-deploy-dev06: 🚀 Déployer l'application avec TeamsFx (DEV-06)
teamsfx-deploy-dev06:
	@echo "$(CYAN)Déploiement de l'application DEV-06 avec TeamsFx...$(NC)"
	@echo ""
	@echo "$(YELLOW)🚀 Démarrage du déploiement...$(NC)"
	@teamsfx deploy --env dev06 --verbose || { \
		echo "$(RED)❌ Échec du déploiement TeamsFx$(NC)"; \
		echo "$(YELLOW)💡 Vérifiez les logs ci-dessus pour plus de détails$(NC)"; \
		exit 1; \
	}
	@echo "$(GREEN)✅ Déploiement terminé!$(NC)"

## teamsfx-publish-dev06: 📱 Publier l'application Teams (DEV-06)
teamsfx-publish-dev06: teamsfx-deploy-dev06
	@echo "$(CYAN)Publication de l'application Teams DEV-06...$(NC)"
	@echo ""
	@echo "$(YELLOW)📱 Publication dans le catalogue Teams...$(NC)"
	@teamsfx publish --env dev06 --verbose || { \
		echo "$(RED)❌ Échec de la publication$(NC)"; \
		echo "$(YELLOW)💡 Vérifiez vos permissions d'administration Teams$(NC)"; \
		exit 1; \
	}
	@echo "$(GREEN)✅ Publication terminée!$(NC)"

## teamsfx-dev06-full: 🎯 Déploiement complet TeamsFx DEV-06 (provision + deploy + publish)
teamsfx-dev06-full: teamsfx-provision-dev06 teamsfx-deploy-dev06 teamsfx-publish-dev06
	@echo ""
	@echo "$(GREEN)🎉 DÉPLOIEMENT TEAMSFX DEV-06 COMPLET TERMINÉ!$(NC)"
	@echo ""
	@echo "$(CYAN)🚀 Votre application Microsoft Teams est déployée et publiée!$(NC)"
	@echo ""
	@echo "$(YELLOW)Lifecycle TeamsFx exécuté:$(NC)"
	@echo "  1. ✅ $(GREEN)Provision$(NC) : Infrastructure provisionnée"
	@echo "  2. ✅ $(GREEN)Deploy$(NC)    : Application déployée"
	@echo "  3. ✅ $(GREEN)Publish$(NC)   : Application publiée dans Teams"
	@echo ""
	@echo "$(YELLOW)Prochaines étapes:$(NC)"
	@echo "  1. Vérifier l'application: $(GREEN)make teamsfx-status-dev06$(NC)"
	@echo "  2. Tester dans Microsoft Teams"
	@echo "  3. Monitorer les logs: $(GREEN)make teamsfx-logs-dev06$(NC)"
	@echo ""

## teamsfx-status-dev06: 📊 Statut de l'application TeamsFx DEV-06
teamsfx-status-dev06:
	@echo "$(CYAN)Statut de l'application TeamsFx DEV-06...$(NC)"
	@echo ""
	@echo "$(YELLOW)📊 Informations sur l'environnement:$(NC)"
	@if [ -f "env/.env.dev06" ]; then \
		echo "  ✅ Configuration DEV-06 présente"; \
	else \
		echo "  ❌ Configuration DEV-06 manquante"; \
	fi
	@echo ""
	@echo "$(YELLOW)☁️  Ressources Azure:$(NC)"
	@az group show --name "rg-chatbottez-gpt-4-1-dev-06" --query "{Name:name, Location:location, State:properties.provisioningState}" --output table 2>/dev/null || echo "  ❌ Groupe de ressources non trouvé"
	@echo ""
	@echo "$(YELLOW)🚀 Application:$(NC)"
	@if az webapp show --name "app-chatbottez-gpt-4-1-dev-06" --resource-group "rg-chatbottez-gpt-4-1-dev-06" >/dev/null 2>&1; then \
		echo "  ✅ App Service actif"; \
		az webapp show --name "app-chatbottez-gpt-4-1-dev-06" --resource-group "rg-chatbottez-gpt-4-1-dev-06" --query "{Name:name, State:state, URL:defaultHostName}" --output table; \
	else \
		echo "  ❌ App Service non trouvé"; \
	fi

## teamsfx-logs-dev06: 📋 Consulter les logs de l'application DEV-06
teamsfx-logs-dev06:
	@echo "$(CYAN)Consultation des logs DEV-06...$(NC)"
	@echo ""
	@echo "$(YELLOW)📋 Logs récents de l'App Service:$(NC)"
	@az webapp log tail --name "app-chatbottez-gpt-4-1-dev-06" --resource-group "rg-chatbottez-gpt-4-1-dev-06" || { \
		echo "$(RED)❌ Impossible de récupérer les logs$(NC)"; \
		echo "$(YELLOW)💡 Vérifiez que l'application est déployée$(NC)"; \
	}

## teamsfx-preview-dev06: 👀 Prévisualiser l'application dans Teams
teamsfx-preview-dev06:
	@echo "$(CYAN)Prévisualisation de l'application Teams DEV-06...$(NC)"
	@teamsfx preview --env dev06 || { \
		echo "$(RED)❌ Échec de la prévisualisation$(NC)"; \
		echo "$(YELLOW)💡 Assurez-vous que l'application est déployée$(NC)"; \
	}

# ==================================================================
# ✅ COMMANDES DE VALIDATION ET TESTS
# ==================================================================

## validate: ✅ Validation complète du système
validate:
	@echo "$(CYAN)Validation complète du système...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/deployment-validate.sh
	@$(SCRIPTS_DIR)/deployment-validate.sh

## provision-dev06: �️ Provisionner l'infrastructure DEV-06 (méthode legacy)
provision-dev06:
	@echo "$(CYAN)Provisionnement infrastructure DEV-06 (méthode legacy)...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/deploy-infrastructure-dev06.sh
	@$(SCRIPTS_DIR)/deploy-infrastructure-dev06.sh

## deploy-dev06: 🚀 Déployer l'application DEV-06 (méthode legacy)
deploy-dev06: provision-dev06
	@echo "$(CYAN)Déploiement de l'application vers DEV-06 (méthode legacy)...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/deploy-app-dev06.sh
	@$(SCRIPTS_DIR)/deploy-app-dev06.sh

## deploy-app-dev06: 🚀 Déployer l'application vers dev-06 (méthode legacy) - DEPRECATED
deploy-app-dev06:
	@echo "$(YELLOW)⚠️  DEPRECATED: Utilisez 'make deploy-dev06' qui inclut provision + deploy$(NC)"
	@echo "$(CYAN)Déploiement de l'application vers dev-06 (méthode legacy)...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/deploy-app-dev06.sh
	@$(SCRIPTS_DIR)/deploy-app-dev06.sh

## test-config: 🧪 Tester la configuration
test-config:
	@echo "$(CYAN)Test de la configuration...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/config-test.sh
	@$(SCRIPTS_DIR)/config-test.sh

## test-db: 💾 Tester la connexion base de données
test-db:
	@echo "$(CYAN)Test de la connexion base de données...$(NC)"
	@if [ -f ".env.local" ]; then \
		npm run test:db || echo "$(YELLOW)⚠️  Test DB échoué - vérifiez DATABASE_URL dans .env.local$(NC)"; \
	else \
		echo "$(RED)❌ Fichier .env.local non trouvé. Exécutez d'abord: make setup$(NC)"; \
	fi

## status-deployment: 📊 Vérifier l'état des déploiements
status-deployment:
	@echo "$(CYAN)Vérification de l'état des déploiements Azure...$(NC)"
	@echo ""
	@echo "$(YELLOW)📊 DÉPLOIEMENTS EN COURS:$(NC)"
	@az deployment sub list --query "[?properties.provisioningState=='Running'].{Name:name, State:properties.provisioningState, Started:properties.timestamp, Location:location}" --output table 2>/dev/null || echo "$(RED)❌ Erreur lors de la récupération des déploiements$(NC)"
	@echo ""
	@echo "$(YELLOW)📊 DERNIERS DÉPLOIEMENTS (Tous états):$(NC)"
	@az deployment sub list --query "[?contains(name, 'complete-infrastructure')].{Name:name, State:properties.provisioningState, Started:properties.timestamp}" --output table --top 10 2>/dev/null || echo "$(RED)❌ Erreur lors de la récupération des déploiements$(NC)"
	@echo ""
	@echo "$(YELLOW)🏗️ RESOURCE GROUPS CHATBOTTEZ:$(NC)"
	@az group list --query "[?contains(name, 'chatbottez')].{Name:name, Location:location, State:properties.provisioningState}" --output table 2>/dev/null || echo "$(RED)❌ Erreur lors de la récupération des groupes de ressources$(NC)"
	@echo ""
	@echo "$(YELLOW)💡 COMMANDES UTILES:$(NC)"
	@echo "  • Surveiller un déploiement: $(GREEN)az deployment sub show --name <DEPLOYMENT_NAME>$(NC)"
	@echo "  • Voir les erreurs: $(GREEN)az deployment sub show --name <DEPLOYMENT_NAME> --query 'properties.error'$(NC)"
	@echo "  • Lister les ressources: $(GREEN)az resource list --resource-group <RG_NAME> --output table$(NC)"

# ==================================================================
# 🧹 COMMANDES UTILITAIRES
# ==================================================================

## clean: 🧹 Nettoyer les fichiers temporaires
clean:
	@echo "$(CYAN)Nettoyage des fichiers temporaires...$(NC)"
	@rm -f *.tmp
	@rm -f *.backup
	@rm -f temp_deploy.ps1
	@rm -f deployment-outputs.json
	@rm -f marketplace-temp.env
	@echo "$(GREEN)✅ Nettoyage terminé$(NC)"

## scripts-cleanup: 🧹 Nettoyer les scripts obsolètes
scripts-cleanup:
	@echo "$(CYAN)Nettoyage des scripts obsolètes...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/scripts-cleanup.sh
	@$(SCRIPTS_DIR)/scripts-cleanup.sh

## reset: 🔄 RESET COMPLET - Remettre tout à l'état neuf
reset:
	@echo ""
	@echo "$(RED)⚠️  ATTENTION: RESET COMPLET DU PROJET$(NC)"
	@echo "$(RED)🔥 Cette commande va supprimer DÉFINITIVEMENT:$(NC)"
	@echo "$(RED)   • Tous les groupes de ressources Azure$(NC)"
	@echo "$(RED)   • Toutes les configurations TeamsFx$(NC)"
	@echo "$(RED)   • Tous les fichiers temporaires$(NC)"
	@echo "$(RED)   • Toutes les ressources soft-deleted$(NC)"
	@echo ""
	@echo "$(YELLOW)🚨 CETTE ACTION EST IRRÉVERSIBLE!$(NC)"
	@echo ""
	@echo "$(CYAN)Exécution du script de reset complet...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/reset-complete.sh
	@$(SCRIPTS_DIR)/reset-complete.sh

# ==================================================================
# 🔍 COMMANDES DE DIAGNOSTIC
# ==================================================================

## status: 📊 Afficher le statut du système
status:
	@echo ""
	@echo "$(CYAN)=================================================================$(NC)"
	@echo "$(CYAN)📊 STATUT DU SYSTÈME$(NC)"
	@echo "$(CYAN)=================================================================$(NC)"
	@echo ""
	@echo "$(YELLOW)📁 Fichiers de configuration:$(NC)"
	@if [ -f "env/.env.local" ]; then echo "  ✅ env/.env.local"; else echo "  ❌ env/.env.local (manquant)"; fi
	@if [ -f "$(CONFIG_DIR)/azure.env" ]; then echo "  ✅ config/azure.env"; else echo "  ❌ config/azure.env (manquant)"; fi
	@if [ -f "marketplace.env" ]; then echo "  ✅ marketplace.env"; else echo "  ⚠️  marketplace.env (optionnel)"; fi
	@echo ""
	@echo "$(YELLOW)🛠️  Outils système:$(NC)"
	@if command -v az >/dev/null 2>&1; then echo "  ✅ Azure CLI"; else echo "  ❌ Azure CLI (requis)"; fi
	@if command -v node >/dev/null 2>&1; then echo "  ✅ Node.js"; else echo "  ❌ Node.js (requis)"; fi
	@if command -v npm >/dev/null 2>&1; then echo "  ✅ npm"; else echo "  ❌ npm (requis)"; fi
	@echo ""
	@echo "$(YELLOW)☁️  Azure:$(NC)"
	@if az account show >/dev/null 2>&1; then \
		echo "  ✅ Connecté à Azure"; \
		az account show --query "name" -o tsv | sed 's/^/    Abonnement: /'; \
	else \
		echo "  ❌ Non connecté à Azure (az login requis)"; \
	fi
	@echo ""
	@echo "$(YELLOW)🚀 Déploiements en cours:$(NC)"
	@if az deployment sub list --query "[?properties.provisioningState=='Running' && contains(name, 'chatbottez')]" --output table >/dev/null 2>&1; then \
		az deployment sub list --query "[?properties.provisioningState=='Running' && contains(name, 'chatbottez')].{Name:name, State:properties.provisioningState}" --output table 2>/dev/null || echo "  ✅ Aucun déploiement en cours"; \
	else \
		echo "  ✅ Aucun déploiement en cours"; \
	fi
	@echo ""
	@echo "$(YELLOW)📦 Resource Groups ChatBottez:$(NC)"
	@az group list --query "[?contains(name, 'chatbottez')].{Name:name, Location:location}" --output table 2>/dev/null || echo "  ❌ Erreur lors de la récupération"
	@echo ""

# ==================================================================
# 🎛️ COMMANDES AVANCÉES
# ==================================================================

## deploy-dev06-full: 🎯 Déploiement complet DEV-06 (provision + deploy) - MÉTHODE LEGACY
deploy-dev06-full: deploy-dev06
	@echo ""
	@echo "$(GREEN)🎉 DÉPLOIEMENT COMPLET DEV-06 TERMINÉ! (Méthode Legacy)$(NC)"
	@echo ""
	@echo "$(CYAN)🚀 Votre système DEV-06 est maintenant déployé!$(NC)"
	@echo ""
	@echo "$(YELLOW)Lifecycle Legacy exécuté:$(NC)"
	@echo "  1. ✅ $(GREEN)Provision$(NC) : Infrastructure déployée"
	@echo "  2. ✅ $(GREEN)Deploy$(NC)    : Application déployée"
	@echo ""
	@echo "$(YELLOW)Prochaines étapes:$(NC)"
	@echo "  1. Vérifier l'application: $(GREEN)make status$(NC)"
	@echo "  2. Configurer les variables d'environnement via Azure Portal"
	@echo "  3. Tester les fonctionnalités Microsoft Teams"
	@echo ""
	@echo "$(BLUE)💡 Pour utiliser la méthode native TeamsFx: $(GREEN)make teamsfx-dev06-full$(NC)"
	@echo ""

# ==================================================================
# 🌟 MICROSOFT 365 AGENTS TOOLKIT - UTILITAIRES
# ==================================================================

## teamsfx-install: 📦 Installer TeamsFx CLI
teamsfx-install:
	@echo "$(CYAN)Installation de TeamsFx CLI...$(NC)"
	@npm install -g @microsoft/teamsfx-cli || { \
		echo "$(RED)❌ Échec de l'installation$(NC)"; \
		echo "$(YELLOW)💡 Essayez avec sudo: sudo npm install -g @microsoft/teamsfx-cli$(NC)"; \
		exit 1; \
	}
	@echo "$(GREEN)✅ TeamsFx CLI installé!$(NC)"
	@teamsfx --version

## teamsfx-login: 🔐 Se connecter aux services Microsoft 365
teamsfx-login:
	@echo "$(CYAN)Connexion aux services Microsoft 365...$(NC)"
	@echo ""
	@echo "$(YELLOW)🔐 Connexion Azure...$(NC)"
	@teamsfx account login azure || { \
		echo "$(RED)❌ Échec connexion Azure$(NC)"; \
		exit 1; \
	}
	@echo ""
	@echo "$(YELLOW)⚙️  Configuration de la subscription Azure...$(NC)"
	@az account set --subscription "0f1323ea-0f29-4187-9872-e1cf15d677de" || { \
		echo "$(RED)❌ Échec configuration subscription$(NC)"; \
		echo "$(YELLOW)� Vérifiez que vous avez accès à Microsoft Azure Sponsorship$(NC)"; \
		exit 1; \
	}
	@echo "$(GREEN)✅ Subscription configurée: Microsoft Azure Sponsorship$(NC)"
	@echo ""
	@echo "$(YELLOW)�🔐 Connexion Microsoft 365...$(NC)"
	@teamsfx account login m365 || { \
		echo "$(RED)❌ Échec connexion M365$(NC)"; \
		echo "$(YELLOW)💡 Vérifiez vos permissions d'administration Teams$(NC)"; \
		exit 1; \
	}
	@echo ""
	@echo "$(YELLOW)🔍 Vérification des comptes configurés...$(NC)"
	@az account show --query "{subscription: name, id: id, tenant: tenantId}" -o table
	@echo ""
	@teamsfx account show | head -10
	@echo "$(GREEN)✅ Connexions établies avec Microsoft Azure Sponsorship!$(NC)"

## teamsfx-logout: 🚪 Se déconnecter des services
teamsfx-logout:
	@echo "$(CYAN)Déconnexion des services...$(NC)"
	@teamsfx account logout azure
	@teamsfx account logout m365
	@echo "$(GREEN)✅ Déconnexion terminée$(NC)"

## teamsfx-account-status: 👤 Vérifier le statut des comptes
teamsfx-account-status:
	@echo "$(CYAN)Statut des comptes Microsoft 365 Agents Toolkit...$(NC)"
	@echo ""
	@echo "$(YELLOW)🔍 Azure CLI:$(NC)"
	@az account show --query "{subscription: name, id: id, tenant: tenantId}" -o table || { \
		echo "$(RED)❌ Azure CLI non connecté$(NC)"; \
	}
	@echo ""
	@echo "$(YELLOW)🔍 TeamsFx:$(NC)"
	@teamsfx account show || { \
		echo "$(RED)❌ TeamsFx non connecté$(NC)"; \
	}

## teamsfx-set-subscription: ⚙️ Configurer la subscription Azure Sponsorship
teamsfx-set-subscription:
	@echo "$(CYAN)Configuration de la subscription Azure...$(NC)"
	@echo ""
	@echo "$(YELLOW)🔧 Définition de la subscription: $(AZURE_SUBSCRIPTION_NAME)$(NC)"
	@az account set --subscription "$(AZURE_SUBSCRIPTION_ID)" || { \
		echo "$(RED)❌ Échec configuration subscription$(NC)"; \
		echo "$(YELLOW)💡 Vérifiez que vous avez accès à $(AZURE_SUBSCRIPTION_NAME)$(NC)"; \
		echo "$(YELLOW)💡 ID: $(AZURE_SUBSCRIPTION_ID)$(NC)"; \
		exit 1; \
	}
	@echo "$(GREEN)✅ Subscription configurée: $(AZURE_SUBSCRIPTION_NAME)$(NC)"
	@echo ""
	@echo "$(YELLOW)🔍 Vérification:$(NC)"
	@az account show --query "{subscription: name, id: id, tenant: tenantId}" -o table
	@echo "$(YELLOW)☁️  Compte Azure:$(NC)"
	@teamsfx account show azure || echo "  ❌ Non connecté"
	@echo ""
	@echo "$(YELLOW)🏢 Compte Microsoft 365:$(NC)"
	@teamsfx account show m365 || echo "  ❌ Non connecté"

## teamsfx-clean-dev06: 🧹 Nettoyer l'environnement TeamsFx DEV-06
teamsfx-clean-dev06:
	@echo "$(CYAN)Nettoyage de l'environnement TeamsFx DEV-06...$(NC)"
	@echo ""
	@echo "$(YELLOW)⚠️  Cette action va supprimer les ressources DEV-06$(NC)"
	@read -p "Continuer? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo "$(CYAN)🧹 Suppression des ressources...$(NC)"; \
		az group delete --name "rg-chatbottez-gpt-4-1-dev-06" --yes --no-wait || echo "$(YELLOW)⚠️  Groupe de ressources non trouvé$(NC)"; \
		echo "$(GREEN)✅ Nettoyage initié$(NC)"; \
	else \
		echo "$(YELLOW)❌ Nettoyage annulé$(NC)"; \
	fi

## teamsfx-env-create-dev06: 📝 Créer la configuration d'environnement DEV-06
teamsfx-env-create-dev06:
	@echo "$(CYAN)Création de la configuration d'environnement DEV-06...$(NC)"
	@if [ ! -f "env/.env.dev06" ]; then \
		echo "$(YELLOW)📝 Création du fichier env/.env.dev06...$(NC)"; \
		mkdir -p env; \
		printf '%s\n' \
			'# =================================================================' \
			'# Microsoft 365 Agents Toolkit - Configuration DEV-06' \
			'# =================================================================' \
			'# ⚠️ IMPORTANT: Ce fichier contient des secrets - Ne jamais commiter !' \
			"# Généré automatiquement le $$(date '+%Y-%m-%d %H:%M:%S')" \
			'' \
			'# =================================================================' \
			'# TeamsFx Environment Configuration' \
			'# =================================================================' \
			'TEAMSFX_ENV=dev06' \
			'APP_NAME_SUFFIX=dev06' \
			'' \
			'# =================================================================' \
			'# Azure OpenAI Configuration (Partagé)' \
			'# =================================================================' \
			'AZURE_OPENAI_API_KEY=to-be-filled-manually' \
			'AZURE_OPENAI_ENDPOINT=https://openai-shared-canada-central.openai.azure.com/' \
			'AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4' \
			'AZURE_OPENAI_API_VERSION=2024-02-15-preview' \
			'' \
			'# =================================================================' \
			'# Azure Configuration (Auto-filled by TeamsFx)' \
			'# =================================================================' \
			'AZURE_SUBSCRIPTION_ID=to-be-filled-by-teamsfx' \
			'AZURE_RESOURCE_GROUP_NAME=rg-chatbottez-gpt-4-1-dev-06' \
			'AZURE_LOCATION=Canada Central' \
			'' \
			'# =================================================================' \
			'# Bot Configuration (Auto-filled by TeamsFx)' \
			'# =================================================================' \
			'BOT_ID=to-be-filled-by-teamsfx' \
			'BOT_PASSWORD=to-be-filled-by-teamsfx' \
			'TEAMS_APP_ID=to-be-filled-by-teamsfx' \
			'BOT_ENDPOINT=to-be-filled-by-teamsfx' \
			'BOT_DOMAIN=to-be-filled-by-teamsfx' \
			'' \
			'# =================================================================' \
			'# Application Configuration' \
			'# =================================================================' \
			'PORT=3978' \
			'NODE_ENV=production' \
			'LOG_LEVEL=info' \
			> env/.env.dev06; \
		echo "$(GREEN)✅ Fichier env/.env.dev06 créé$(NC)"; \
		echo "$(YELLOW)⚠️  N'oubliez pas de configurer AZURE_OPENAI_API_KEY$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Le fichier env/.env.dev06 existe déjà$(NC)"; \
	fi
	@if [ ! -f "m365agents.dev06.yml" ]; then \
		echo "$(YELLOW)📝 Création du fichier m365agents.dev06.yml...$(NC)"; \
		printf '%s\n' \
			'# =================================================================' \
			'# Microsoft 365 Agents Toolkit - Configuration de déploiement DEV-06' \
			'# =================================================================' \
			'# Fichier de configuration TeamsFx pour l'"'"'environnement DEV-06' \
			'# =================================================================' \
			'' \
			'version: 2.0.0' \
			'' \
			'environmentFolderPath: ./env' \
			'' \
			'provision:' \
			'  - uses: teamsApp/create' \
			'    with:' \
			'      name: ChatBottez-GPT-4.1-DEV-06' \
			'    writeToEnvironmentFile:' \
			'      teamsAppId: TEAMS_APP_ID' \
			'' \
			'  - uses: arm/deploy' \
			'    with:' \
			'      subscriptionId: $${{AZURE_SUBSCRIPTION_ID}}' \
			'      resourceGroupName: rg-chatbottez-gpt-4-1-dev-06' \
			'      templates:' \
			'        - path: ./infra/complete-infrastructure-dev06.bicep' \
			'          parameters: ./infra/complete-infrastructure-dev06.parameters.json' \
			'          deploymentName: chatbottez-infrastructure-dev06' \
			'      bicepCliVersion: v0.15.31' \
			'' \
			'deploy:' \
			'  - uses: azureAppService/zipDeploy' \
			'    with:' \
			'      artifactFolder: .' \
			'      ignoreFile: .webappignore' \
			'      resourceId: $${{AZURE_APP_SERVICE_RESOURCE_ID}}' \
			> m365agents.dev06.yml; \
		echo "$(GREEN)✅ Fichier m365agents.dev06.yml créé$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Le fichier m365agents.dev06.yml existe déjà$(NC)"; \
	fi

## purge-dev06: ♻ Purger ressources soft-deleted (APIM / KeyVault) pour DEV-06
purge-dev06:
	@echo "$(CYAN)Purge soft-deleted ressources DEV-06...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/purge-infra-dev-06.sh
	@$(SCRIPTS_DIR)/purge-infra-dev-06.sh --auto

## bot-credentials-setup-dev06: 🔐 Régénérer et configurer les identifiants Bot (App Registration) pour DEV-06
bot-credentials-setup-dev06:
	@echo "$(CYAN)Reset & configuration des credentials Bot (dev-06)...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/bot-credentials-setup-dev06.sh
	@$(SCRIPTS_DIR)/bot-credentials-setup-dev06.sh || { echo "$(RED)Échec génération credentials Bot$(NC)"; exit 1; }

## check-deps: 🔍 Vérifier les dépendances
check-deps:
	@echo "$(CYAN)Vérification des dépendances...$(NC)"
	@echo ""
	@echo "$(YELLOW)Dépendances système:$(NC)"
	@command -v az >/dev/null 2>&1 && echo "  ✅ Azure CLI" || echo "  ❌ Azure CLI manquant"
	@command -v node >/dev/null 2>&1 && echo "  ✅ Node.js" || echo "  ❌ Node.js manquant"
	@command -v npm >/dev/null 2>&1 && echo "  ✅ npm" || echo "  ❌ npm manquant"
	@command -v git >/dev/null 2>&1 && echo "  ✅ Git" || echo "  ❌ Git manquant"
	@echo ""
	@echo "$(YELLOW)Dépendances Node.js:$(NC)"
	@if [ -f "package.json" ]; then \
		if [ -d "node_modules" ]; then \
			echo "  ✅ node_modules installé"; \
		else \
			echo "  ⚠️  node_modules manquant - exécutez: npm install"; \
		fi; \
	else \
		echo "  ❌ package.json non trouvé"; \
	fi

# Valeur par défaut
.DEFAULT_GOAL := help
