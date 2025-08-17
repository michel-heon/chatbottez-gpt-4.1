# Charger la configuration
$ConfigPath = "config/azure.env"
$Config = @{}

Get-Content $ConfigPath | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*?)\s*=\s*(.*?)\s*$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim('"', "'")
        $Config[$key] = $value
    }
}

# Variables dérivées
$ResourceGroupName = "rg-$($Config.PROJECT_NAME)-$($Config.ENVIRONMENT)-$($Config.REGION_SUFFIX)"
$Location = $Config.AZURE_LOCATION
$Environment = $Config.ENVIRONMENT

Write-Host "Déploiement Bicep avec:" -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor Yellow
Write-Host "  Location: $Location" -ForegroundColor Yellow
Write-Host "  Environment: $Environment" -ForegroundColor Yellow

# Validation du template
Write-Host "Validation du template Bicep..." -ForegroundColor Blue
try {
    az deployment group validate `
        --resource-group $ResourceGroupName `
        --template-file "infra/database/postgres.bicep" `
        --parameters "@infra/database/postgres.parameters.json" `
        --parameters location="$Location" environment="$Environment" `
        --output none
    
    Write-Host "✅ Validation réussie" -ForegroundColor Green
} catch {
    Write-Host "❌ Échec de validation: $_" -ForegroundColor Red
    exit 1
}

# Déploiement
Write-Host "Déploiement de l'infrastructure..." -ForegroundColor Blue
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$deploymentName = "postgres-deploy-$timestamp"

try {
    $deploymentResult = az deployment group create `
        --resource-group $ResourceGroupName `
        --template-file "infra/database/postgres.bicep" `
        --parameters "@infra/database/postgres.parameters.json" `
        --parameters location="$Location" environment="$Environment" `
        --name $deploymentName `
        --output json | ConvertFrom-Json
    
    if ($deploymentResult.properties.provisioningState -eq "Succeeded") {
        Write-Host "✅ Déploiement réussi!" -ForegroundColor Green
        
        # Sauvegarder les outputs
        $outputs = $deploymentResult.properties.outputs
        $outputFile = "deployment-outputs.json"
        $outputs | ConvertTo-Json -Depth 10 | Out-File $outputFile
        Write-Host "Outputs sauvegardés dans: $outputFile" -ForegroundColor Yellow
        
        # Afficher les résultats
        Write-Host "Détails du déploiement:" -ForegroundColor Cyan
        Write-Host "  Serveur: $($outputs.serverName.value)" -ForegroundColor Yellow
        Write-Host "  FQDN: $($outputs.serverFQDN.value)" -ForegroundColor Yellow
        Write-Host "  Base de données: $($outputs.databaseName.value)" -ForegroundColor Yellow
        Write-Host "  Key Vault: $($outputs.keyVaultName.value)" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Échec du déploiement: $($deploymentResult.properties.provisioningState)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Erreur de déploiement: $_" -ForegroundColor Red
    exit 1
}
