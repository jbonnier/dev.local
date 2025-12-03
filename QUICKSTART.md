# 🚀 Guide de Démarrage Rapide - Dev.Local 2.0

> **Guide pas-à-pas** pour démarrer avec Dev.Local en moins de 10 minutes !

## 📑 Table des matières

1. [Prérequis](#prérequis)
2. [Installation rapide](#installation-rapide)
3. [Configuration SOPS](#1-configuration-sops)
4. [Initialiser les secrets](#2-initialiser-les-secrets)
5. [Ajouter votre premier service](#3-ajouter-votre-premier-service)
6. [Démarrer les services](#4-démarrer-les-services)
7. [Variables partagées](#5-variables-partagées-optionnel)
8. [Commandes essentielles](#-commandes-essentielles)
9. [Exemple complet](#-exemple-complet)
10. [Dépannage](#-dépannage)
11. [Prochaines étapes](#-prochaines-étapes)

## Prérequis

1. ✅ Docker & Docker Compose v2+ installés
2. ✅ PowerShell 5.1+
3. ✅ SOPS installé (binaire dans le PATH)
4. ⚠️  AWS CLI (optionnel, pour KMS uniquement)

## Installation rapide

### 1. Configuration SOPS

Choisissez une méthode de chiffrement :

#### Option A : Age (recommandé pour débuter)

```powershell
# Générer une clé Age
age-keygen -o age-key.txt

# Afficher la clé publique (commence par "age1...")
Get-Content age-key.txt | Select-String "public key"

# Éditer .sops.yaml et décommenter la ligne age:
# age: 'age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p'
# Remplacer par votre clé publique

# Définir la clé privée
$env:SOPS_AGE_KEY_FILE = "$(Get-Location)\age-key.txt"
```

#### Option B : AWS KMS

```powershell
# Se connecter à AWS
.\launch.ps1 -c sso

# Éditer .sops.yaml et configurer :
# kms: 'arn:aws:kms:ca-central-1:ACCOUNT:key/KEY-ID'
```

### 2. Initialiser les secrets

```powershell
# Créer le fichier de secrets
.\manage-profiles.ps1 -Action init-secrets

# L'éditeur SOPS s'ouvrira automatiquement
# Ajoutez vos secrets, puis sauvegardez et fermez
```

### 3. Ajouter votre premier service

```powershell
# Via le menu interactif
.\menu.ps1
# Choisir option 6 : Ajouter un nouveau profil

# OU en ligne de commande
.\manage-profiles.ps1 -Action add
```

Exemple de réponses :
```
Nom du service: mon-api
Description: Mon API backend
Image Docker: nginx:latest
Port du service: 80
Port hôte: 8090
Activer Traefik: o
Préfixe de route: /api
Supprimer le préfixe: o
```

### 4. Démarrer les services

```powershell
# Démarrer tous les services
.\launch.ps1

# OU via le menu
.\menu.ps1

# OU avec Just (si installé)
just start
```

### 5. Variables partagées (Optionnel)

Les variables partagées permettent de centraliser des configurations communes (URLs d'APIs, log level, etc.).

```powershell
# Éditer config.yml
notepad config.yml
```

Ajouter vos variables communes :

```yaml
# config.yml
shared_env:
  global:
    - LOG_LEVEL=info
    - NODE_ENV=development
    - TZ=America/Toronto
  
  external_services:
    - API_GATEWAY_URL=https://api.example.com
    - AUTH_SERVICE_URL=https://auth.example.com

shared_env_config:
  enabled: true
  auto_inject:
    - global
    - external_services
```

Puis régénérer :

```powershell
.\manage-profiles.ps1 -Action generate
.\launch.ps1 -c recreate
```

**Avantages :**
- ✅ Centralisez les URLs communes
- ✅ Évitez la duplication
- ✅ Changez une variable partout d'un coup

📚 **Documentation complète :** [docs/shared-env-guide.md](docs/shared-env-guide.md)

## 🎯 Commandes essentielles

### Gestion des services

```powershell
# Démarrer tout
.\launch.ps1

# Démarrer services spécifiques
.\launch.ps1 -p api,frontend

# Arrêter
.\launch.ps1 -c stop

# Recréer
.\launch.ps1 -c recreate

# Voir le statut
.\launch.ps1 -c ps
```

### Gestion des profils

```powershell
# Lister les profils
.\manage-profiles.ps1 -Action list

# Ajouter un profil
.\manage-profiles.ps1 -Action add

# Regénérer docker-compose.yml
.\manage-profiles.ps1 -Action generate
```

### Gestion des secrets

```powershell
# Éditer les secrets
.\launch.ps1 -c edit-secrets

# Voir les secrets déchiffrés
.\launch.ps1 -c view-secrets

# Initialiser secrets.env
.\manage-profiles.ps1 -Action init-secrets
```

## 📝 Exemple complet

Créer un service API + Frontend :

```powershell
# 1. Ajouter le backend
.\manage-profiles.ps1 -Action add
# Nom: api-backend
# Image: myregistry/api:latest
# Port: 8000 -> 8001
# Traefik: oui, /api

# 2. Ajouter le frontend
.\manage-profiles.ps1 -Action add
# Nom: frontend
# Image: myregistry/frontend:latest
# Port: 3000 -> 3000
# Traefik: oui, /

# 3. Configurer les secrets
.\launch.ps1 -c edit-secrets
# Ajouter:
# API_BACKEND_DB_PASSWORD=secret123
# API_BACKEND_SECRET_KEY=mykey

# 4. Démarrer
.\launch.ps1 -p api-backend,frontend

# 5. Tester
# Frontend : http://localhost:8080/
# API : http://localhost:8080/api
# Traefik Dashboard : http://localhost:8081/
```

## 🔧 Dépannage

### SOPS ne fonctionne pas

```powershell
# Vérifier que SOPS est installé
sops --version

# Vérifier la config
Get-Content .sops.yaml

# Pour Age, vérifier la clé
$env:SOPS_AGE_KEY_FILE
Get-Content $env:SOPS_AGE_KEY_FILE

# Pour KMS, vérifier AWS
.\launch.ps1 -c id
```

### Docker Compose ne trouve pas les services

```powershell
# Regénérer docker-compose.yml
.\manage-profiles.ps1 -Action generate

# Vérifier le fichier
Get-Content docker-compose.yml
```

### Les secrets ne se chargent pas

```powershell
# Vérifier que secrets.env existe
Test-Path secrets.env

# Tester le déchiffrement
sops -d secrets.env

# Vérifier les variables
$env:MON_SECRET
```

## 📚 Prochaines étapes

### Documentation approfondie

1. **README principal** - [README.md](README.md)
   - Toutes les fonctionnalités détaillées
   - Guide complet des commandes
   - Configuration avancée

2. **Variables partagées** - [docs/shared-env-guide.md](docs/shared-env-guide.md)
   - Guide complet avec exemples
   - Cas d'usage pratiques
   - Configuration avancée

3. **Aide-mémoire** - [CHEATSHEET.md](CHEATSHEET.md)
   - Commandes essentielles
   - Raccourcis pratiques
   - Dépannage rapide

4. **Support Linux/macOS** - [BASH_README.md](BASH_README.md)
   - Guide complet Bash
   - Commandes Linux/macOS
   - Scripts bash

### Personnalisation

1. **Profils personnalisés**
   - Ajoutez vos services dans `profiles/`
   - Utilisez `profiles/example.yml` comme template
   - Documentation inline dans les profils

2. **Configuration Traefik**
   - Éditez `traefik/traefik.yml` pour changer les ports
   - Activez HTTPS
   - Configurez des middlewares

3. **Variables partagées**
   - Éditez `config.yml` pour centraliser vos URLs
   - Créez des groupes logiques (auth, database, external)
   - Activez/désactivez par service

4. **Secrets**
   - Ajoutez vos secrets dans `secrets.env` (chiffré)
   - Synchronisez automatiquement avec `sync-secrets`
   - Utilisez Age ou AWS KMS selon vos besoins

### Workflows recommandés

**Développement quotidien :**
```powershell
# Matin - Démarrer
just start

# Changer de branche/version
$env:API_TAG="feature-xyz"
just restart

# Voir les logs
just logs api

# Soir - Arrêter
just stop
```

**Ajouter un nouveau service :**
```powershell
# 1. Créer le profil
.\manage-profiles.ps1 -Action add

# 2. Ajouter les secrets
.\launch.ps1 -c edit-secrets

# 3. Regénérer et tester
.\manage-profiles.ps1 -Action generate
.\launch.ps1 -p nouveau-service
```

**Partager avec l'équipe :**
```powershell
# 1. Commiter les profils (sans secrets!)
git add profiles/nouveau-service.yml
git commit -m "Add nouveau-service profile"

# 2. Documenter les secrets requis
# Les secrets sont déjà documentés dans le profil

# 3. Partager les instructions
# L'équipe peut initialiser avec:
# .\launch.ps1 -c edit-secrets
```

## 💡 Astuces

### Alias PowerShell

Ajoutez à votre profil PowerShell (`$PROFILE`) :

```powershell
# Raccourcis Dev.Local 2.0
Set-Location "C:\Src\Dev.Local.2.0"
function menu { .\menu.ps1 }
function start { .\launch.ps1 }
function stop { .\launch.ps1 -c stop }
function secrets { .\launch.ps1 -c edit-secrets }
```

Ensuite, utilisez simplement :
```powershell
menu      # Ouvre le menu
start     # Démarre tout
stop      # Arrête tout
secrets   # Édite les secrets
```

### Variables d'environnement persistantes

Pour Age, ajoutez à votre profil PowerShell :

```powershell
$env:SOPS_AGE_KEY_FILE = "C:\Src\Dev.Local.2.0\age-key.txt"
```

## ✅ Checklist de démarrage

- [ ] SOPS installé
- [ ] Clé Age générée OU AWS KMS configuré
- [ ] `.sops.yaml` configuré
- [ ] `secrets.env` créé et chiffré
- [ ] Au moins un profil créé
- [ ] `docker-compose.yml` généré
- [ ] Services démarrés avec succès
- [ ] Traefik accessible sur http://localhost:8081/

Bonne utilisation ! 🚀
