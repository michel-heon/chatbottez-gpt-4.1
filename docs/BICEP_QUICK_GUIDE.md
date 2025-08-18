# 🎯 Fichiers Bicep - Guide Rapide

## ✅ **Fichiers ACTUELLEMENT UTILISÉS**

### 🟢 **Templates Principaux DEV-05** (Production)
```
📄 complete-infrastructure-dev05.bicep          [PRINCIPAL - Subscription Level]
📄 complete-infrastructure-resources.bicep      [MODULE - Resource Group Level]  
📄 complete-infrastructure-dev05.parameters.json [PARAMÈTRES]
```

**Commande de déploiement** :
```bash
az deployment sub create \
  --location "Canada Central" \
  --template-file "infra/complete-infrastructure-dev05.bicep" \
  --parameters "@infra/complete-infrastructure-dev05.parameters.json"
```

## 🟡 **Fichiers de RÉFÉRENCE/COMPATIBILITÉ**

### Templates Historiques
```
📄 azure.bicep                    [Teams Framework Original - Requis pour compatibilité]
📄 complete-infrastructure.bicep  [Template de base - Référence]
```

### Modules Spécialisés
```
📄 botRegistration/azurebot.bicep [Module Bot Service]
📄 database/postgres.bicep        [Module PostgreSQL]  
📄 apim/apim.bicep               [Module API Management]
```

## ❌ **Fichiers SUPPRIMÉS** (Post-cleanup)

Ces fichiers étaient des versions de test et ont été nettoyés :
```
❌ complete-infrastructure-dev03.bicep
❌ complete-infrastructure-dev03.parameters.json
❌ complete-infrastructure-dev04.bicep  
❌ complete-infrastructure-dev04.parameters.json
```

## 🎯 **En Résumé**

**Pour déployer** : Utilisez `complete-infrastructure-dev05.bicep`  
**Architecture** : Voir [BICEP_ARCHITECTURE.md](BICEP_ARCHITECTURE.md)  
**Status DEV-05** : ✅ Déployé et fonctionnel

---

**Mis à jour** : 18 août 2025  
**Version** : v1.7.0-step6-application-deployment
