# Makefile for Microsoft 365 Agents Cha	@if command -v atk >/dev/null 2>&1; then \
		echo "$(GREEN)✓$(NC) Microsoft 365 Agents Toolkit CLI installed"; \
		atk --version; \t GPT-4.1
# Created from Microsoft 365 Agents Toolkit

# Variables
PROJECT_NAME = chatbottez-gpt-4.1
ENV ?= dev
TEAMSFX_ENV ?= $(ENV)
NODE_VERSION = 18

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

##@ General

.PHONY: help
help: ## Display this help message
	@echo "$(GREEN)Microsoft 365 Agents ChatBot GPT-4.1 - Makefile Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: status
status: ## Show current project status
	@echo "$(GREEN)Project Status:$(NC)"
	@echo "  Project Name: $(PROJECT_NAME)"
	@echo "  Environment: $(ENV)"
	@echo "  TeamsFx Environment: $(TEAMSFX_ENV)"
	@echo "  Node Version: $(NODE_VERSION)"
	@echo ""
	@if [ -f "env/.env.$(ENV)" ]; then \
		echo "$(GREEN)✓$(NC) Environment file exists: env/.env.$(ENV)"; \
	else \
		echo "$(RED)✗$(NC) Environment file missing: env/.env.$(ENV)"; \
	fi
	@if command -v teamsapp >/dev/null 2>&1; then \
		echo "$(GREEN)✓$(NC) TeamsFx CLI is installed"; \
		teamsapp --version; \
	else \
		echo "$(RED)✗$(NC) TeamsFx CLI is not installed"; \
	fi

##@ Setup & Dependencies

.PHONY: install
install: ## Install all dependencies
	@echo "$(YELLOW)Installing dependencies...$(NC)"
	npm install
	@echo "$(GREEN)Dependencies installed successfully!$(NC)"

.PHONY: install-atk
install-atk: ## Install Microsoft 365 Agents Toolkit CLI globally
	@echo "$(YELLOW)Installing Microsoft 365 Agents Toolkit CLI...$(NC)"
	npm install -g @microsoft/m365agentstoolkit-cli --force
	@echo "$(GREEN)Microsoft 365 Agents Toolkit CLI installed successfully!$(NC)"

.PHONY: install-teamsfx
install-teamsfx: install-atk ## Legacy: Install Microsoft 365 Agents Toolkit CLI (replaces TeamsFx CLI)
	@echo "$(YELLOW)Note: TeamsFx CLI has been replaced by Microsoft 365 Agents Toolkit CLI$(NC)"

.PHONY: install-bicep
install-bicep: ## Install Azure Bicep CLI manually
	@echo "$(YELLOW)Installing Azure Bicep CLI...$(NC)"
	@if command -v az >/dev/null 2>&1; then \
		echo "$(YELLOW)Installing Bicep via Azure CLI...$(NC)"; \
		az bicep install; \
	else \
		echo "$(YELLOW)Installing Bicep directly...$(NC)"; \
		if [ "$$(uname)" = "Linux" ]; then \
			curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64; \
			chmod +x ./bicep; \
			sudo mv ./bicep /usr/local/bin/bicep; \
		elif [ "$$(uname)" = "Darwin" ]; then \
			curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-osx-x64; \
			chmod +x ./bicep; \
			sudo mv ./bicep /usr/local/bin/bicep; \
		else \
			echo "$(RED)Unsupported platform. Please install Bicep manually.$(NC)"; \
			exit 1; \
		fi; \
	fi
	@echo "$(GREEN)Bicep CLI installed successfully!$(NC)"

.PHONY: install-azure-cli
install-azure-cli: ## Install Azure CLI
	@echo "$(YELLOW)Installing Azure CLI...$(NC)"
	@if [ "$$(uname)" = "Linux" ]; then \
		if command -v apt-get >/dev/null 2>&1; then \
			curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash; \
		elif command -v yum >/dev/null 2>&1; then \
			sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc; \
			sudo dnf install -y https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm; \
			sudo dnf install azure-cli; \
		else \
			echo "$(RED)Please install Azure CLI manually for your Linux distribution$(NC)"; \
			exit 1; \
		fi; \
	elif [ "$$(uname)" = "Darwin" ]; then \
		if command -v brew >/dev/null 2>&1; then \
			brew update && brew install azure-cli; \
		else \
			echo "$(RED)Please install Homebrew first or install Azure CLI manually$(NC)"; \
			exit 1; \
		fi; \
	else \
		echo "$(RED)Unsupported platform for automatic Azure CLI installation$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Azure CLI installed successfully!$(NC)"

.PHONY: setup
setup: install-atk install ## Complete setup (install Microsoft 365 Agents Toolkit CLI and dependencies)
	@echo "$(GREEN)Setup completed successfully!$(NC)"

.PHONY: setup-full
setup-full: install-azure-cli install-bicep install-atk install ## Complete setup with Azure tools
	@echo "$(GREEN)Full setup completed successfully!$(NC)"

##@ Build & Development

.PHONY: build
build: ## Build the application
	@echo "$(YELLOW)Building application...$(NC)"
	npm run build
	@echo "$(GREEN)Build completed successfully!$(NC)"

.PHONY: dev
dev: ## Start development server
	@echo "$(YELLOW)Starting development server...$(NC)"
	npm run dev

.PHONY: dev-playground
dev-playground: ## Start development server with playground
	@echo "$(YELLOW)Starting development server with playground...$(NC)"
	npm run dev:teamsfx:testtool

.PHONY: start
start: build ## Start the application (production mode)
	@echo "$(YELLOW)Starting application...$(NC)"
	npm start

##@ Microsoft 365 Agents Lifecycle

.PHONY: resource-group-create
resource-group-create: ## Create Azure resource group if it doesn't exist (Environment: ENV=dev|local|playground)
	@echo "$(YELLOW)Creating Azure resource group for environment: $(ENV)...$(NC)"
	./scripts/az-rg-create.sh $(ENV)

.PHONY: provision
provision: resource-group-create ## Provision resources to Azure (Environment: ENV=dev|local|playground)
	@echo "$(YELLOW)Provisioning resources for environment: $(ENV)...$(NC)"
	./scripts/m365-provisioning.sh $(ENV)
	@echo "$(GREEN)Provisioning completed for environment: $(ENV)!$(NC)"

.PHONY: provision-force
provision-force: ## Force provision (retry with Bicep reinstall if needed)
	@echo "$(YELLOW)Force provisioning for environment: $(ENV)...$(NC)"
	./scripts/m365-provisioning.sh $(ENV) true
	@echo "$(GREEN)Force provisioning completed for environment: $(ENV)!$(NC)"

.PHONY: provision-clean
provision-clean: ## Clean provision (clear cache and retry)
	@echo "$(YELLOW)Cleaning and provisioning for environment: $(ENV)...$(NC)"
	./scripts/m365-provisioning.sh $(ENV) false true
	@echo "$(GREEN)Clean provisioning completed for environment: $(ENV)!$(NC)"

.PHONY: provision-debug
provision-debug: ## Debug provision with verbose output
	@echo "$(YELLOW)Debug provisioning for environment: $(ENV)...$(NC)"
	VERBOSE=true ./scripts/m365-provisioning.sh $(ENV)
	@echo "$(GREEN)Debug provisioning completed for environment: $(ENV)!$(NC)"

.PHONY: app-deploy
app-deploy: build ## Deploy application to Azure (Environment: ENV=dev|local|playground)
	@echo "$(YELLOW)Deploying application for environment: $(ENV)...$(NC)"
	@if [ ! -f "env/.env.$(ENV)" ]; then \
		echo "$(RED)Error: Environment file env/.env.$(ENV) not found!$(NC)"; \
		exit 1; \
	fi
	TEAMSFX_ENV=$(ENV) atk deploy --env $(ENV)
	@echo "$(GREEN)Deployment completed for environment: $(ENV)!$(NC)"

.PHONY: app-publish
app-publish: ## Publish app to Teams Admin Center for organization approval (Environment: ENV=dev|local|playground)
	@echo "$(YELLOW)Publishing application to Teams Admin Center for environment: $(ENV)...$(NC)"
	@if [ ! -f "env/.env.$(ENV)" ]; then \
		echo "$(RED)Error: Environment file env/.env.$(ENV) not found!$(NC)"; \
		exit 1; \
	fi
	TEAMSFX_ENV=$(ENV) atk publish --env $(ENV)
	@echo "$(GREEN)Application published to Teams Admin Center for environment: $(ENV)!$(NC)"
	@echo "$(YELLOW)The app is now available for review and approval in Teams Admin Center$(NC)"

##@ Complete Lifecycle

.PHONY: lifecycle-full
lifecycle-full: provision app-deploy app-publish ## Complete lifecycle: Provision → Deploy → Publish (Environment: ENV=dev|local|playground)
	@echo "$(GREEN)Full lifecycle completed for environment: $(ENV)!$(NC)"

.PHONY: lifecycle-dev
lifecycle-dev: ## Complete lifecycle for development environment
	$(MAKE) lifecycle-full ENV=dev

.PHONY: lifecycle-local
lifecycle-local: ## Complete lifecycle for local environment
	$(MAKE) lifecycle-full ENV=local

.PHONY: lifecycle-playground
lifecycle-playground: ## Complete lifecycle for playground environment
	$(MAKE) lifecycle-full ENV=playground

##@ Package Management

.PHONY: app-package
app-package: ## Create app package for current environment
	@echo "$(YELLOW)Creating app package for environment: $(ENV)...$(NC)"
	TEAMSFX_ENV=$(ENV) atk package --env $(ENV)
	@echo "$(GREEN)App package created: appPackage/build/appPackage.$(ENV).zip$(NC)"

.PHONY: app-validate
app-validate: ## Validate app manifest and package
	@echo "$(YELLOW)Validating app manifest and package...$(NC)"
	TEAMSFX_ENV=$(ENV) atk validate --env $(ENV)
	@echo "$(GREEN)Validation completed successfully!$(NC)"

##@ Environment Management

.PHONY: env-list
env-list: ## List available environments
	@echo "$(GREEN)Available environments:$(NC)"
	@ls -1 env/.env.* 2>/dev/null | sed 's/env\/.env\.//g' | sort || echo "No environment files found"

.PHONY: env-show
env-show: ## Show current environment variables (Environment: ENV=dev|local|playground)
	@echo "$(GREEN)Environment variables for: $(ENV)$(NC)"
	@if [ -f "env/.env.$(ENV)" ]; then \
		cat "env/.env.$(ENV)" | grep -v "^#" | grep -v "^$$"; \
	else \
		echo "$(RED)Environment file not found: env/.env.$(ENV)$(NC)"; \
	fi

.PHONY: env-create
env-create: ## Create new environment (Usage: make env-create ENV=newenv)
	@if [ -z "$(ENV)" ] || [ "$(ENV)" = "dev" ]; then \
		echo "$(RED)Error: Please specify environment name (make env-create ENV=yourenv)$(NC)"; \
		exit 1; \
	fi
	@if [ -f "env/.env.$(ENV)" ]; then \
		echo "$(RED)Error: Environment $(ENV) already exists!$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Creating new environment: $(ENV)...$(NC)"
	cp env/.env.dev env/.env.$(ENV)
	@echo "$(GREEN)Environment $(ENV) created successfully!$(NC)"
	@echo "$(YELLOW)Don't forget to update the values in env/.env.$(ENV)$(NC)"

##@ Maintenance & Cleanup

.PHONY: project-clean
project-clean: ## Clean build artifacts and temporary files
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	rm -rf lib/
	rm -rf appPackage/build/
	rm -rf node_modules/.cache/
	@echo "$(GREEN)Clean completed!$(NC)"

.PHONY: project-clean-all
project-clean-all: project-clean ## Clean everything including node_modules
	@echo "$(YELLOW)Cleaning everything including dependencies...$(NC)"
	rm -rf node_modules/
	@echo "$(GREEN)Complete clean finished!$(NC)"

.PHONY: project-reset
project-reset: project-clean-all install ## Reset project (clean everything and reinstall)
	@echo "$(GREEN)Project reset completed!$(NC)"

##@ Information & Debugging

.PHONY: info
info: ## Show project information
	@echo "$(GREEN)Project Information:$(NC)"
	@echo "  Name: $(PROJECT_NAME)"
	@echo "  Version: $$(node -p "require('./package.json').version")"
	@echo "  Description: $$(node -p "require('./package.json').description")"
	@echo "  Node Version Required: $$(node -p "require('./package.json').engines.node")"
	@echo "  Current Node Version: $$(node --version)"
	@echo ""
	@echo "$(GREEN)Available Scripts:$(NC)"
	@node -p "Object.keys(require('./package.json').scripts).map(s => '  ' + s).join('\\n')"

.PHONY: provision-debug-info
provision-debug-info: ## Debug provisioning issues
	@echo "$(GREEN)Debugging Provisioning Setup:$(NC)"
	@echo ""
	@echo "$(YELLOW)1. Checking Tools:$(NC)"
	@if command -v atk >/dev/null 2>&1; then \
		echo "$(GREEN)✓$(NC) Microsoft 365 Agents Toolkit CLI: $$(atk --version)"; \
	else \
		echo "$(RED)✗$(NC) TeamsFx CLI not installed"; \
	fi
	@if command -v bicep >/dev/null 2>&1; then \
		echo "$(GREEN)✓$(NC) Bicep CLI: $$(bicep --version)"; \
	else \
		echo "$(RED)✗$(NC) Bicep CLI not installed"; \
	fi
	@if command -v az >/dev/null 2>&1; then \
		echo "$(GREEN)✓$(NC) Azure CLI: $$(az --version | head -1)"; \
	else \
		echo "$(RED)✗$(NC) Azure CLI not installed"; \
	fi
	@echo ""
	@echo "$(YELLOW)2. Environment Status:$(NC)"
	@if [ -f "env/.env.$(ENV)" ]; then \
		echo "$(GREEN)✓$(NC) Environment file: env/.env.$(ENV)"; \
		echo "$(YELLOW)Key Variables:$(NC)"; \
		grep -E "AZURE_|TEAMS_APP_ID|BOT_" "env/.env.$(ENV)" | head -10; \
	else \
		echo "$(RED)✗$(NC) Environment file missing: env/.env.$(ENV)"; \
	fi
	@echo ""
	@echo "$(YELLOW)3. Cache Directories:$(NC)"
	@if [ -d "$$HOME/.fx" ]; then \
		echo "$(YELLOW)~$(NC) TeamsFx cache exists: ~/.fx"; \
	else \
		echo "$(GREEN)✓$(NC) No TeamsFx cache"; \
	fi
	@if [ -d "$$HOME/.teamsfx" ]; then \
		echo "$(YELLOW)~$(NC) TeamsFx cache exists: ~/.teamsfx"; \
	else \
		echo "$(GREEN)✓$(NC) No TeamsFx cache"; \
	fi

.PHONY: bicep-fix
bicep-fix: ## Fix Bicep installation issues
	@echo "$(YELLOW)Fixing Bicep installation issues...$(NC)"
	@echo "$(YELLOW)Removing old Bicep installations...$(NC)"
	@rm -rf ~/.fx/bin/bicep* 2>/dev/null || true
	@rm -rf ~/.teamsfx/bin/bicep* 2>/dev/null || true
	@sudo rm -f /usr/local/bin/bicep 2>/dev/null || true
	@echo "$(YELLOW)Installing latest Bicep...$(NC)"
	$(MAKE) install-bicep
	@echo "$(GREEN)Bicep fix completed!$(NC)"

.PHONY: docs
docs: ## Open documentation in default editor
	@echo "$(GREEN)Opening Makefile documentation...$(NC)"
	@if command -v code >/dev/null 2>&1; then \
		code docs/MAKEFILE_GUIDE.md; \
	elif command -v nano >/dev/null 2>&1; then \
		nano docs/MAKEFILE_GUIDE.md; \
	elif command -v vim >/dev/null 2>&1; then \
		vim docs/MAKEFILE_GUIDE.md; \
	else \
		cat docs/MAKEFILE_GUIDE.md; \
	fi

.PHONY: logs
logs: ## Show recent deployment logs
	@echo "$(GREEN)Recent deployment activity:$(NC)"
	@if [ -f ".teamsfx/logs/deployment.log" ]; then \
		tail -20 .teamsfx/logs/deployment.log; \
	else \
		echo "No deployment logs found"; \
	fi

##@ Scripts & Utilities

.PHONY: provision-script
provision-script: ## Run provisioning script directly (Usage: make provision-script ENV=dev [ARGS=...])
	@echo "$(YELLOW)Running provisioning script for $(ENV)...$(NC)"
	./scripts/m365-provisioning.sh $(ENV) $(ARGS)

.PHONY: provision-script-help
provision-script-help: ## Show help for provisioning script
	./scripts/m365-provisioning.sh --help

.PHONY: scripts-list project-repair project-repair-fix
scripts-list: ## List available scripts
	@echo "$(GREEN)Available Scripts:$(NC)"
	@find scripts/ -name "*.sh" -type f | sed 's|scripts/||' | sort

project-repair: ## Diagnose Microsoft 365 Agents Toolkit project configuration
	@echo "🔧 Diagnosing Microsoft 365 Agents Toolkit project..."
	@./scripts/m365-project-repair.sh

project-repair-fix: ## Attempt to fix Microsoft 365 Agents Toolkit project configuration
	@echo "🔧 Attempting to fix Microsoft 365 Agents Toolkit project..."
	@./scripts/m365-project-repair.sh --fix --backup

##@ Quick Commands

.PHONY: dev-quick
dev-quick: install build provision app-deploy ## Quick setup for development (install → build → provision → deploy)
	@echo "$(GREEN)Quick development setup completed!$(NC)"

.PHONY: prod-quick
prod-quick: install build lifecycle-dev ## Quick production deployment (install → build → full lifecycle)
	@echo "$(GREEN)Quick production deployment completed!$(NC)"

# Help for environment usage
.PHONY: help-env
help-env: ## Show help for environment usage
	@echo "$(GREEN)Environment Usage Examples:$(NC)"
	@echo ""
	@echo "  $(YELLOW)Development Environment:$(NC)"
	@echo "    make provision ENV=dev"
	@echo "    make app-deploy ENV=dev"
	@echo "    make app-publish ENV=dev"
	@echo "    make lifecycle-full ENV=dev"
	@echo ""
	@echo "  $(YELLOW)Local Environment:$(NC)"
	@echo "    make provision ENV=local"
	@echo "    make app-deploy ENV=local"
	@echo "    make app-publish ENV=local"
	@echo ""
	@echo "  $(YELLOW)Playground Environment:$(NC)"
	@echo "    make provision ENV=playground"
	@echo "    make app-deploy ENV=playground"
	@echo "    make app-publish ENV=playground"
	@echo ""
	@echo "  $(YELLOW)Quick Commands:$(NC)"
	@echo "    make lifecycle-dev      # Complete lifecycle for dev"
	@echo "    make lifecycle-local    # Complete lifecycle for local"
	@echo "    make lifecycle-playground # Complete lifecycle for playground"
	@echo ""
	@echo "  $(YELLOW)Documentation:$(NC)"
	@echo "    See docs/MAKEFILE_GUIDE.md for complete documentation"

# Validation target to ensure prerequisites
.PHONY: prereq-check
prereq-check: ## Check prerequisites
	@echo "$(YELLOW)Checking prerequisites...$(NC)"
	@command -v node >/dev/null 2>&1 || { echo "$(RED)Error: Node.js is not installed$(NC)"; exit 1; }
	@command -v npm >/dev/null 2>&1 || { echo "$(RED)Error: npm is not installed$(NC)"; exit 1; }
	@command -v atk >/dev/null 2>&1 || { echo "$(RED)Error: Microsoft 365 Agents Toolkit CLI is not installed. Run 'make install-atk'$(NC)"; exit 1; }
	@if command -v bicep >/dev/null 2>&1; then \
		echo "$(GREEN)✓$(NC) Bicep CLI is installed"; \
	else \
		echo "$(YELLOW)⚠$(NC)  Bicep CLI not installed. Run 'make install-bicep'"; \
	fi
	@if command -v az >/dev/null 2>&1; then \
		echo "$(GREEN)✓$(NC) Azure CLI is installed"; \
	else \
		echo "$(YELLOW)⚠$(NC)  Azure CLI not installed (optional). Run 'make install-azure-cli'"; \
	fi
	@echo "$(GREEN)✓ Core prerequisites are installed$(NC)"

.PHONY: provision-check-ready
provision-check-ready: ## Check if ready for provisioning
	@echo "$(YELLOW)Checking provisioning readiness for $(ENV)...$(NC)"
	$(MAKE) prereq-check
	@if [ ! -f "env/.env.$(ENV)" ]; then \
		echo "$(RED)✗ Environment file missing: env/.env.$(ENV)$(NC)"; \
		exit 1; \
	else \
		echo "$(GREEN)✓ Environment file exists$(NC)"; \
	fi
	@if grep -q "AZURE_SUBSCRIPTION_ID=" "env/.env.$(ENV)" && ! grep -q "AZURE_SUBSCRIPTION_ID=$$" "env/.env.$(ENV)"; then \
		echo "$(GREEN)✓ Azure Subscription configured$(NC)"; \
	else \
		echo "$(RED)✗ Azure Subscription not configured in env/.env.$(ENV)$(NC)"; \
		exit 1; \
	fi
	@if grep -q "AZURE_RESOURCE_GROUP_NAME=" "env/.env.$(ENV)" && ! grep -q "AZURE_RESOURCE_GROUP_NAME=$$" "env/.env.$(ENV)"; then \
		echo "$(GREEN)✓ Resource Group configured$(NC)"; \
	else \
		echo "$(RED)✗ Resource Group not configured in env/.env.$(ENV)$(NC)"; \
		exit 1; \
	fi
	@if grep -q "AZURE_LOCATION=" "env/.env.$(ENV)" && ! grep -q "AZURE_LOCATION=$$" "env/.env.$(ENV)"; then \
		echo "$(GREEN)✓ Azure Location configured$(NC)"; \
	else \
		echo "$(RED)✗ Azure Location not configured in env/.env.$(ENV)$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ Ready for provisioning!$(NC)"
