#!/bin/bash

# 🧹 Script de nettoyage - ChatBottez GPT-4.1
# Supprime les fichiers désuets avant push Git

echo "🧹 Nettoyage des fichiers désuets..."

# 1. Scripts PowerShell désuets (remplacés par scripts WSL)
echo "🗑️  Suppression des scripts PowerShell désuets..."
rm -f deploy-simple.ps1
rm -f deploy-app-dev05.ps1
rm -f temp_deploy.ps1

# 2. Infrastructure dev01-dev04 (désuètes, dev05 est actuel)
echo "🗑️  Suppression des infrastructures dev01-dev04..."
rm -f infra/complete-infrastructure-dev01.*
rm -f infra/complete-infrastructure-dev02.*
rm -f infra/complete-infrastructure-dev03.*
rm -f infra/complete-infrastructure-dev04.*

# 3. Fichiers temporaires
echo "🗑️  Suppression des fichiers temporaires..."
rm -f deploy.zip
rm -f deployment-outputs.json
rm -f app-settings.json

# 4. Logs temporaires
echo "🗑️  Suppression des logs temporaires..."
rm -f devTools/m365agentsplayground.log

# 5. Fichiers de build (seront reconstruits)
echo "🗑️  Nettoyage du dossier lib/..."
rm -rf lib/

# 6. node_modules (sera réinstallé avec npm install)
echo "🗑️  Suppression de node_modules/..."
rm -rf node_modules/

# 7. Fichiers de configuration locaux sensibles
echo "🗑️  Suppression des configs locales sensibles..."
rm -f .localConfigs
rm -f .localConfigs.playground

echo "✅ Nettoyage terminé!"
echo ""
echo "📋 Fichiers conservés:"
echo "  ✅ infra/complete-infrastructure-dev05.* (infrastructure actuelle)"
echo "  ✅ scripts/deploy-app-dev05-wsl.sh (script de déploiement actuel)"
echo "  ✅ docs/ (documentation mise à jour)"
echo "  ✅ src/ (code source application)"
echo "  ✅ env/ (variables d'environnement)"
echo "  ✅ appPackage/ (Teams app package)"
echo ""
echo "🔄 Pour reconstruire:"
echo "  npm install"
echo "  npm run build"
