# Dev.Local - Gestionnaire de Services Docker Générique

Un système modulaire et générique pour gérer des services Docker avec profils dynamiques et gestion sécurisée des secrets via SOPS.

## 💡 À quoi sert Dev.Local ?

**Dev.Local** est un environnement de développement local orchestré qui simplifie la gestion de multiples services Docker. Il vous permet de :

- **Démarrer rapidement** un environnement complet avec tous vos services (APIs, bases de données, frontends, etc.)
- **Gérer facilement** plusieurs profils de services selon vos besoins (activer/désactiver des services à la volée)
- **Sécuriser vos secrets** (mots de passe, clés API) avec chiffrement SOPS intégré
- **Accéder simplement** à tous vos services via des URLs propres grâce à Traefik (ex: `http://localhost:8080/api`)
- **Travailler en équipe** avec une configuration partagée et reproductible

**Cas d'usage typiques :**
- Développeur frontend qui a besoin de plusieurs APIs backend
- Développeur fullstack gérant un écosystème de microservices
- Équipe partageant un environnement de développement standardisé
- Tests d'intégration nécessitant plusieurs services interconnectés

## 🎯 Caractéristiques

- **Gestion dynamique des profils** : Ajoutez facilement de nouveaux services
- **Secrets sécurisés** : Intégration SOPS avec AWS KMS ou Age
- **Configuration modulaire** : Chaque service dans son propre fichier
- **Menu interactif** : Interface simple pour toutes les opérations
- **Traefik intégré** : Reverse proxy automatique

## 🚀 Démarrage rapide

### 1. Prérequis

- Docker & Docker Compose v2+
- PowerShell 5.1+
- SOPS (binaire installé)
- AWS CLI (optionnel, pour KMS)

### 2. Configuration initiale

```powershell
# Connexion AWS (si utilisation de KMS)
.\launch.ps1 -c sso

# Créer le fichier de secrets
.\manage-profiles.ps1 -Action init-secrets

# Démarrer le menu
.\menu.ps1
```

## 📁 Structure du projet

```
dev.local/
├── profiles/               # Définitions des profils de services
│   ├── example.yml        # Template de profil
│   └── <nom-service>.yml  # Vos profils personnalisés
├── traefik/               # Configuration Traefik
│   ├── traefik.yml        # Config principale
│   └── dynamic.yml        # Config dynamique (généré)
├── docker-compose.yml     # Composition Docker (généré)
├── config.yml             # Configuration globale (Dozzle, etc.)
├── secrets.env            # Secrets chiffrés SOPS
├── .sops.yaml            # Configuration SOPS
├── menu.ps1              # Menu interactif
├── launch.ps1            # Script principal
├── manage-profiles.ps1   # Gestion des profils
└── README.md             # Ce fichier

```

## 🎮 Utilisation

Dev.Local offre **trois façons** de gérer vos services Docker :

### 1️⃣ Just (Recommandé - Multiplateforme)

[Just](https://github.com/casey/just) est un command runner simple et multiplateforme qui fonctionne sur Windows, Linux et macOS.

```bash
# Afficher toutes les commandes disponibles
just --list

# Démarrer tous les services
just start

# Démarrer avec profils spécifiques
just start-profile example,emp

# Voir les logs
just logs
just logs example

# Arrêter les services
just stop

# Autres commandes utiles
just ps              # Lister les containers
just validate        # Valider la configuration
just generate        # Régénérer docker-compose.yml
just secrets-edit    # Éditer les secrets
just aws-sso         # Connexion AWS
just menu            # Lancer le menu interactif

# Commandes AWS et Docker Registry
just aws-sso         # Connexion AWS SSO
just aws-id          # Afficher l'identité AWS
just ecr-login       # Login Docker à AWS ECR
just jfrog-login     # Login Docker à JFrog

# Aliases courts
just s               # start
just st              # stop
just r               # restart
just p               # ps
just g               # generate
just v               # validate
```

**Installation de Just :**
- **Windows (Chocolatey):** `choco install just`
- **Windows (Scoop):** `scoop install just`
- **Linux/macOS (Homebrew):** `brew install just`
- **Cargo:** `cargo install just`

### 2️⃣ Menu interactif

Le menu interactif offre une interface simple pour toutes les opérations :

**Avec Just (toutes plateformes) :**
```bash
just menu
```

**Windows (PowerShell) :**
```powershell
.\menu.ps1
```

**Linux/macOS (Bash) :**
```bash
./menu.sh
```

Options disponibles :
1. Démarrer tous les services
2. Démarrer avec profils spécifiques
3. Gérer les profils (ajouter/modifier/supprimer)
4. Gérer les secrets SOPS
5. Arrêter les services

### 3️⃣ Ligne de commande directe

**Windows (PowerShell) :**
```powershell
# Démarrer tous les services
.\launch.ps1

# Démarrer avec profils spécifiques
.\launch.ps1 -p service1,service2

# Voir les logs
.\launch.ps1 logs
.\launch.ps1 logs -service example

# Arrêter
.\launch.ps1 stop

# Autres commandes
.\launch.ps1 ps              # Lister les containers
.\launch.ps1 recreate        # Recréer les services
.\launch.ps1 edit-secrets    # Éditer les secrets
.\launch.ps1 view-secrets    # Voir les secrets déchiffrés
.\launch.ps1 sso             # Connexion AWS SSO
.\launch.ps1 id              # Afficher l'identité AWS
.\launch.ps1 ecr-login       # Login Docker ECR
```

**Linux/macOS (Bash) :**
```bash
# Démarrer tous les services
./launch.sh start

# Démarrer avec profils spécifiques
./launch.sh --profile service1,service2 start

# Voir les logs
./launch.sh logs
./launch.sh logs example

# Arrêter
./launch.sh stop

# Autres commandes
./launch.sh ps              # Lister les containers
./launch.sh recreate        # Recréer les services
./launch.sh edit-secrets    # Éditer les secrets
./launch.sh view-secrets    # Voir les secrets déchiffrés
./launch.sh sso             # Connexion AWS SSO
./launch.sh id              # Afficher l'identité AWS
./launch.sh ecr-login       # Login Docker ECR
```

### Quelle méthode choisir ?

| Méthode | Avantages | Quand utiliser |
|---------|-----------|----------------|
| **Just** | ✅ Syntaxe courte et claire<br>✅ Multiplateforme<br>✅ Autocomplete disponible<br>✅ Commandes mémorisables | Utilisation quotidienne, scripts CI/CD |
| **Menu** | ✅ Interface guidée<br>✅ Pas besoin de mémoriser les commandes<br>✅ Idéal pour les débutants | Découverte, opérations ponctuelles |
| **CLI directe** | ✅ Contrôle total<br>✅ Scriptable<br>✅ Pas de dépendances externes | Scripts automatisés, intégrations custom |

## 📝 Ajouter un nouveau service

### Option 1 : Via le menu interactif

```powershell
.\menu.ps1
# Choisir "3. Gérer les profils"
# Choisir "Ajouter un nouveau profil"
```

### Option 2 : Via la ligne de commande

```powershell
.\manage-profiles.ps1 -Action add
```

Le script vous guidera pour :
- Nom du service
- Image Docker
- Port d'exposition
- Variables d'environnement
- Secrets requis
- Configuration Traefik

## 🔐 Gestion des secrets avec SOPS

### Éditer les secrets

```powershell
# Via SOPS directement
sops secrets.env

# Via le script
.\launch.ps1 -c edit-secrets

# Via le menu
.\menu.ps1 # Option "Gérer les secrets"
```

### Format du fichier secrets.env

```env
# Secrets globaux
DATABASE_PASSWORD=ChangeMe123!
API_KEY=your-api-key-here

# Secrets par service (prefixés)
SERVICE1_SECRET_TOKEN=token123
SERVICE2_DB_PASSWORD=password456
```

### Configuration SOPS (.sops.yaml)

```yaml
creation_rules:
  - path_regex: secrets\.env$
    # Option 1 : AWS KMS
    kms: 'arn:aws:kms:REGION:ACCOUNT:key/KEY-ID'
    
    # Option 2 : Age
    # age: 'age1...'
```

## 📋 Format d'un profil

Les profils sont des fichiers YAML dans le dossier `profiles/` :

```yaml
# profiles/mon-service.yml
name: mon-service
description: "Description du service"
enabled: true

# Configuration Docker Compose (copié tel quel)
docker-compose:
  image: myregistry/service:latest
  container_name: mon-service
  ports:
    - "8000:8000"
  environment:
    - ENV_VAR=value
    - SECRET_KEY=${SECRET_KEY:-changeme}

# Configuration Traefik (optionnel)
traefik:
  enabled: true
  prefix: /mon-service
  strip_prefix: true
  port: 8000
  priority: 10
  failover: false  # Active le failover host/docker
  host_port: 8000  # Port du service local (si failover)
  health_path: /health

# Documentation des secrets requis (recommandé)
secrets:
  - name: SECRET_KEY
    description: "Clé API secrète"
    default: changeme
  - name: DATABASE_PASSWORD
    description: "Mot de passe de la base de données"
    default: changeme

# Métadonnées (optionnel)
metadata:
  category: api
  tags:
    - backend
    - production
```

### Section `secrets:` (recommandée)

Cette section documente explicitement les secrets requis :
- **name** : Nom de la variable (doit correspondre à `${VAR}` dans `environment`)
- **description** : Utilité du secret
- **default** : Valeur par défaut (utilisée lors de la synchronisation)

La commande `sync-secrets` utilise cette section pour mettre à jour automatiquement `secrets.env`.
name: mon-service
enabled: true

service:
  image: registry.example.com/mon-service:latest
  container_name: mon-service
  ports:
    - "8001:8000"
  environment:
    - ENV_MODE=docker
    - SERVICE_PORT=8000
    # Secrets chargés depuis secrets.env
    - API_KEY=${MON_SERVICE_API_KEY}
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
    interval: 30s
    timeout: 5s
    retries: 3

traefik:
  enabled: true
  prefix: /mon-service
  strip_prefix: true
  port: 8000
```

## 🔧 Configuration avancée

### Basculer entre différentes images Docker

Vous pouvez facilement basculer entre différentes versions ou registres d'images pour un service en utilisant des **variables d'environnement**.

#### Méthode 1 : Variables d'environnement dans le profil (Recommandé)

Modifiez votre profil pour utiliser des variables d'environnement (image et tag séparés pour plus de flexibilité) :

```yaml
# profiles/example.yml
docker-compose:
  # Image et tag séparés (recommandé)
  image: ${EXAMPLE_IMAGE:-<id>.dkr.ecr.ca-central-1.amazonaws.com/example}:${EXAMPLE_TAG:-latest}
  container_name: example
  # ... reste de la config
```

Ensuite, basculez entre les images selon vos besoins :

**Avec Just :**
```bash
# Utiliser l'image par défaut (production avec tag latest)
just start-profile example

# Utiliser le tag dev
$env:example_TAG="dev"
just start-profile example

# Utiliser une image locale
$env:EXAMPLE_IMAGE="EXAMPLE"
$env:EXAMPLE_TAG="local"
just start-profile example

# Utiliser un autre registre
$env:EXAMPLE_IMAGE="ghcr.io/myorg/example"
$env:EXAMPLE_TAG="v2.0.0"
just start-profile example

# Tester une branche feature
$env:EXAMPLE_TAG="feature-new-api"
just start-profile example
```

**Avec PowerShell :**
```powershell
# Changer uniquement le tag
$env:EXAMPLE_TAG="dev"
.\launch.ps1 -p example

# Changer image et tag
$env:EXAMPLE_IMAGE="EXAMPLE"; $env:EXAMPLE_TAG="local"
.\launch.ps1 -p example

# Ou en ligne séparée
$env:EXAMPLE_IMAGE = "ghcr.io/myorg/EXAMPLE"
$env:EXAMPLE_TAG = "staging"
.\launch.ps1 -p example
```

**Avec Bash :**
```bash
# Changer uniquement le tag
export EXAMPLE_TAG="dev"
./launch.sh --profile example start

# Changer image et tag en une ligne
EXAMPLE_IMAGE="EXAMPLE" EXAMPLE_TAG="local" ./launch.sh --profile example start
```

#### Méthode 2 : Fichier .env pour une configuration persistante

Créez un fichier `.env` à la racine (il est déjà dans `.gitignore`) :

```env
# .env
# Images personnalisées avec tags séparés
EXAMPLE_IMAGE=<id>.dkr.ecr.ca-central-1.amazonaws.com/cgpt-EXAMPLE
EXAMPLE_TAG=dev

FRONTEND_IMAGE=ghcr.io/myorg/frontend
FRONTEND_TAG=feature-xyz

API_IMAGE=myregistry.com/api
API_TAG=v2.0.0

# Ou pour développement local
EXAMPLE_IMAGE=EXAMPLE
EXAMPLE_TAG=local

# Versions spécifiques des dépendances
NODE_VERSION=20-alpine
POSTGRES_VERSION=15.2
```

Les variables seront automatiquement chargées par Docker Compose !

#### Tips et Bonnes Pratiques

1. **Nommage cohérent** : Utilisez `<SERVICE>_IMAGE` (sans tag), `<SERVICE>_TAG`, et optionnellement `<SERVICE>_REGISTRY`
2. **Séparation image/tag** : Préférez séparer l'image et le tag pour faciliter les changements de version
3. **Valeurs par défaut** : Toujours fournir une valeur par défaut avec `${VAR:-default}`
4. **Documentation** : Documentez les variables disponibles dans le profil ou le README
5. **Fichier .env.example** : Créez un exemple pour votre équipe (déjà fourni)
6. **Pas de secrets** : Les secrets vont dans `secrets.env` (chiffré), pas `.env`
7. **Tags explicites** : Évitez `latest` en production, utilisez des versions spécifiques

**Exemples de bons formats :**
```yaml
# ✅ Bon : Image et tag séparés
image: ${SERVICE_IMAGE:-registry.com/service}:${SERVICE_TAG:-v1.0.0}

# ✅ Bon : Avec registre optionnel
image: ${SERVICE_REGISTRY:-registry.com}/${SERVICE_IMAGE:-service}:${SERVICE_TAG:-v1.0.0}

# ❌ Moins flexible : Tout dans une variable
image: ${SERVICE_IMAGE:-registry.com/service:v1.0.0}
```

### Configuration globale (config.yml)

Le fichier `config.yml` permet d'activer/désactiver des services optionnels :

```yaml
# Dozzle - Monitoring des logs Docker
dozzle_enabled: true
dozzle_port: 9999  # Accessible via http://localhost:9999 ou http://localhost:8080/logs
```

### Variables d'environnement

Créer un fichier `.env` (non versionné) pour les variables locales :

```env
# Registre Docker
DOCKER_REGISTRY=registry.example.com

# Versions des images
SERVICE1_VERSION=latest
SERVICE2_VERSION=v1.2.3
```

### Personnalisation Traefik

Modifier `traefik/traefik.yml` pour :
- Changer les ports
- Activer HTTPS
- Configurer les certificats
- Ajouter des middlewares

## 🛠️ Scripts disponibles

| Script | Description | Équivalent Just |
|--------|-------------|-----------------|
| `menu.ps1` / `menu.sh` | Menu interactif principal | `just menu` |
| `launch.ps1` / `launch.sh` | Gestion des services Docker | - |
| `manage-profiles.ps1` / `manage-profiles.sh` | Gestion des profils de services | - |

### Commandes disponibles

#### Services Docker
| Commande | Just | PowerShell | Bash | Description |
|----------|------|------------|------|-------------|
| Démarrer | `just start` | `.\launch.ps1 start` | `./launch.sh start` | Démarrer tous les services |
| Démarrer profils | `just start-profile example,emp` | `.\launch.ps1 -p example,emp` | `./launch.sh --profile example,emp start` | Démarrer des profils spécifiques |
| Arrêter | `just stop` | `.\launch.ps1 stop` | `./launch.sh stop` | Arrêter tous les services |
| Redémarrer | `just restart` | `.\launch.ps1 recreate` | `./launch.sh recreate` | Recréer les services |
| Lister | `just ps` | `.\launch.ps1 ps` | `./launch.sh ps` | Lister les containers |
| Logs | `just logs [service]` | `.\launch.ps1 logs [-service xxx]` | `./launch.sh logs [service]` | Voir les logs |

#### Profils
| Commande | Just | PowerShell | Bash | Description |
|----------|------|------------|------|-------------|
| Lister | `just profiles` | `.\manage-profiles.ps1 list` | `./manage-profiles.sh list` | Lister les profils |
| Générer | `just generate` | `.\manage-profiles.ps1 generate` | `./manage-profiles.sh generate` | Regénérer docker-compose.yml |
| Valider | `just validate` | - | - | Valider la configuration |

#### Secrets (SOPS)
| Commande | Just | PowerShell | Bash | Description |
|----------|------|------------|------|-------------|
| Éditer | `just secrets-edit` | `.\launch.ps1 edit-secrets` | `./launch.sh edit-secrets` | Éditer les secrets |
| Voir | `just secrets-view` | `.\launch.ps1 view-secrets` | `./launch.sh view-secrets` | Voir les secrets déchiffrés |

#### AWS et Docker Registry
| Commande | Just | PowerShell | Bash | Description |
|----------|------|------------|------|-------------|
| AWS SSO | `just aws-sso` | `.\launch.ps1 sso` | `./launch.sh sso` | Connexion AWS SSO |
| Identité AWS | `just aws-id` | `.\launch.ps1 id` | `./launch.sh id` | Afficher l'identité AWS |
| ECR Login | `just ecr-login` | `.\launch.ps1 ecr-login` | `./launch.sh ecr-login` | Login Docker à AWS ECR |
| JFrog Login | `just jfrog-login` | `.\launch.ps1 jfrog-login` | `./launch.sh jfrog-login` | Login Docker à JFrog |

#### Utilitaires
| Commande | Just | PowerShell | Bash | Description |
|----------|------|------------|------|-------------|
| Menu | `just menu` | `.\menu.ps1` | `./menu.sh` | Lancer le menu interactif |
| Nettoyer | `just clean` | `docker compose down -v` | `docker compose down -v` | Nettoyer containers et volumes |
| Config | `just config` | `docker compose config` | `docker compose config` | Afficher la config finale |

## 📚 Exemples

### Ajouter un service API

```powershell
.\manage-profiles.ps1 -Action add
# Nom: api-backend
# Image: myregistry/api:latest
# Port: 8002
# Prefix Traefik: /api
# Secrets: API_SECRET_KEY, DB_PASSWORD
```

### Ajouter un service Frontend

```powershell
.\manage-profiles.ps1 -Action add
# Nom: frontend
# Image: myregistry/frontend:latest
# Port: 3000
# Prefix Traefik: /
# Secrets: (aucun)
```

### Démarrer uniquement certains services

```powershell
.\launch.ps1 -p api-backend,frontend
```

## ☁️ AWS et Docker Registry

Dev.Local supporte l'authentification AWS SSO et les connexions aux registres Docker privés.

### Connexion AWS SSO

Avant d'utiliser des images depuis AWS ECR, connectez-vous avec AWS SSO :

**Avec Just :**
```bash
just aws-sso
```

**Avec les scripts :**
```powershell
# Windows
.\launch.ps1 sso

# Linux/macOS
./launch.sh sso
```

### Connexion Docker à AWS ECR

Une fois connecté à AWS SSO, authentifiez Docker avec ECR :

**Avec Just :**
```bash
just ecr-login
```

**Avec les scripts :**
```powershell
# Windows
.\launch.ps1 ecr-login

# Linux/macOS
./launch.sh ecr-login
```

### Vérifier l'identité AWS

Pour vérifier quelle identité AWS est actuellement utilisée :

**Avec Just :**
```bash
just aws-id
```

**Avec les scripts :**
```powershell
# Windows
.\launch.ps1 id

# Linux/macOS
./launch.sh id
```

### Workflow complet avec AWS

```bash
# 1. Se connecter à AWS SSO
just aws-sso

# 2. Vérifier l'identité (optionnel)
just aws-id

# 3. Se connecter à Docker ECR
just ecr-login

# 4. Démarrer les services avec images ECR
just start
```

### Configuration du profil AWS

Les scripts utilisent le profil AWS `ESG-DV-PowerUser-SSO` par défaut. Pour utiliser un autre profil, modifiez la fonction `Connect-AwsSso` dans `launch.ps1` ou `connect_aws_sso` dans `launch.sh`.

## 🐧 Support Linux/macOS

Dev.Local est **100% compatible** avec Linux et macOS grâce aux scripts Bash !

### Scripts Bash Disponibles

- `menu.sh` - Menu interactif (équivalent de menu.ps1)
- `manage-profiles.sh` - Gestion des profils (équivalent de manage-profiles.ps1)
- `launch.sh` - Orchestration des services (équivalent de launch.ps1)
- `test-bash-scripts.sh` - Validation automatique de l'installation

### Utilisation sur Linux/macOS

```bash
# Rendre les scripts exécutables (une seule fois)
chmod +x *.sh

# Lancer le menu interactif
./menu.sh

# Ou utiliser directement les commandes
./manage-profiles.sh add
./launch.sh start
```

### Documentation Bash

- [BASH_README.md](BASH_README.md) - Guide complet pour Linux/macOS
- [CHEATSHEET.md](CHEATSHEET.md) - Aide-mémoire des commandes

## 📚 Documentation Complète

### Guides Disponibles

- [QUICKSTART.md](QUICKSTART.md) - Démarrage rapide (Windows + Linux)
- [BASH_README.md](BASH_README.md) - Guide utilisateur Linux/macOS
- [CHEATSHEET.md](CHEATSHEET.md) - Aide-mémoire des commandes essentielles
- [FILE_INDEX.md](FILE_INDEX.md) - Index complet de tous les fichiers

## 🔒 Sécurité

- ✅ Secrets chiffrés avec SOPS (AWS KMS ou Age)
- ✅ `.gitignore` configuré pour exclure les secrets en clair
- ✅ Validation automatique de la configuration SOPS
- ✅ Aucun secret en dur dans les fichiers versionnés

## 🌍 Compatibilité Multiplateforme

| Fonctionnalité | Windows | Linux | macOS | WSL2 |
|----------------|---------|-------|-------|------|
| Menu interactif | ✅ | ✅ | ✅ | ✅ |
| Gestion profils | ✅ | ✅ | ✅ | ✅ |
| SOPS secrets | ✅ | ✅ | ✅ | ✅ |
| Docker profiles | ✅ | ✅ | ✅ | ✅ |
| Traefik | ✅ | ✅ | ✅ | ✅ |
| AWS CLI | ✅ | ✅ | ✅ | ✅ |

**Fichiers 100% compatibles** entre plateformes :
- `profiles/*.yml`
- `docker-compose.yml`
- `traefik/dynamic.yml`
- `secrets.env` (chiffré SOPS)
- `config.yml`

## 🤝 Contribution

1. Créer un nouveau profil dans `profiles/`
2. Tester :
   - Windows : `.\launch.ps1 -p mon-nouveau-service`
   - Linux : `./launch.sh --profile mon-nouveau-service start`
3. Committer le profil (sans secrets!)

## 📞 Support

### Windows (PowerShell)
1. Consulter [README.md](README.md) et [QUICKSTART.md](QUICKSTART.md)
2. Utiliser le menu : `.\menu.ps1`
3. Aide-mémoire : [CHEATSHEET.md](CHEATSHEET.md)

### Linux/macOS (Bash)
1. Consulter [BASH_README.md](BASH_README.md)
2. Utiliser le menu : `./menu.sh`
3. Tester l'installation : `./test-bash-scripts.sh`

### Logs et Débogage
```bash
# Valider la configuration
docker compose config --quiet

# Voir les logs
docker compose logs -f

# Tester SOPS
sops -d secrets.env
```

## 📄 Licence

À définir selon votre projet.
