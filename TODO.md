# TODO - ChatBottez GPT-4.1 v1.7.0

## 🎯 **État Actuel - 18 Août 2025**

### ✅ **COMPLÉTÉ - Infrastructure & Application**
- [x] **Infrastructure Azure complète** : Environment DEV-05 déployé
- [x] **Application déployée** : Code compilé et uploadé sur Azure App Service
- [x] **Key Vault configuré** : OpenAI API key stockée de manière sécurisée
- [x] **Database opérationnelle** : PostgreSQL Flexible Server ready
- [x] **Monitoring actif** : Application Insights configuré
- [x] **Scripts de déploiement** : Script WSL `deploy-app-dev05-wsl.sh` fonctionnel
- [x] **Documentation mise à jour** : Statut v1.7.0, logs de déploiement
- [x] **Projet nettoyé** : Fichiers désuets supprimés, structure optimisée

### ⚠️ **EN COURS - Configuration Finale**
- [ ] **Fix Environment Variables** : Azure CLI config échoue, configuration manuelle requise
- [ ] **Application Startup** : Résoudre HTTP 500 error
- [ ] **Variables Mapping** : Synchroniser noms de secrets Key Vault avec Bicep

### 🚀 **PROCHAINES ÉTAPES IMMÉDIATES**

#### **Phase 1 - Application Functional (Priorité 1)**
1. **[ ] Fix Environment Variables Configuration**
   - Access Azure Portal → App Service `chatbottez-gpt41-app-rnukfj`
   - Manually configure environment variables (Azure CLI bug)
   - Test environment variables are properly loaded

2. **[ ] Resolve Application Startup Issues**
   - Diagnose HTTP 500 error causes
   - Verify Node.js runtime compatibility
   - Check application logs for specific error messages

3. **[ ] Validate Application Functionality**
   - Test health endpoints
   - Verify OpenAI API integration
   - Test basic chat functionality

#### **Phase 2 - Teams Integration (Priorité 2)**
4. **[ ] Teams Bot Registration**
   - Register bot in Azure Bot Service
   - Configure Teams app manifest
   - Deploy Teams app package

5. **[ ] End-to-End Testing**
   - Test chat functionality in Teams
   - Verify quota enforcement
   - Test Marketplace webhook integration

#### **Phase 3 - Production Readiness (Priorité 3)**
6. **[ ] Marketplace Configuration**
   - Setup Partner Center account
   - Configure SaaS offer
   - Implement billing webhooks

7. **[ ] Performance & Security**
   - Load testing
   - Security review
   - Documentation completion

---

## 🛠️ **Actions Techniques Détaillées**

### 🔧 **Environment Variables Fix**

**Problème** : Les commandes `az webapp config appsettings set` retournent success mais toutes les valeurs restent `null`.

**Variables Requises** :
```env
NODE_ENV=production
AZURE_OPENAI_ENDPOINT=https://openai-cotechnoe.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4.1
AZURE_OPENAI_KEY=@Microsoft.KeyVault(VaultName=kv-gpt41-rnukfj;SecretName=azure-openai-key)
DATABASE_URL=@Microsoft.KeyVault(VaultName=kv-gpt41-rnukfj;SecretName=database-url)
APPLICATIONINSIGHTS_CONNECTION_STRING=[from bicep output]
```

**Solutions à Tester** :
- [ ] Configuration manuelle via Azure Portal
- [ ] Utilisation de Azure CLI PowerShell natif
- [ ] Redéploiement infrastructure avec variables intégrées
- [ ] Vérification des permissions Azure

### 🚨 **Issues Connues**

#### **Azure CLI Environment Variables Bug**
- **Symptôme** : `az webapp config appsettings set` réussit mais variables = null
- **Impact** : Application ne peut pas démarrer (HTTP 500)
- **Workaround** : Configuration manuelle via Azure Portal

#### **Key Vault Secret Mapping**
- **Bicep attend** : `azure-openai-key`
- **Nous avions** : `openai-api-key`
- **Status** : ✅ Corrigé - les deux secrets existent maintenant

#### **Windows vs Linux App Service**
- **Current** : Windows App Service Plan (reserved: false)
- **Deployed** : web.config pour IIS
- **Status** : ✅ Compatible - reste à tester

---

## 📊 **Métriques de Progression**

### **Infrastructure (100% ✅)**
- Resource Group : ✅
- PostgreSQL Database : ✅  
- Key Vault : ✅
- App Service Plan : ✅
- Web App : ✅
- Application Insights : ✅

### **Application (85% ⚠️)**
- Code Compilation : ✅
- Deployment Package : ✅
- Azure Upload : ✅
- Environment Config : ❌ (blocking)
- Application Runtime : ❌ (pending config)

### **Teams Integration (0% ⏳)**
- Bot Registration : ⏳
- Teams Manifest : ⏳
- App Package : ⏳
- Teams Testing : ⏳

### **Marketplace (0% ⏳)**
- Partner Center : ⏳
- SaaS Offer : ⏳
- Billing Webhooks : ⏳
- End-to-End Testing : ⏳

---

## 🎯 **Milestone Targets**

### **v1.7.1 - Configuration Fix (Target: 19 août 2025)**
- [ ] Environment variables configured
- [ ] Application responding (HTTP 200)
- [ ] Basic functionality verified

### **v1.8.0 - Teams Integration (Target: 22 août 2025)**
- [ ] Teams Bot registered and functional
- [ ] Chat working in Teams client
- [ ] Teams app package published

### **v1.9.0 - Marketplace Ready (Target: 30 août 2025)**
- [ ] Partner Center configured
- [ ] SaaS offer published
- [ ] Billing integration tested
- [ ] Production deployment ready

---

**Last Updated** : 18 août 2025  
**Current Version** : v1.7.0-step6-application-deployment  
**Next Milestone** : v1.7.1-step6-config-fix  
**Deployment URL** : https://chatbottez-gpt41-app-rnukfj.azurewebsites.net

## � Déploiement Rapide avec Makefile

### ✅ Configuration et déploiement automatisés
- [x] **Makefile créé** : Interface unifiée pour tous les workflows
- [x] **Scripts standardisés** : Nomenclature `<objet>-<action>.sh` alignée sur l'architecture
- [x] **Documentation complète** : Guide Makefile et composants Azure

#### Commandes principales disponibles :
```bash
make help          # Afficher l'aide complète
make all           # Déploiement complet (setup + deploy + configure + validate)
make dev-setup     # Configuration rapide pour développement
make status        # Statut du système
make validate      # Tests de validation (15 validations)
```

## �🔧 Setup et Configuration Immédiate

### ✅ 1. Installation des dépendances
- [x] Exécuter `npm install` pour installer les nouvelles dépendances
- [x] Vérifier que toutes les dépendances TypeScript sont installées
- [x] Corriger les erreurs de compilation TypeScript

### ✅ 2. Configuration des variables d'environnement
- [x] Copier `.env.example` vers `.env.local`
- [x] Configurer le script d'environnement automatisé (`scripts/environment-setup.sh`)
- [x] Générer automatiquement `TENANT_ID` et `JWT_SECRET_KEY`
- [ ] Remplir les valeurs réelles pour :
  - [ ] `MARKETPLACE_API_KEY` (clé d'API Microsoft Marketplace)
  - [ ] `DATABASE_URL` (chaîne de connexion à la base de données)
  - [ ] `AZURE_STORAGE_CONNECTION_STRING` (pour retry des événements d'usage)
  - [ ] `APPLICATION_INSIGHTS_CONNECTION_STRING` (monitoring)
  - [ ] `BOT_ID` et `BOT_PASSWORD` (Azure Bot Service)
  - [ ] `AZURE_OPENAI_API_KEY` et `AZURE_OPENAI_ENDPOINT` (Azure OpenAI)

### ✅ 3. Base de données
- [x] Créer les scripts d'installation automatisés (Bash/WSL et PowerShell legacy)
- [x] Script de test de connexion et vérification (`scripts/test-database.ts`)
- [x] Guide d'installation PostgreSQL pour Windows (`docs/INSTALL_POSTGRESQL.md`)
- [x] Scripts NPM pour la gestion de base de données (`npm run db:setup`, `npm run test:db`)
- [x] **DÉPLOYÉ** : PostgreSQL Flexible Server dans Azure (Canada Central)
- [x] **DÉPLOYÉ** : Azure Key Vault pour la gestion des secrets
- [x] Tester la connexion avec `npm run test:db` ou `make test-db`

## 🏗️ Infrastructure Azure

### ✅ 4. Déploiement APIM (API Management)
- [x] **DÉPLOYÉ** : Service Azure API Management dans rg-chatbottez-gpt-4-1-dev-02
- [x] **DÉPLOYÉ** : Policies de quota et rate limiting configurées
- [x] **DÉPLOYÉ** : Intégration avec Key Vault pour les secrets
- [x] **VALIDÉ** : 15 tests de validation passés avec succès
- [x] Scripts de déploiement automatisés : `make deploy`
- [x] Scripts de configuration post-déploiement : `make configure`

### 5. Configuration Microsoft Marketplace
- [ ] Créer l'offre SaaS dans Partner Center
- [ ] Configurer le plan "300 questions/mois"
- [ ] Configurer les webhooks de fulfillment
- [ ] Configurer les dimensions de metered billing
- [ ] Obtenir les clés d'API Marketplace réelles
- [x] Script de configuration Marketplace : `scripts/marketplace-setup.sh`

## 🔨 Corrections de Code

### 6. Fixes TypeScript immédiats
- [ ] Corriger l'erreur dans `SubscriptionService.updateSubscription()` (type status)
- [ ] Ajouter les types Jest manquants
- [ ] Installer `@types/jest` et configurer Jest
- [ ] Corriger les imports manquants

### 7. Implémentation base de données réelle
- [x] **DÉPLOYÉ** : PostgreSQL Flexible Server dans Azure
- [x] **CONFIGURÉ** : Connection strings et variables d'environnement
- [ ] Remplacer `SubscriptionService` in-memory par PostgreSQL
- [ ] Implémenter les repositories PostgreSQL
- [ ] Ajouter les migrations de base de données
- [ ] Configurer le connection pooling

## ✅ Tests et Validation

### ✅ 8. Infrastructure validée
- [x] **15 tests de validation** passés avec succès via `make validate`
- [x] **Configuration testée** via `make test-config`
- [x] **Base de données testée** via `make test-db`
- [x] **Déploiement vérifié** via scripts automatisés

### 9. Tests unitaires applicatifs
- [ ] Corriger la configuration Jest (`jest.config.js`)
- [ ] Faire passer tous les tests unitaires
- [ ] Ajouter des tests pour les nouveaux services
- [ ] Tests de couverture > 80%

### 10. Tests d'intégration
- [ ] Créer des tests d'intégration pour les webhooks Marketplace
- [ ] Tests de quota enforcement avec APIM
- [ ] Tests de publication d'événements d'usage
- [ ] Tests de retry logic

### 11. Tests de charge quota
- [ ] Créer un test qui envoie 300+ requêtes
- [ ] Vérifier que la 301ème requête est bloquée (HTTP 429)
- [ ] Tester le reset mensuel du quota
- [ ] Tester le mode overage

## 🚀 Déploiement et Monitoring

### 11. Déploiement en production
- [ ] Configurer l'environnement de production
- [ ] Déployer l'application sur Azure App Service
- [ ] Configurer HTTPS et les certificats
- [ ] Configurer les variables d'environnement de prod

### 12. Monitoring et observabilité
- [ ] Configurer Application Insights
- [ ] Créer des dashboards pour :
  - [ ] Usage par subscription
  - [ ] Quota remaining par tenant
  - [ ] Erreurs et retry
  - [ ] Performance des APIs
- [ ] Configurer les alertes :
  - [ ] Quota à 80%/90%/100%
  - [ ] Échecs de publication d'usage
  - [ ] Erreurs système

### 13. Logs et audit
- [ ] Vérifier que tous les événements sont loggés
- [ ] Configurer la rétention des logs
- [ ] Tester les logs d'audit de sécurité
- [ ] Configurer l'export vers SIEM (si nécessaire)

## 🔐 Sécurité et Conformité

### 14. Sécurité
- [ ] Valider la signature des webhooks Microsoft
- [ ] Configurer CORS correctement
- [ ] Audit de sécurité des endpoints
- [ ] Tests de pénétration basiques
- [ ] Chiffrement des données sensibles

### 15. Conformité GDPR
- [ ] Documenter les données personnelles collectées
- [ ] Implémenter la suppression des données
- [ ] Configurer les consentements utilisateur
- [ ] Documentation privacy policy

## 📋 Documentation et Formation

### 16. Documentation technique
- [x] Finaliser `docs/README_QUOTA.md` ✅ **COMPLÉTÉ**
- [ ] Documenter les APIs Marketplace
- [ ] Créer un guide de troubleshooting
- [ ] Documenter les procédures d'urgence

### 17. Documentation utilisateur
- [ ] Guide d'installation pour les admins
- [ ] FAQ sur les quotas
- [ ] Instructions d'upgrade de plan
- [ ] Documentation des erreurs courantes

### 18. Formation équipe
- [ ] Former l'équipe sur l'architecture
- [ ] Documenter les procédures support
- [ ] Créer un runbook pour les incidents
- [ ] Former sur Partner Center

## 🎯 Tests de Validation Finale

### 19. Tests End-to-End
- [ ] **Test complet du workflow** :
  1. [ ] Créer une offre test dans Partner Center
  2. [ ] S'abonner via Marketplace
  3. [ ] Webhook resolve → activate reçus
  4. [ ] Envoyer 300 questions via Teams
  5. [ ] Vérifier que la 301ème est bloquée
  6. [ ] Vérifier les événements d'usage publiés
  7. [ ] Tester la facturation dans Partner Center

### 20. Tests de régression
- [ ] Vérifier que les fonctionnalités existantes marchent
- [ ] Tests de performance (latence < 2s)
- [ ] Tests de charge (100 utilisateurs simultanés)
- [ ] Tests de fail-over et récupération

## 🚨 Prêt pour Production - Checklist Final

### 21. Pre-Production
- [ ] ✅ Tous les tests passent
- [ ] ✅ Monitoring configuré et testé
- [ ] ✅ Base de données sauvegardée
- [ ] ✅ Logs d'audit fonctionnels
- [ ] ✅ Webhooks Marketplace testés
- [ ] ✅ APIM quota policy validée
- [ ] ✅ Documentation complète

### 22. Go-Live
- [ ] Déploiement en production
- [ ] Tests smoke post-déploiement
- [ ] Monitoring des premiers utilisateurs
- [ ] Support prêt pour les questions
- [ ] Rollback plan préparé

## 📊 Post Go-Live

### 23. Suivi et optimisation
- [ ] Analyser les métriques d'usage
- [ ] Optimiser les performances
- [ ] Ajuster les alertes
- [ ] Collecter feedback utilisateurs
- [ ] Planifier les améliorations

---

## 🔥 Actions Prioritaires (à faire en premier)

1. **CRITIQUE** : Corriger les erreurs TypeScript
2. **CRITIQUE** : Configurer la base de données
3. **IMPORTANT** : Déployer APIM avec la policy de quota
4. **IMPORTANT** : Configurer les webhooks Marketplace
5. **MOYEN** : Tests d'intégration
6. **FAIBLE** : Documentation finale

---

## 📞 Contacts et Ressources

- **Microsoft Partner Center** : https://partner.microsoft.com
- **Azure API Management** : https://docs.microsoft.com/azure/api-management/
- **Marketplace Documentation** : https://docs.microsoft.com/marketplace/
- **Support Microsoft** : Via Partner Center

---

## 🎯 Estimation Temps

- **Setup initial (1-3)** : 2-3 jours
- **Infrastructure (4-5)** : 3-5 jours  
- **Corrections code (6-7)** : 2-3 jours
- **Tests (8-10)** : 3-4 jours
- **Déploiement (11-13)** : 2-3 jours
- **Sécurité (14-15)** : 2-3 jours
- **Documentation (16-18)** : 2-3 jours
- **Tests E2E (19-20)** : 2-3 jours

**TOTAL ESTIMÉ : 18-27 jours** (selon l'équipe et la complexité)
