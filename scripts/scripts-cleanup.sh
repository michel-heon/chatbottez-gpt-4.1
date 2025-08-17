#!/bin/bash
# =================================================================
# Script de Nettoyage - Suppression des Fichiers Obsolètes
# =================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}$1${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo ""
print_header "================================================================="
print_header "🧹 Nettoyage des Scripts Obsolètes"
print_header "================================================================="
echo ""

# Fichiers à conserver (scripts Bash fonctionnels)
KEEP_FILES=(
    "config-loader.sh"
    "azure-deploy.sh"
    "azure-configure.sh"
    "config-test.sh"
    "deployment-validate.sh"
    "marketplace-setup.sh"
    "database-setup.sh"
    "environment-setup.sh"
    "scripts-cleanup.sh"
)

# Fichiers PowerShell obsolètes à supprimer
OBSOLETE_POWERSHELL=(
    "AzureConfigLoader.psm1"
    "Cleanup-And-Redeploy.ps1"
    "Configure-Environment.ps1"
    "Deploy-AzureDatabase.ps1"
    "Deploy-AzureDatabase-v2.ps1"
    "Quick-Deploy-Azure.ps1"
    "Quick-Deploy-Centralized.ps1"
)

# Scripts PowerShell encore référencés dans la documentation (à conserver temporairement)
KEEP_POWERSHELL_TEMPORARILY=(
    "Setup-Environment.ps1"
    "Setup-Database.ps1"
)

# Scripts Bash obsolètes/doublons à supprimer
OBSOLETE_BASH=(
    "configure-environment.sh"
    "deploy-azure-database.sh"
    "setup-environment.sh"
)

# Fichiers divers obsolètes
OBSOLETE_MISC=(
    "env-template-complete.env"
    "test-database.ts"
)

print_info "Analyse des fichiers dans le répertoire scripts/..."
echo ""

# Afficher les fichiers à conserver
print_header "✅ Fichiers à CONSERVER (scripts Bash fonctionnels):"
for file in "${KEEP_FILES[@]}"; do
    if [ -f "scripts/$file" ]; then
        echo "   📄 $file"
    else
        print_warning "Fichier manquant: $file"
    fi
done

echo ""

# Afficher les fichiers à supprimer
print_header "🗑️  Fichiers à SUPPRIMER:"

echo ""
print_info "Scripts PowerShell obsolètes:"
for file in "${OBSOLETE_POWERSHELL[@]}"; do
    if [ -f "scripts/$file" ]; then
        echo "   ❌ $file (PowerShell obsolète)"
    fi
done

echo ""
print_info "Scripts Bash obsolètes/doublons:"
for file in "${OBSOLETE_BASH[@]}"; do
    if [ -f "scripts/$file" ]; then
        echo "   ❌ $file (Bash obsolète)"
    fi
done

echo ""
print_info "Scripts PowerShell encore référencés (conservés temporairement):"
for file in "${KEEP_POWERSHELL_TEMPORARILY[@]}"; do
    if [ -f "scripts/$file" ]; then
        echo "   ⚠️  $file (référencé dans la documentation)"
    fi
done

echo ""
print_info "Fichiers divers obsolètes:"
for file in "${OBSOLETE_MISC[@]}"; do
    if [ -f "scripts/$file" ]; then
        echo "   ❌ $file (obsolète)"
    fi
done

echo ""
read -p "Voulez-vous procéder à la suppression de ces fichiers? (o/N): " -r
if [[ ! $REPLY =~ ^[Oo]$ ]]; then
    print_info "Nettoyage annulé"
    exit 0
fi

echo ""
print_header "🧹 Suppression en cours..."

# Fonction pour supprimer un fichier avec confirmation
delete_file() {
    local file="$1"
    local reason="$2"
    
    if [ -f "scripts/$file" ]; then
        rm "scripts/$file"
        print_success "Supprimé: $file ($reason)"
    fi
}

# Supprimer les fichiers PowerShell obsolètes
print_info "Suppression des scripts PowerShell obsolètes..."
for file in "${OBSOLETE_POWERSHELL[@]}"; do
    delete_file "$file" "PowerShell obsolète"
done

# Supprimer les scripts Bash obsolètes
print_info "Suppression des scripts Bash obsolètes..."
for file in "${OBSOLETE_BASH[@]}"; do
    delete_file "$file" "Bash obsolète/doublon"
done

# Supprimer les fichiers divers
print_info "Suppression des fichiers divers obsolètes..."
for file in "${OBSOLETE_MISC[@]}"; do
    delete_file "$file" "fichier obsolète"
done

echo ""
print_header "📋 État final du répertoire scripts/:"
echo ""

# Afficher l'état final
if [ -d "scripts" ]; then
    for file in scripts/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if [[ " ${KEEP_FILES[*]} " =~ " ${filename} " ]]; then
                echo -e "   ${GREEN}✅ ${filename}${NC} (conservé)"
            else
                echo -e "   ${YELLOW}❓ ${filename}${NC} (non répertorié)"
            fi
        fi
    done
fi

echo ""
print_header "🎯 Résumé du Nettoyage:"
echo ""

# Compter les fichiers supprimés
total_deleted=0
for file in "${OBSOLETE_POWERSHELL[@]}" "${OBSOLETE_BASH[@]}" "${OBSOLETE_MISC[@]}"; do
    if [ ! -f "scripts/$file" ]; then
        total_deleted=$((total_deleted + 1))
    fi
done

# Compter les fichiers conservés
total_kept=0
for file in "${KEEP_FILES[@]}"; do
    if [ -f "scripts/$file" ]; then
        total_kept=$((total_kept + 1))
    fi
done

print_success "$total_deleted fichiers obsolètes supprimés"
print_success "$total_kept scripts Bash fonctionnels conservés"

# Compter les scripts PowerShell conservés
total_ps1_kept=0
for file in "${KEEP_POWERSHELL_TEMPORARILY[@]}"; do
    if [ -f "scripts/$file" ]; then
        total_ps1_kept=$((total_ps1_kept + 1))
    fi
done

if [ $total_ps1_kept -gt 0 ]; then
    echo -e "${YELLOW}   $total_ps1_kept scripts PowerShell conservés (référencés dans la documentation)${NC}"
    echo -e "${YELLOW}   ⚠️  À remplacer par des équivalents Bash et mettre à jour la documentation${NC}"
fi

echo ""
print_header "✨ Nettoyage terminé!"
print_info "Le répertoire scripts/ ne contient plus que les scripts Bash fonctionnels"
print_info "Prêt pour le commit GitHub"

echo ""
print_header "================================================================="
