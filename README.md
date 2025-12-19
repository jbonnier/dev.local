# Dev.Local - Gestionnaire de Services Docker Générique

Un système modulaire et générique pour gérer des services Docker avec profils dynamiques et gestion sécurisée des secrets via SOPS.

## 📑 Table des matières

- [💡 À quoi sert Dev.Local ?](#-à-quoi-sert-devlocal-)
- [🎯 Caractéristiques](#-caractéristiques)
- [🚀 Démarrage rapide](#-démarrage-rapide)
- [📁 Structure du projet](#-structure-du-projet)
- [🎮 Utilisation](#-utilisation)
- [📝 Ajouter un nouveau service](#-ajouter-un-nouveau-service)
- [📋 Format d'un profil](#-format-dun-profil)
- [🔄 Variables d'environnement partagées](#-variables-denvironnement-partagées)
- [🔐 Gestion des secrets avec SOPS](#-gestion-des-secrets-avec-sops)
- [📚 Exemples pratiques](#-exemples-pratiques)
- [🐧 Support Linux/macOS](#-support-linuxmacos)
- [🔒 Sécurité](#-sécurité)
- [📚 Documentation complète](#-documentation-complète)
- [🔧 Développement](#-développement)
- [🤝 Contribution](#-contribution)
- [📄 Licence](#-licence)

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

### Prérequis

**Obligatoires :**
- Docker & Docker Compose v2+
- PowerShell 5.1+ (Windows) ou Bash (Linux/macOS)
- SOPS (binaire installé et dans le PATH)

**Optionnels :**
- AWS CLI (pour utiliser AWS KMS avec SOPS)
- Just command runner (recommandé pour faciliter l'utilisation)
- Age (alternative à AWS KMS pour SOPS)
- yq (optionnel mais recommandé) — utilitaire YAML pour parser correctement les profils lors de la génération. Le script `manage-profiles.sh` utilise `yq` quand il est disponible, sinon il retombe sur une implémentation sed/grep.

### Installation de SOPS

**Windows (Chocolatey) :**
```powershell
choco install sops
```

**Linux :**
```bash
# Via release GitHub
wget https://github.com/mozilla/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64
sudo mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops
chmod +x /usr/local/bin/sops
```

**macOS (Homebrew) :**
```bash
brew install sops
```

### (Optionnel) Installation de yq (recommandé)

Si vous voulez que la génération des fichiers soit la plus robuste possible (parsing YAML fiable), installez `yq` (mikefarah) :

**Linux (binaire officiel) :**
```bash
sudo wget -q -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
sudo chmod +x /usr/local/bin/yq
```

**macOS (Homebrew) :**
```bash
brew install yq
```

Une fois `yq` installé, `manage-profiles.sh` l'utilisera automatiquement.

### Configuration initiale

#### 1. Configurer SOPS

**Option A : Utiliser Age (recommandé pour débuter)**

```powershell
# Générer une clé Age
age-keygen -o age-key.txt

# Copier la clé publique affichée (commence par "age1...")
# Éditer .sops.yaml et remplacer la clé Age par la vôtre

# Définir la clé privée
$env:SOPS_AGE_KEY_FILE = "$(Get-Location)\age-key.txt"
```

**Option B : Utiliser AWS KMS**

```powershell
# Se connecter à AWS SSO
.\launch.ps1 -c sso

# Éditer .sops.yaml avec votre ARN KMS
# kms: 'arn:aws:kms:REGION:ACCOUNT:key/KEY-ID'
```

#### 2. Initialiser le fichier de secrets

```powershell
# Créer et éditer secrets.env (chiffré automatiquement)
.\manage-profiles.ps1 -Action init-secrets
```

#### 3. Créer votre premier profil de service

```powershell
# Via le menu interactif (recommandé pour débuter)
.\menu.ps1

# Ou en ligne de commande
.\manage-profiles.ps1 -Action add
```

#### 4. Générer et démarrer

```powershell
# Générer docker-compose.yml
.\manage-profiles.ps1 -Action generate

# Démarrer tous les services
.\launch.ps1

# OU utiliser Just (si installé)
just generate
just start
```

### Note : génération des fichiers (yq préféré, fallback présent)

- Le script Bash `./manage-profiles.sh` privilégie `yq` lorsqu'il est installé pour parser correctement les fichiers YAML (profils et `config.yml`). Si `yq` n'est pas présent, un parsing basé sur sed/grep est utilisé en fallback.

- Commandes pour (re)générer les fichiers :

  - Sous Bash / Linux / macOS :
  ```bash
  ./manage-profiles.sh generate
  ```

  - Sous PowerShell / Windows :
  ```powershell
  .\manage-profiles.ps1 -Action generate
  ```

- Ce que le script génère maintenant :
  - `docker-compose.yml` (généré) — contient désormais en en-tête la clé `name: <namespace>` prise depuis `config.yml` (clé `namespace`). Par défaut, si `config.yml` ne contient pas `namespace`, la valeur `devlocal` est utilisée.
  - `traefik/dynamic.yml` (généré) — configuration dynamique des routers, services et middlewares pour Traefik.

- Exemple rapide pour regénérer et vérifier :

```bash
./manage-profiles.sh generate
sed -n '1,40p' docker-compose.yml        # vérifier l'en-tête et la clé `name:`
sed -n '1,240p' traefik/dynamic.yml     # vérifier la config Traefik
```

### Vérification de l'installation

Après le démarrage, vérifiez que tout fonctionne :

- **Traefik Dashboard :** http://localhost:8081/
- **Dozzle (logs) :** http://localhost:9999/ ou http://localhost:8080/logs
- **Vos services :** http://localhost:8080/[prefix-du-service]

📚 **Guide détaillé :** Consultez [QUICKSTART.md](QUICKSTART.md) pour un tutoriel pas-à-pas complet.

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

### Méthodes disponibles

#### Option 1 : Menu interactif (Recommandé pour débuter)

```powershell
# Windows
.\menu.ps1

# Linux/macOS
./menu.sh

# Avec Just
just menu
```

Puis choisir : **"Ajouter un nouveau profil"**

#### Option 2 : Ligne de commande

```powershell
# Windows
.\manage-profiles.ps1 -Action add

# Linux/macOS
./manage-profiles.sh add
```

Le script vous guidera étape par étape pour configurer :
- ✅ Nom du service
- ✅ Description
- ✅ Image Docker (avec support de variables)
- ✅ Ports (conteneur et hôte)
- ✅ Variables d'environnement
- ✅ Secrets requis (stockés dans secrets.env chiffré)
- ✅ Configuration Traefik (routing HTTP)
- ✅ Health checks

### Exemple de création guidée

```
Nom du service: mon-api
Description: Mon API REST backend
Image Docker: ${MON_API_IMAGE:-myregistry/api}:${MON_API_TAG:-latest}
Port du service (conteneur): 8000
Port hôte: 8001
Activer Traefik ? (O/n): o
Préfixe de route: /api
Supprimer le préfixe avant transmission ? (O/n): o
Port du service pour Traefik: 8000
```

Le profil sera créé dans `profiles/mon-api.yml`.

## 🔄 Variables d'environnement partagées

Dev.Local supporte l'injection automatique de variables d'environnement communes à tous vos services. Ceci est idéal pour :

- 🌐 URLs de services externes (APIs, passerelles, authentification)
- 🔧 Configuration commune (log level, timezone, environnement)
- 📊 Paramètres partagés entre microservices

### Configuration dans `config.yml`

```yaml
# Variables d'environnement partagées
shared_env:
  # Variables globales pour tous les services
  global:
    - LOG_LEVEL=info
    - NODE_ENV=development
    - TZ=America/Toronto
  
  # Variables pour des services externes
  external_services:
    - API_GATEWAY_URL=https://api.example.com
    - AUTH_SERVICE_URL=https://auth.example.com
    - MESSAGING_SERVICE_URL=https://messaging.example.com

# Configuration de l'injection
shared_env_config:
  enabled: true
  auto_inject:
    - global
    - external_services
  exclude_services: []  # Services à exclure
```

### Utilisation

Les variables partagées sont automatiquement injectées lors de la génération :

```powershell
.\manage-profiles.ps1 -Action generate
```

Le script affichera le nombre de variables injectées pour chaque service :
```
✅ Ajout : mon-service
   📌 6 variable(s) partagée(s)
```

**Note :** Les variables du profil ont priorité sur les variables partagées en cas de conflit.

📚 **Documentation complète :** [docs/shared-env-guide.md](docs/shared-env-guide.md)

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
```

```yaml
# ✅ Bon : Avec registre optionnel
image: ${SERVICE_REGISTRY:-registry.com}/${SERVICE_IMAGE:-service}:${SERVICE_TAG:-v1.0.0}
```

```yaml
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

## 🛠️ Scripts et commandes disponibles

### Scripts principaux

| Script | Windows | Linux/macOS | Just | Description |
|--------|---------|-------------|------|-------------|
| **Menu interactif** | `.\menu.ps1` | `./menu.sh` | `just menu` | Interface guidée pour toutes les opérations |
| **Lancer services** | `.\launch.ps1` | `./launch.sh start` | `just start` | Orchestration des services Docker |
| **Gérer profils** | `.\manage-profiles.ps1` | `./manage-profiles.sh` | - | Gestion des profils de services |

### Commandes par catégorie

#### 🐳 Services Docker

| Action | Just | PowerShell | Bash |
|--------|------|------------|------|
| Démarrer tous | `just start` | `.\launch.ps1` | `./launch.sh start` |
| Démarrer profils | `just start-profile api,ui` | `.\launch.ps1 -p api,ui` | `./launch.sh --profile api,ui start` |
| Arrêter | `just stop` | `.\launch.ps1 stop` | `./launch.sh stop` |
| Redémarrer | `just restart` | `.\launch.ps1 recreate` | `./launch.sh recreate` |
| Statut | `just ps` | `.\launch.ps1 ps` | `./launch.sh ps` |
| Logs tous | `just logs` | `.\launch.ps1 logs` | `./launch.sh logs` |
| Logs service | `just logs api` | `.\launch.ps1 logs -service api` | `./launch.sh logs api` |
| Nettoyer | `just clean` | `docker compose down -v` | `docker compose down -v` |

#### 📋 Profils de services

| Action | Just | PowerShell | Bash |
|--------|------|------------|------|
| Lister | `just profiles` | `.\manage-profiles.ps1 list` | `./manage-profiles.sh list` |
| Ajouter | - | `.\manage-profiles.ps1 add` | `./manage-profiles.sh add` |
| Générer | `just generate` | `.\manage-profiles.ps1 generate` | `./manage-profiles.sh generate` |
| Valider | `just validate` | `docker compose config --quiet` | `docker compose config --quiet` |

#### 🔐 Secrets (SOPS)

| Action | Just | PowerShell | Bash |
|--------|------|------------|------|
| Éditer | `just secrets-edit` | `.\launch.ps1 edit-secrets` | `./launch.sh edit-secrets` |
| Voir | `just secrets-view` | `.\launch.ps1 view-secrets` | `./launch.sh view-secrets` |
| Initialiser | - | `.\manage-profiles.ps1 init-secrets` | `./manage-profiles.sh init-secrets` |
| Synchroniser | - | `.\manage-profiles.ps1 sync-secrets` | `./manage-profiles.sh sync-secrets` |

#### ☁️ AWS et Docker Registry

| Action | Just | PowerShell | Bash |
|--------|------|------------|------|
| AWS SSO Login | `just aws-sso` | `.\launch.ps1 sso` | `./launch.sh sso` |
| AWS Identity | `just aws-id` | `.\launch.ps1 id` | `./launch.sh id` |
| ECR Login | `just ecr-login` | `.\launch.ps1 ecr-login` | `./launch.sh ecr-login` |
| JFrog Login | `just jfrog-login` | `.\launch.ps1 jfrog-login` | `./launch.sh jfrog-login` |

#### 🔧 Utilitaires

| Action | Just | PowerShell | Bash |
|--------|------|------------|------|
| Config finale | `just config` | `docker compose config` | `docker compose config` |
| Vérifier perms .sh | - | `.\fix-sh-permissions.ps1` | `chmod +x *.sh` |
| Menu | `just menu` | `.\menu.ps1` | `./menu.sh` |

### Raccourcis Just (aliases)

Si vous utilisez Just, ces raccourcis sont disponibles :

```bash
just s     # start
just st    # stop
just r     # restart
just p     # ps (statut)
just g     # generate
just v     # validate
just l     # logs
just m     # menu
```

## 📚 Exemples pratiques

### Exemple 1 : API Backend + Frontend

Créer une stack complète API + Frontend avec routing Traefik :

```powershell
# 1. Ajouter le backend
.\manage-profiles.ps1 -Action add
# Nom: api-backend
# Image: ${API_IMAGE:-myregistry/api}:${API_TAG:-latest}
# Port: 8000 -> 8001
# Traefik: oui, /api, strip_prefix: oui

# 2. Ajouter le frontend
.\manage-profiles.ps1 -Action add
# Nom: frontend
# Image: ${FRONTEND_IMAGE:-myregistry/frontend}:${FRONTEND_TAG:-latest}
# Port: 3000 -> 3001
# Traefik: oui, /, strip_prefix: non

# 3. Configurer les secrets
.\launch.ps1 -c edit-secrets
# Ajouter:
# API_BACKEND_DB_PASSWORD=secret123
# API_BACKEND_API_KEY=mykey456

# 4. Configurer les variables partagées (optionnel)
# Éditer config.yml et ajouter des URLs communes

# 5. Démarrer
.\launch.ps1 -p api-backend,frontend
# OU avec Just:
just start-profile api-backend,frontend

# 6. Tester
# Frontend : http://localhost:8080/
# API : http://localhost:8080/api
# Traefik Dashboard : http://localhost:8081/
# Dozzle (logs) : http://localhost:9999/
```

### Exemple 2 : Microservices avec services externes

Utiliser les variables partagées pour des URLs communes :

```yaml
# config.yml
shared_env:
  global:
    - LOG_LEVEL=info
    - NODE_ENV=development
  
  external_services:
    - AUTH_SERVICE_URL=https://auth.mycompany.com
    - PAYMENT_API_URL=https://api.stripe.com/v1
    - STORAGE_URL=https://s3.amazonaws.com/mybucket
```

Tous vos services auront automatiquement accès à ces variables !

### Exemple 3 : Basculer entre environnements

Utiliser des variables d'environnement pour basculer entre dev/staging/prod :

```powershell
# Développement local
$env:API_IMAGE="api"; $env:API_TAG="local"
.\launch.ps1 -p api-backend

# Staging
$env:API_IMAGE="myregistry/api"; $env:API_TAG="staging"
.\launch.ps1 -p api-backend

# Production
$env:API_IMAGE="myregistry/api"; $env:API_TAG="v2.1.0"
.\launch.ps1 -p api-backend

# Ou via fichier .env (persistent)
echo "API_IMAGE=myregistry/api" > .env
echo "API_TAG=dev" >> .env
.\launch.ps1 -p api-backend
```

### Exemple 4 : Développement avec hot-reload

Monter un volume local pour le développement :

```yaml
# profiles/mon-service.yml
docker-compose:
  image: node:20-alpine
  volumes:
    - ./src:/app  # Code local monté dans le conteneur
    - /app/node_modules  # node_modules reste dans le conteneur
  environment:
    - NODE_ENV=development
  command: npm run dev
```

### Exemple 5 : Service avec dépendances

Service nécessitant une base de données :

```yaml
# profiles/api-with-db.yml
docker-compose:
  image: myapi:latest
  depends_on:
    postgres:
      condition: service_healthy
  environment:
    - DATABASE_URL=postgresql://user:${DB_PASSWORD}@postgres:5432/mydb

# Ajouter aussi postgres dans profiles/postgres.yml
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

## 🔧 Développement

### Conventional Commits

**TOUS les commits doivent respecter la spécification [Conventional Commits](https://www.conventionalcommits.org/).**

#### Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

#### Types de commits

- **feat**: Nouvelle fonctionnalité
- **fix**: Correction de bug
- **docs**: Modifications de documentation uniquement
- **style**: Changements de style (formatage, point-virgules manquants, etc.)
- **refactor**: Refactorisation sans ajout de fonctionnalité ni correction de bug
- **perf**: Amélioration des performances
- **test**: Ajout ou modification de tests
- **build**: Modifications du système de build ou des dépendances
- **ci**: Modifications de la configuration CI/CD
- **chore**: Autres modifications (maintenance, configuration, etc.)

#### Exemples

```bash
feat(profiles): add support for custom healthcheck configuration
fix(traefik): correct routing priority for dynamic routes
docs(readme): update installation instructions for Linux
refactor(launch): simplify service orchestration logic
chore(deps): update Docker Compose to v2.24.0
```

#### Breaking Changes

Pour les changements incompatibles, ajouter `BREAKING CHANGE:` dans le footer ou utiliser `!` après le type :

```
feat(api)!: remove deprecated v1 profile format

BREAKING CHANGE: Profile format v1 is no longer supported.
Users must migrate to v2 format using the migration script.
```

## 🤝 Contribution

### Workflow de contribution

1. Créer un nouveau profil dans `profiles/`
2. Tester :
   - Windows : `.\launch.ps1 -p mon-nouveau-service`
   - Linux : `./launch.sh --profile mon-nouveau-service start`
3. **Important** : Les secrets doivent TOUJOURS être placés dans `secrets.env` (chiffré avec SOPS), jamais dans les profils ou autres fichiers versionnés
4. Committer le profil en respectant le format Conventional Commits

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

## 🔧 Développeurs Windows : Permissions des fichiers .sh

Si vous travaillez sur Windows et contribuez au projet, assurez-vous que les fichiers `.sh` ont le bit exécutable pour les utilisateurs Linux/macOS.

### Vérification automatique

Utilisez le script fourni pour vérifier et corriger les permissions :

```powershell
.\fix-sh-permissions.ps1
```

Ce script :
- ✅ Vérifie tous les fichiers `.sh` du projet
- ✅ Affiche leur statut (exécutable ou non)
- ✅ Corrige automatiquement les permissions si nécessaire

### Correction manuelle

```powershell
# Rendre un fichier .sh exécutable
git update-index --chmod=+x fichier.sh

# Vérifier les permissions
git ls-files -s *.sh
# 100755 = exécutable ✅
# 100644 = non exécutable ❌
```

### Automatisation avec .gitattributes

Le fichier `.gitattributes` est déjà configuré pour :
- Assurer que les `.sh` utilisent LF (fins de ligne Unix)
- Normaliser les fins de ligne selon le type de fichier

**Important :** Après modification des permissions, committez les changements :
```powershell
git add <fichiers>
git commit -m "Fix: Ajouter bit exécutable aux scripts .sh"
```

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

Copyright (c) 2025 Dev.Local Contributors
