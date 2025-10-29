# Makefile Usage Guide for Microsoft 365 Agents ChatBot

Ce document explique comment utiliser le Makefile pour automatiser le cycle de vie de développement et de déploiement de votre Microsoft 365 Agents ChatBot.

## Prérequis

Avant d'utiliser le Makefile, assurez-vous d'avoir :

1. **Node.js** (version 18, 20 ou 22)
2. **npm** 
3. **TeamsFx CLI** (sera installé automatiquement si nécessaire)

## Configuration initiale

```bash
# Vérifier les prérequis
make check-prereq

# Installation complète (TeamsFx CLI + dépendances)
make setup

# Ou installation manuelle
make install-teamsfx  # Installe TeamsFx CLI globalement
make install          # Installe les dépendances du projet
```

## Commandes principales

### 🔍 Informations et aide

```bash
make help           # Affiche toutes les commandes disponibles
make status         # Affiche l'état actuel du projet
make info           # Informations détaillées du projet
make help-env       # Aide pour l'utilisation des environnements
```

### 🏗️ Construction et développement

```bash
make build          # Construit l'application
make dev            # Démarre le serveur de développement
make dev-playground # Démarre avec le playground
make start          # Démarre en mode production
```

### 🚀 Cycle de vie Microsoft 365 Agents

Le Makefile supporte trois environnements : `dev`, `local`, et `playground`.

#### Commandes individuelles

```bash
# Provision des ressources Azure
make provision ENV=dev
make provision ENV=local
make provision ENV=playground

# Déploiement de l'application
make deploy ENV=dev
make deploy ENV=local  
make deploy ENV=playground

# Publication vers Teams Admin Center
make publish ENV=dev
make publish ENV=local
make publish ENV=playground
```

#### Cycle complet automatisé

```bash
# Cycle complet pour un environnement spécifique
make full-lifecycle ENV=dev
make full-lifecycle ENV=local
make full-lifecycle ENV=playground

# Raccourcis pour chaque environnement
make lifecycle-dev          # Équivalent à full-lifecycle ENV=dev
make lifecycle-local        # Équivalent à full-lifecycle ENV=local
make lifecycle-playground   # Équivalent à full-lifecycle ENV=playground
```

### 📦 Gestion des packages

```bash
make package ENV=dev       # Crée le package d'application
make validate ENV=dev      # Valide le manifeste et le package
```

### 🌍 Gestion des environnements

```bash
make env-list              # Liste les environnements disponibles
make env-show ENV=dev      # Affiche les variables d'environnement
make env-create ENV=newenv # Crée un nouvel environnement
```

### 🧹 Maintenance

```bash
make clean                 # Nettoie les artéfacts de build
make clean-all            # Nettoie tout (incluant node_modules)
make reset                # Reset complet (clean + reinstall)
```

### ⚡ Commandes rapides

```bash
make quick-dev            # Setup rapide pour développement
make quick-prod           # Déploiement rapide en production
```

## Exemples d'utilisation typiques

### Développement local

```bash
# Configuration initiale
make setup
make build

# Cycle de développement
make provision ENV=dev
make deploy ENV=dev
make dev
```

### Déploiement en production

```bash
# Construction et déploiement complet
make build
make full-lifecycle ENV=dev

# Ou version raccourcie
make lifecycle-dev
```

### Test avec Playground

```bash
# Setup pour playground
make provision ENV=playground
make deploy ENV=playground
make dev-playground
```

### Publication vers l'organisation

```bash
# Après avoir testé votre application
make publish ENV=dev

# L'application sera soumise pour approbation dans Teams Admin Center
```

## Structure des environnements

Le Makefile utilise les fichiers d'environnement suivants :

- `env/.env.dev` - Environnement de développement
- `env/.env.local` - Environnement local
- `env/.env.playground` - Environnement playground

Chaque environnement peut avoir ses propres configurations Azure et Teams.

## Variables importantes

- `ENV` - Spécifie l'environnement (dev|local|playground)
- `TEAMSFX_ENV` - Variable TeamsFx (automatiquement définie)
- `PROJECT_NAME` - Nom du projet (chatbottez-gpt-4.1)

## Résolution de problèmes

### Erreur "Environment file not found"

```bash
# Vérifiez les environnements disponibles
make env-list

# Créez un nouvel environnement si nécessaire
make env-create ENV=mon-env
```

### Erreur "TeamsFx CLI not found"

```bash
# Installez TeamsFx CLI
make install-teamsfx
```

### Problèmes de build

```bash
# Reset complet du projet
make reset
```

## Flux de travail recommandé

1. **Configuration initiale**
   ```bash
   make setup
   make status
   ```

2. **Développement**
   ```bash
   make build
   make provision ENV=dev
   make deploy ENV=dev
   make dev
   ```

3. **Test**
   ```bash
   make validate ENV=dev
   make package ENV=dev
   ```

4. **Publication**
   ```bash
   make publish ENV=dev
   ```

5. **Production**
   ```bash
   make lifecycle-dev  # Cycle complet
   ```

## Notes importantes

- Toujours construire (`make build`) avant de déployer
- Les fichiers d'environnement doivent exister avant provision/deploy
- La publication soumet l'app pour approbation dans Teams Admin Center
- Utilisez `ENV=playground` pour les tests avec Microsoft 365 Agents Playground
- Les logs de déploiement sont disponibles avec `make logs`

Pour plus d'aide, utilisez `make help` ou `make help-env`.
