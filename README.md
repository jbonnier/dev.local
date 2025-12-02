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
├── secrets.env            # Secrets chiffrés SOPS
├── .sops.yaml            # Configuration SOPS
├── menu.ps1              # Menu interactif
├── launch.ps1            # Script principal
├── manage-profiles.ps1   # Gestion des profils
└── README.md             # Ce fichier

```

## 🎮 Utilisation

### Menu interactif

```powershell
.\menu.ps1
```

Options disponibles :
1. Démarrer tous les services
2. Démarrer avec profils spécifiques
3. Gérer les profils (ajouter/modifier/supprimer)
4. Gérer les secrets SOPS
5. Arrêter les services

### Ligne de commande

```powershell
# Démarrer tous les services
.\launch.ps1

# Démarrer avec profils spécifiques
.\launch.ps1 -p service1,service2

# Arrêter
.\launch.ps1 -c stop

# Gérer les secrets
.\launch.ps1 -c edit-secrets
```

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

## 🔒 Sécurité

- ✅ Secrets chiffrés avec SOPS (AWS KMS ou Age)
- ✅ `.gitignore` configuré pour exclure les secrets en clair
- ✅ Validation automatique de la configuration SOPS
- ✅ Aucun secret en dur dans les fichiers versionnés

## 🤝 Contribution

1. Créer un nouveau profil dans `profiles/`
2. Tester avec `.\launch.ps1 -p mon-nouveau-service`
3. Committer le profil (sans secrets!)

## 📞 Support

Pour toute question :
1. Consulter ce README
2. Exécuter `.\launch.ps1 -h` pour l'aide détaillée
3. Vérifier les logs : `docker compose logs -f`

## 📄 Licence

À définir selon votre projet.
