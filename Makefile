# =================================================================
# Makefile - Microsoft Marketplace Quota Management System
# Orchestration des scripts de déploiement et configuration
# =================================================================

.PHONY: help setup deploy configure validate clean test-config test-db all

# Configuration
SCRIPTS_DIR := scripts
CONFIG_DIR := config

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
	@echo "$(CYAN)Microsoft Marketplace Quota Management System$(NC)"
	@echo "$(CYAN)=================================================================$(NC)"
	@echo ""
	@echo "$(YELLOW)🎯 COMMANDES PRINCIPALES:$(NC)"
	@echo ""
	@echo "  $(GREEN)make setup$(NC)        - 🔧 Configuration initiale complète"
	@echo "  $(GREEN)make deploy$(NC)       - 🚀 Déploiement Azure infrastructure"
	@echo "  $(GREEN)make configure$(NC)    - ⚙️  Configuration post-déploiement"
	@echo "  $(GREEN)make validate$(NC)     - ✅ Validation complète du système"
	@echo "  $(GREEN)make all$(NC)          - 🎉 Processus complet (setup + deploy + configure + validate)"
	@echo ""
	@echo "$(YELLOW)🔧 COMMANDES DE DÉVELOPPEMENT:$(NC)"
	@echo ""
	@echo "  $(GREEN)make test-config$(NC)  - 🧪 Tester la configuration"
	@echo "  $(GREEN)make test-db$(NC)      - 💾 Tester la connexion base de données"
	@echo "  $(GREEN)make clean$(NC)        - 🧹 Nettoyer les fichiers temporaires"
	@echo "  $(GREEN)make status$(NC)       - 📊 Afficher le statut du système"
	@echo "  $(GREEN)make components$(NC)   - 📋 Afficher les composants Azure"
	@echo ""
	@echo "$(YELLOW)📋 COMMANDES INDIVIDUELLES:$(NC)"
	@echo ""
	@echo "  $(GREEN)make environment$(NC)  - 🌍 Configuration environnement seulement"
	@echo "  $(GREEN)make database$(NC)     - 💾 Configuration base de données seulement"
	@echo "  $(GREEN)make marketplace$(NC)  - 💼 Configuration Marketplace API seulement"
	@echo ""
	@echo "$(YELLOW)ℹ️  PRÉREQUIS:$(NC)"
	@echo "  - Azure CLI installé et connecté (az login)"
	@echo "  - Node.js et npm installés"
	@echo "  - WSL/Bash disponible"
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

## deploy: 🚀 Déploiement de l'infrastructure Azure
deploy:
	@echo "$(CYAN)Déploiement de l'infrastructure Azure...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/azure-deploy.sh
	@$(SCRIPTS_DIR)/azure-deploy.sh --show-config --create-resource-group

## configure: ⚙️ Configuration post-déploiement Azure
configure:
	@echo "$(CYAN)Configuration post-déploiement...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/azure-configure.sh
	@$(SCRIPTS_DIR)/azure-configure.sh

# ==================================================================
# ✅ COMMANDES DE VALIDATION ET TESTS
# ==================================================================

## validate: ✅ Validation complète du système
validate:
	@echo "$(CYAN)Validation complète du système...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/deployment-validate.sh
	@$(SCRIPTS_DIR)/deployment-validate.sh

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

## info: ℹ️ Informations sur l'architecture
info:
	@echo ""
	@echo "$(CYAN)=================================================================$(NC)"
	@echo "$(CYAN)ℹ️  INFORMATIONS ARCHITECTURE$(NC)"
	@echo "$(CYAN)=================================================================$(NC)"
	@echo ""
	@echo "$(YELLOW)🏗️  Composants principaux:$(NC)"
	@echo "  • Microsoft Teams Bot (Teams AI Library)"
	@echo "  • Azure API Management (Quota enforcement)"
	@echo "  • PostgreSQL Database (Azure Flexible Server)"
	@echo "  • Azure Key Vault (Secrets management)"
	@echo "  • Marketplace Integration (SaaS + Metering)"
	@echo ""
	@echo "$(YELLOW)📋 Scripts disponibles:$(NC)"
	@ls -1 $(SCRIPTS_DIR)/*.sh | sed 's/^/  • /'
	@echo ""
	@echo "$(YELLOW)📖 Documentation:$(NC)"
	@echo "  • Diagramme: docs/architecture-diagram.drawio"
	@echo "  • Composants Azure: docs/azure-components.md"
	@echo "  • Déploiement: DEPLOYMENT_SUMMARY.md"
	@echo "  • Migration: MIGRATION_COMPLETED.md"
	@echo ""

## components: 📋 Afficher la liste des composants Azure
components:
	@echo ""
	@echo "$(CYAN)=================================================================$(NC)"
	@echo "$(CYAN)📋 COMPOSANTS AZURE$(NC)"
	@echo "$(CYAN)=================================================================$(NC)"
	@echo ""
	@if [ -f "docs/azure-components.md" ]; then \
		echo "$(GREEN)📄 Documentation complète disponible dans: docs/azure-components.md$(NC)"; \
		echo ""; \
		echo "$(YELLOW)✅ Composants déployés:$(NC)"; \
		echo "  • Resource Group (rg-chatbottez-gpt-4-1-dev-02)"; \
		echo "  • PostgreSQL Flexible Server"; \
		echo "  • Key Vault"; \
		echo ""; \
		echo "$(YELLOW)🔄 Composants à déployer (Priorité Haute):$(NC)"; \
		echo "  • Bot Service"; \
		echo "  • App Service Plan"; \
		echo "  • App Service (Node.js)"; \
		echo "  • Application Registration"; \
		echo ""; \
		echo "$(YELLOW)🔄 Composants à déployer (Priorité Moyenne):$(NC)"; \
		echo "  • API Management"; \
		echo "  • Application Insights"; \
		echo "  • Storage Account"; \
		echo "  • Marketplace SaaS Offer"; \
		echo ""; \
		echo "$(CYAN)💰 Coût estimé total: ~110.50 CAD/mois$(NC)"; \
		echo "$(CYAN)📖 Voir le détail complet: docs/azure-components.md$(NC)"; \
	else \
		echo "$(RED)❌ Documentation des composants non trouvée$(NC)"; \
	fi
	@echo ""

# ==================================================================
# 🎛️ COMMANDES AVANCÉES
# ==================================================================

## dev-setup: 🧑‍💻 Configuration rapide pour développement
dev-setup: environment test-config
	@echo "$(GREEN)✅ Configuration développement prête!$(NC)"
	@echo "$(YELLOW)Pour démarrer: $(GREEN)npm run dev$(NC)"

## prod-deploy: 🏭 Déploiement production (avec validation)
prod-deploy: setup deploy configure validate
	@echo ""
	@echo "$(GREEN)🏭 Déploiement production terminé!$(NC)"
	@echo "$(YELLOW)⚠️  N'oubliez pas de configurer le monitoring en production$(NC)"

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
