# ÉTAT DES CONFIGURATIONS - CHATBOTTEZ DEV-06
**Snapshot de configuration pour reprise de travail**

## FICHIERS DE CONFIGURATION ACTUELS

### web.config (Version Actuelle)
```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <webSocket enabled="false" />
    <handlers>
      <add name="iisnode" path="lib/src/index.js" verb="*" modules="iisnode"/>
    </handlers>
    <rewrite>
      <rules>
        <rule name="NodeInspector" patternSyntax="ECMAScript" stopProcessing="true">
          <match url="^lib/src/index.js\/debug[\/]?" />
        </rule>
        <rule name="DynamicContent">
          <conditions>
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="True"/>
          </conditions>
          <action type="Rewrite" url="lib/src/index.js"/>
        </rule>
      </rules>
    </rewrite>
    <security>
      <requestFiltering>
        <hiddenSegments>
          <remove segment="bin"/>
        </hiddenSegments>
      </requestFiltering>
    </security>
    <httpErrors existingResponse="PassThrough" />
    <iisnode watchedFiles="web.config;*.js"/>
    <defaultDocument enabled="true">
      <files>
        <add value="lib/src/index.js" />
      </files>
    </defaultDocument>
  </system.webServer>
</configuration>
```

### iisnode.yml (Configuration Optimisée)
```yaml
node_env: production
loggingEnabled: true
logDirectory: iisnode
debuggingEnabled: false
maxConcurrentRequestsPerProcess: 1024
maxNamedPipeConnectionRetry: 24
namedPipeConnectionRetryDelay: 250
maxNamedPipeConnectionPoolSize: 512
maxNamedPipePooledConnectionAge: 30000
asyncCompletionThreadCount: 0
initialRequestBufferSize: 4096
maxRequestBufferSize: 65536
watchedFiles: web.config;*.js
uncFileChangesPollingInterval: 5000
gracefulShutdownTimeout: 60000
enableXFF: false
flushResponse: false
devErrorsEnabled: false
debugHeaderEnabled: false
maxLogFileSizeInKB: 128
maxTotalLogFileSizeInKB: 1024
maxLogFiles: 20
recycleSignalEnabled: false
idlePageOutTimePeriod: 0
```

## VARIABLES D'ENVIRONNEMENT APP SERVICE

### Configuration Azure App Settings
```json
{
  "WEBSITE_NODE_DEFAULT_VERSION": "20.11.0",
  "NODE_ENV": "production",
  "SCM_DO_BUILD_DURING_DEPLOYMENT": "false",
  "WEBSITE_HTTPLOGGING_RETENTION_DAYS": "7",
  "APPINSIGHTS_INSTRUMENTATIONKEY": "[Auto-configuré]",
  "APPLICATIONINSIGHTS_CONNECTION_STRING": "[Auto-configuré]"
}
```

### Secrets Key Vault (Référencés)
```json
{
  "BOT_ID": "@Microsoft.KeyVault(VaultName=cotechnoe-ai-kv-01;SecretName=chatbottez-bot-id)",
  "BOT_PASSWORD": "@Microsoft.KeyVault(VaultName=cotechnoe-ai-kv-01;SecretName=chatbottez-bot-password)",
  "AZURE_OPENAI_API_KEY": "@Microsoft.KeyVault(VaultName=cotechnoe-ai-kv-01;SecretName=azure-openai-api-key)",
  "AZURE_OPENAI_ENDPOINT": "@Microsoft.KeyVault(VaultName=cotechnoe-ai-kv-01;SecretName=azure-openai-endpoint)"
}
```

## LOGS APPLICATIFS RÉCENTS

### Derniers Logs Node.js (Succès)
```
Agent started, app listening to { address: '::', family: 'IPv6', port: 3978 }
{"timestamp":"2025-08-19T01:02:32.267Z","level":"info","message":"Microsoft 365 Agent with Quota Management started","meta":{"port":"3978","quotaEnabled":"true","environment":"production"}}
```

### Warnings Non-Critiques
```
(node:3364) [DEP0005] DeprecationWarning: Buffer() is deprecated due to security and usability issues. Please use the Buffer.alloc(), Buffer.allocUnsafe(), or Buffer.from() methods instead.
```

## STRUCTURE DÉPLOIEMENT

### Package deploy.zip (Contenu)
```
deploy.zip
├── lib/                     ← JavaScript compilé
│   ├── src/
│   │   ├── index.js        ← Point d'entrée
│   │   ├── app/
│   │   ├── marketplace/
│   │   ├── middleware/
│   │   ├── services/
│   │   └── utils/
│   └── tests/
├── node_modules/           ← Dépendances
├── package.json
├── web.config
└── iisnode.yml
```

### Dernière Commande de Déploiement
```bash
zip -r deploy.zip lib/ node_modules/ package.json web.config iisnode.yml
az webapp deploy --resource-group rg-chatbottez-gpt-4-1-dev-06 --name chatbottez-gpt41-app-o7woxr --src-path deploy.zip --type zip
```

## DIAGNOSTICS SYSTÈME

### Test HTTP Actuel
```bash
curl -I https://chatbottez-gpt41-app-o7woxr.azurewebsites.net/health
# Résultat: HTTP/1.1 500 Internal Server Error
# Headers: Microsoft-IIS/10.0, X-Powered-By: ASP.NET
```

### Application Insights
- **Resource**: chatbottez-gpt41-insights-9dw6p9
- **Connection String**: Configurée automatiquement
- **Telemetry**: En cours de collecte

### Log Analytics
- **Workspace**: chatbottez-gpt41-logs-dvjk2l
- **Retention**: Configurée pour monitoring
- **Queries**: Disponibles pour debugging

## RESSOURCES AZURE

### App Service Principal
```
Nom: chatbottez-gpt41-app-o7woxr
URL: https://chatbottez-gpt41-app-o7woxr.azurewebsites.net
Runtime: Node.js 20.x
OS: Windows
Plan: chatbottez-gpt41-plan-cbhpqf (B1)
```

### Managed Identity
```
Nom: chatbottez-gpt41-mi-idmg6f
Type: User-assigned
Accès: Key Vault cotechnoe-ai-kv-01
```

### Base de Données (Mutualisée)
```
Server: cotechnoe-ai-sql-server-01.database.windows.net
Database: cotechnoe-ai-sql-db-01
Connection: Configurée via Key Vault
```

### Azure OpenAI (Mutualisé)
```
Service: cotechnoe-ai-oai-01
Endpoint: Configuré via Key Vault
Models: GPT-4, GPT-3.5-turbo (selon quota)
```

## PROCHAINES ACTIONS TECHNIQUES

### 1. Debugging HTTP 500
```bash
# Récupérer logs détaillés
az webapp log download --resource-group rg-chatbottez-gpt-4-1-dev-06 --name chatbottez-gpt41-app-o7woxr --log-file http500-debug.zip

# Analyser logs iisnode spécifiques
unzip http500-debug.zip
cat LogFiles/Application/*/stdout*.txt
cat LogFiles/Application/*/stderr*.txt
```

### 2. Test Configuration Alternative
```xml
<!-- web.config minimal pour test -->
<configuration>
  <system.webServer>
    <handlers>
      <add name="iisnode" path="lib/src/index.js" verb="*" modules="iisnode"/>
    </handlers>
    <rewrite>
      <rules>
        <rule name="app">
          <match url=".*" />
          <action type="Rewrite" url="lib/src/index.js"/>
        </rule>
      </rules>
    </rewrite>
  </system.webServer>
</configuration>
```

### 3. Vérification Port Mapping
```bash
# Accès console App Service pour vérifier
# Via Azure Portal → App Service → Development Tools → Console
node lib/src/index.js  # Test direct
netstat -an | grep 3978  # Vérifier port binding
```

## HISTORIQUE VERSIONS

### Tag de Référence: v1.0.0-marketplace-quota
Configuration extraite et appliquée avec succès pour:
- ✅ Structure application
- ✅ Point d'entrée lib/src/index.js
- ✅ Configuration iisnode de base
- ❌ Routage HTTP (encore problématique)

### Évolution Configuration
1. **Test-server.js** → Échec (Handler incorrect)
2. **src/index.js** → Échec (Chemin incorrect)
3. **lib/src/index.js** → Application démarre ✅ + HTTP 500 ❌

## CONTACT TECHNIQUE

### Ressources Déployées Par
- **Infrastructure**: Bicep templates (infra/)
- **Configuration**: web.config + iisnode.yml
- **Code**: TypeScript compilé vers lib/

### Support URLs
- App Service: https://chatbottez-gpt41-app-o7woxr.azurewebsites.net
- SCM Site: https://chatbottez-gpt41-app-o7woxr.scm.azurewebsites.net
- Application Insights: Via Azure Portal

**STATUT FINAL**: Application Node.js 100% fonctionnelle, HTTP routing 0% fonctionnel. 
**EFFORT RESTANT**: Résolution configuration IIS/iisnode pour routage HTTP.
