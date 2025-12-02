# Dev.Local 2.0 - Gestionnaire de Services Docker Générique

Un système modulaire et générique pour gérer des services Docker avec profils dynamiques et gestion sécurisée des secrets via SOPS.

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
Dev.Local.2.0/
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

Dev.Local 2.0 offre **trois façons** de gérer vos services Docker :

### 1️⃣ Just (Recommandé - Multiplateforme)

[Just](https://github.com/casey/just) est un command runner simple et multiplateforme qui fonctionne sur Windows, Linux et macOS.

```bash
# Afficher toutes les commandes disponibles
just --list

# Démarrer tous les services
just start

# Démarrer avec profils spécifiques
just start-profile andoc,emp

# Voir les logs
just logs
just logs andoc

# Arrêter les services
just stop

# Autres commandes utiles
just ps              # Lister les containers
just validate        # Valider la configuration
just generate        # Régénérer docker-compose.yml
just secrets-edit    # Éditer les secrets
just aws-sso         # Connexion AWS
just menu            # Lancer le menu interactif

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
.\launch.ps1 logs -service andoc

# Arrêter
.\launch.ps1 stop

# Autres commandes
.\launch.ps1 ps              # Lister les containers
.\launch.ps1 recreate        # Recréer les services
.\launch.ps1 edit-secrets    # Éditer les secrets
.\launch.ps1 sso             # Connexion AWS SSO
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
./launch.sh logs andoc

# Arrêter
./launch.sh stop

# Autres commandes
./launch.sh ps              # Lister les containers
./launch.sh recreate        # Recréer les services
./launch.sh edit-secrets    # Éditer les secrets
./launch.sh sso             # Connexion AWS SSO
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

| Script | Description |
|--------|-------------|
| `menu.ps1` | Menu interactif principal |
| `launch.ps1` | Gestion des services Docker |
| `manage-profiles.ps1` | Gestion des profils de services |

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

## 🐧 Support Linux/macOS

Dev.Local 2.0 est maintenant **100% compatible** avec Linux et macOS grâce aux scripts Bash !

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
