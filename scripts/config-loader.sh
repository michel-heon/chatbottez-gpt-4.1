#!/bin/bash
# =================================================================
# Azure Configuration Loader - Bash Module
# Équivalent Bash du module PowerShell AzureConfigLoader.psm1
# =================================================================

# Variables globales pour la configuration
AZURE_CONFIG_LOADED=false

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Fonction utilitaire pour les messages
config_log_info() {
    echo -e "${CYAN}[CONFIG]${NC} $1"
}

config_log_success() {
    echo -e "${GREEN}[CONFIG]${NC} $1"
}

config_log_warning() {
    echo -e "${YELLOW}[CONFIG]${NC} $1"
}

config_log_error() {
    echo -e "${RED}[CONFIG]${NC} $1"
}

# Fonction pour charger la configuration Azure
load_azure_config() {
    local config_file="${1:-config/azure.env}"
    
    config_log_info "Chargement de la configuration depuis: $config_file"
    
    # Vérifier l'existence du fichier
    if [ ! -f "$config_file" ]; then
        config_log_error "Fichier de configuration non trouvé: $config_file"
        echo "Créez le fichier avec:"
        echo "mkdir -p config"
        echo "cat > config/azure.env << 'EOF'"
        echo "PROJECT_NAME=chatbottez-gpt-4-1"
        echo "ENVIRONMENT=dev"
        echo "REGION_SUFFIX=02"
        echo "AZURE_LOCATION=Canada Central"
        echo "POSTGRES_DATABASE_NAME=gpt41db"
        echo "POSTGRES_ADMIN_USERNAME=postgresadmin"
        echo "EOF"
        return 1
    fi
    
    # Charger les variables
    set -a
    source "$config_file"
    set +a
    
    # Traitement des variables avec substitution
    export RESOURCE_GROUP_NAME="rg-${PROJECT_NAME}-${ENVIRONMENT}-${REGION_SUFFIX}"
    
    # Variables dérivées pour l'infrastructure
    export SERVER_NAME="${PROJECT_NAME//-/}-${ENVIRONMENT}-postgres-${REGION_SUFFIX}"
    export KEY_VAULT_NAME="${PROJECT_NAME//-/}${ENVIRONMENT}kv${REGION_SUFFIX}"
    
    # Marquer comme chargé
    AZURE_CONFIG_LOADED=true
    
    config_log_success "Configuration chargée avec succès"
    return 0
}

# Fonction pour valider la configuration
validate_azure_config() {
    if [ "$AZURE_CONFIG_LOADED" = false ]; then
        config_log_error "Configuration non chargée. Appelez load_azure_config d'abord."
        return 1
    fi
    
    config_log_info "Validation de la configuration..."
    
    local required_vars=(
        "PROJECT_NAME"
        "ENVIRONMENT"
        "REGION_SUFFIX"
        "AZURE_LOCATION"
        "POSTGRES_DATABASE_NAME"
        "POSTGRES_ADMIN_USERNAME"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        config_log_error "Variables manquantes dans la configuration:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        return 1
    fi
    
    # Validation des valeurs
    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
        config_log_error "ENVIRONMENT doit être 'dev', 'staging' ou 'prod'"
        return 1
    fi
    
    if [[ ! "$REGION_SUFFIX" =~ ^[0-9]{2}$ ]]; then
        config_log_error "REGION_SUFFIX doit être un nombre à 2 chiffres (ex: 01, 02)"
        return 1
    fi
    
    # Validation des noms générés
    if [ ${#RESOURCE_GROUP_NAME} -gt 64 ]; then
        config_log_error "Nom du groupe de ressources trop long: ${#RESOURCE_GROUP_NAME} caractères (max 64)"
        return 1
    fi
    
    if [ ${#KEY_VAULT_NAME} -gt 24 ]; then
        config_log_error "Nom du Key Vault trop long: ${#KEY_VAULT_NAME} caractères (max 24)"
        return 1
    fi
    
    config_log_success "Configuration validée avec succès"
    return 0
}

# Fonction pour afficher le résumé de configuration
show_azure_config() {
    if [ "$AZURE_CONFIG_LOADED" = false ]; then
        config_log_error "Configuration non chargée"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  Configuration Azure                        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Variables de base:${NC}"
    echo "  Projet                 : $PROJECT_NAME"
    echo "  Environnement          : $ENVIRONMENT"
    echo "  Suffixe région         : $REGION_SUFFIX"
    echo "  Localisation Azure     : $AZURE_LOCATION"
    echo ""
    echo -e "${YELLOW}PostgreSQL:${NC}"
    echo "  Nom de la base         : $POSTGRES_DATABASE_NAME"
    echo "  Utilisateur admin      : $POSTGRES_ADMIN_USERNAME"
    echo ""
    echo -e "${YELLOW}Ressources Azure générées:${NC}"
    echo "  Groupe de ressources   : $RESOURCE_GROUP_NAME"
    echo "  Nom du serveur         : $SERVER_NAME"
    echo "  Nom du Key Vault       : $KEY_VAULT_NAME"
    echo ""
}

# Fonction pour exporter la configuration en JSON
export_azure_config_json() {
    if [ "$AZURE_CONFIG_LOADED" = false ]; then
        config_log_error "Configuration non chargée"
        return 1
    fi
    
    cat << EOF
{
    "project": {
        "name": "$PROJECT_NAME",
        "environment": "$ENVIRONMENT",
        "regionSuffix": "$REGION_SUFFIX"
    },
    "azure": {
        "location": "$AZURE_LOCATION",
        "resourceGroupName": "$RESOURCE_GROUP_NAME"
    },
    "postgres": {
        "databaseName": "$POSTGRES_DATABASE_NAME",
        "adminUsername": "$POSTGRES_ADMIN_USERNAME",
        "serverName": "$SERVER_NAME"
    },
    "keyVault": {
        "name": "$KEY_VAULT_NAME"
    }
}
EOF
}

# Fonction pour sauvegarder la configuration dans un fichier JSON
save_azure_config_json() {
    local output_file="${1:-config/azure-config.json}"
    
    if [ "$AZURE_CONFIG_LOADED" = false ]; then
        config_log_error "Configuration non chargée"
        return 1
    fi
    
    # Créer le répertoire si nécessaire
    mkdir -p "$(dirname "$output_file")"
    
    export_azure_config_json > "$output_file"
    config_log_success "Configuration sauvegardée dans: $output_file"
}

# Fonction pour tester la configuration
test_azure_config() {
    config_log_info "Test de la configuration Azure..."
    
    # Charger la configuration
    if ! load_azure_config; then
        return 1
    fi
    
    # Valider la configuration
    if ! validate_azure_config; then
        return 1
    fi
    
    # Afficher le résumé
    show_azure_config
    
    # Test de connexion Azure CLI
    if command -v az &> /dev/null; then
        config_log_info "Test de la connexion Azure CLI..."
        if az account show &> /dev/null; then
            local account_name=$(az account show --query name -o tsv)
            config_log_success "Connecté à Azure: $account_name"
        else
            config_log_warning "Non connecté à Azure. Exécutez: az login"
        fi
    else
        config_log_warning "Azure CLI non installé"
    fi
    
    config_log_success "Test de configuration terminé"
    return 0
}

# Fonction d'aide
show_config_help() {
    echo ""
    echo -e "${CYAN}Azure Configuration Loader - Module Bash${NC}"
    echo ""
    echo -e "${YELLOW}Fonctions disponibles:${NC}"
    echo "  load_azure_config [fichier]    - Charger la configuration"
    echo "  validate_azure_config          - Valider la configuration"
    echo "  show_azure_config              - Afficher le résumé"
    echo "  export_azure_config_json       - Exporter en JSON"
    echo "  save_azure_config_json [file]  - Sauvegarder en JSON"
    echo "  test_azure_config              - Tester la configuration"
    echo ""
    echo -e "${YELLOW}Utilisation:${NC}"
    echo "  source scripts/config-loader.sh"
    echo "  load_azure_config"
    echo "  show_azure_config"
    echo ""
}

# Si le script est exécuté directement (pas sourcé)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-help}" in
        test)
            test_azure_config
            ;;
        show)
            if load_azure_config; then
                show_azure_config
            fi
            ;;
        json)
            if load_azure_config; then
                export_azure_config_json
            fi
            ;;
        help|--help|-h)
            show_config_help
            ;;
        *)
            echo "Usage: $0 {test|show|json|help}"
            echo "Ou sourcez le script: source $0"
            exit 1
            ;;
    esac
fi
