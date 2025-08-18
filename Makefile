# =================================================================
# Makefile - Microsoft Marketplace Quota Management System
# Orchestration des scripts de déploiement et configuration
# =================================================================

.PHONY: help setup deploy configure validate clean test-config test-db status status-deployment deploy-dev06 deploy-app-dev06 deploy-dev06-full check-deps all

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
	@echo "  $(GREEN)make deploy$(NC)       - 🚀 Déploiement Azure infrastructure (legacy)"
	@echo "  $(GREEN)make deploy-dev06$(NC) - 🆕 Déploiement infrastructure dev-06 (recommandé)"
	@echo "  $(GREEN)make deploy-app-dev06$(NC) - 🚀 Déployer l'application vers dev-06"
	@echo "  $(GREEN)make deploy-dev06-full$(NC) - 🎯 Déploiement complet DEV-06 (infra + app)"
	@echo "  $(GREEN)make configure$(NC)    - ⚙️  Configuration post-déploiement"
	@echo "  $(GREEN)make validate$(NC)     - ✅ Validation complète du système"
	@echo "  $(GREEN)make all$(NC)          - 🎉 Processus complet (setup + deploy + configure + validate)"
	@echo ""
	@echo "$(YELLOW)🔧 COMMANDES DE DÉVELOPPEMENT:$(NC)"
	@echo ""
	@echo "  $(GREEN)make test-config$(NC)  - 🧪 Tester la configuration"
	@echo "  $(GREEN)make test-db$(NC)      - 💾 Tester la connexion base de données"
	@echo "  $(GREEN)make status$(NC)       - 📊 Afficher le statut du système"
	@echo "  $(GREEN)make status-deployment$(NC) - 📊 Vérifier l'état des déploiements"
	@echo "  $(GREEN)make check-deps$(NC)   - 🔍 Vérifier les dépendances système"
	@echo "  $(GREEN)make clean$(NC)        - 🧹 Nettoyer les fichiers temporaires"
	@echo ""
	@echo "$(YELLOW)ℹ️  PRÉREQUIS:$(NC)"
	@echo "  - Azure CLI installé et connecté (az login)"
	@echo "  - Node.js et npm installés"
	@echo "  - WSL/Bash disponible"
	@echo ""
	@echo "$(YELLOW)💡 DÉPLOIEMENT RECOMMANDÉ:$(NC)"
	@echo "  1. $(GREEN)make deploy-dev06-full$(NC) pour un déploiement complet"
	@echo "  2. Configuration manuelle des variables d'environnement via Azure Portal"
	@echo "  3. $(GREEN)make status$(NC) pour vérifier l'état"
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

## deploy-dev06: 🆕 Déploiement infrastructure dev-06 (clean redeploy)
deploy-dev06:
	@echo "$(CYAN)Déploiement infrastructure vers dev-06 (redéploiement propre)...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/deploy-infrastructure-dev06.sh
	@$(SCRIPTS_DIR)/deploy-infrastructure-dev06.sh

## deploy-app-dev06: 🚀 Déployer l'application vers dev-06
deploy-app-dev06:
	@echo "$(CYAN)Déploiement de l'application vers dev-06...$(NC)"
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

## deploy-dev06-full: 🎯 Déploiement complet DEV-06 (infrastructure + application)
deploy-dev06-full: deploy-dev06 deploy-app-dev06
	@echo ""
	@echo "$(GREEN)🎉 DÉPLOIEMENT COMPLET DEV-06 TERMINÉ!$(NC)"
	@echo ""
	@echo "$(CYAN)🚀 Votre système DEV-06 est maintenant déployé!$(NC)"
	@echo ""
	@echo "$(YELLOW)Prochaines étapes:$(NC)"
	@echo "  1. Vérifier l'application: $(GREEN)make status$(NC)"
	@echo "  2. Configurer les variables d'environnement via Azure Portal"
	@echo "  3. Tester les fonctionnalités Microsoft Teams"
	@echo ""

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
