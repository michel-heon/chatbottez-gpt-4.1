# TODO - Microsoft Marketplace Quota Implementation

## 🔧 Setup et Configuration Immédiate

### 1. Installation des dépendances
- [ ] Exécuter `npm install` pour installer les nouvelles dépendances
- [ ] Vérifier que toutes les dépendances TypeScript sont installées
- [ ] Corriger les erreurs de compilation TypeScript

### 2. Configuration des variables d'environnement
- [ ] Copier `.env.example` vers `.env.local` ou `.env.development`
- [ ] Remplir les valeurs réelles pour :
  - [ ] `MARKETPLACE_API_KEY` (clé d'API Microsoft Marketplace)
  - [ ] `DATABASE_URL` (chaîne de connexion à la base de données)
  - [ ] `JWT_SECRET_KEY` (secret pour valider les webhooks)
  - [ ] `AZURE_STORAGE_CONNECTION_STRING` (pour retry des événements d'usage)
  - [ ] `APPLICATION_INSIGHTS_CONNECTION_STRING` (monitoring)

### 3. Base de données
- [ ] Créer une base de données PostgreSQL ou SQL Server
- [ ] Exécuter le script `src/db/schema.sql` pour créer les tables
- [ ] Configurer les permissions de base de données
- [ ] Tester la connexion

## 🏗️ Infrastructure Azure

### 4. Déploiement APIM (API Management)
- [ ] Créer un service Azure API Management
- [ ] Déployer le fichier `infra/apim/apim.bicep` :
  ```bash
  az deployment group create --resource-group your-rg --template-file infra/apim/apim.bicep --parameters @apim-parameters.json
  ```
- [ ] Configurer les Event Hubs pour les logs (optionnel)
- [ ] Tester la policy de quota APIM

### 5. Configuration Microsoft Marketplace
- [ ] Créer l'offre SaaS dans Partner Center
- [ ] Configurer le plan "300 questions/mois"
- [ ] Configurer les webhooks de fulfillment
- [ ] Configurer les dimensions de metered billing
- [ ] Obtenir les clés d'API Marketplace

## 🔨 Corrections de Code

### 6. Fixes TypeScript immédiats
- [ ] Corriger l'erreur dans `SubscriptionService.updateSubscription()` (type status)
- [ ] Ajouter les types Jest manquants
- [ ] Installer `@types/jest` et configurer Jest
- [ ] Corriger les imports manquants

### 7. Implémentation base de données réelle
- [ ] Remplacer `SubscriptionService` in-memory par une vraie DB
- [ ] Implémenter les repositories PostgreSQL/SQL Server
- [ ] Ajouter les migrations de base de données
- [ ] Configurer le connection pooling

## ✅ Tests et Validation

### 8. Tests unitaires
- [ ] Corriger la configuration Jest (`jest.config.js`)
- [ ] Faire passer tous les tests unitaires
- [ ] Ajouter des tests pour les nouveaux services
- [ ] Tests de couverture > 80%

### 9. Tests d'intégration
- [ ] Créer des tests d'intégration pour les webhooks Marketplace
- [ ] Tests de quota enforcement avec APIM
- [ ] Tests de publication d'événements d'usage
- [ ] Tests de retry logic

### 10. Tests de charge quota
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
- [ ] Finaliser `README_QUOTA.md`
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
