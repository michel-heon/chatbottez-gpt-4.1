# Guide d'installation PostgreSQL pour Windows

## 🚀 Option Recommandée: Azure PostgreSQL (Déployé)

**Le système est maintenant configuré avec Azure PostgreSQL Flexible Server !**

```bash
# Tester la connexion à Azure PostgreSQL
make test-db

# Ou via npm
npm run test:db
```

### Infrastructure déployée :
- **Serveur** : PostgreSQL 16 dans Azure Canada Central
- **Base de données** : `marketplace_quota` 
- **Sécurité** : Intégration Azure Key Vault
- **Utilisateur** : `marketplace_user` configuré automatiquement

---

## Option Alternative: Installation locale (Développement)

### Option 1: Installation via l'installateur officiel

1. **Télécharger PostgreSQL** :
   - Aller sur https://www.postgresql.org/download/windows/
   - Télécharger la dernière version stable (16.x)

2. **Installation** :
   - Exécuter l'installateur
   - Port par défaut : 5432
   - Créer un mot de passe pour l'utilisateur `postgres`
   - Noter ce mot de passe !

3. **Configuration automatique** :
   ```bash
   # Utiliser le script de configuration automatique
   ./scripts/database-setup.sh
   
   # Ou via Makefile
   make database
   ```

4. **Tests** :
   ```bash
   # Tester la configuration
   make test-db
   
   # Ou directement
   npm run test:db
   ```

### Option 2: Installation via Chocolatey

Si vous avez Chocolatey installé :

```powershell
# Installer PostgreSQL
choco install postgresql

# Démarrer le service
net start postgresql-x64-14

# Configuration automatique
./scripts/database-setup.sh
```

## Option 3: Installation via Docker

Si vous préférez Docker :

```powershell
# Créer et démarrer un conteneur PostgreSQL
docker run --name postgres-marketplace `
  -e POSTGRES_PASSWORD=postgres `
  -e POSTGRES_DB=marketplace_quota `
  -e POSTGRES_USER=marketplace_user `
  -p 5432:5432 `
  -d postgres:16

# Vérifier que le conteneur fonctionne
docker ps
```

Puis mettre à jour .env.local :
```env
DB_PASSWORD=postgres
DATABASE_URL=postgresql://marketplace_user:postgres@localhost:5432/marketplace_quota
```

## Vérification de l'installation

1. **Tester la connexion** :
   ```powershell
   psql -h localhost -p 5432 -U marketplace_user -d postgres
   ```

2. **Créer la base de données** :
   ```powershell
   .\scripts\Setup-Database.ps1
   ```

3. **Tester la configuration** :
   ```powershell
   npm run test:db
   ```

## Dépannage

### Erreur de connexion
- Vérifier que PostgreSQL est démarré : `net start postgresql-x64-16`
- Vérifier le port : `netstat -an | findstr 5432`

### Erreur d'authentification
- Vérifier le mot de passe dans .env.local
- Réinitialiser le mot de passe si nécessaire

### Permissions
- S'assurer que l'utilisateur a les bonnes permissions
- Vérifier la configuration pg_hba.conf si nécessaire
