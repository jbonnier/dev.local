# Scripts Bash pour Dev.Local 2.0

## ✅ Scripts Créés

Versions bash complètes des 3 scripts PowerShell :

1. **menu.sh** - Menu interactif TUI (256 lignes équivalent)
2. **manage-profiles.sh** - Gestion des profils et génération (770 lignes équivalent)  
3. **launch.sh** - Orchestration des services Docker

## 🚀 Utilisation sous Linux/macOS

### Prérequis

```bash
# Docker & Docker Compose v2+
docker --version
docker compose version

# SOPS (pour les secrets)
brew install sops  # macOS
# ou télécharger depuis https://github.com/mozilla/sops/releases

# AWS CLI (optionnel, pour ECR)
brew install awscli
```

### Rendre les scripts exécutables

```bash
chmod +x menu.sh manage-profiles.sh launch.sh
```

### Menu principal

```bash
./menu.sh
```

### Gestion des profils

```bash
# Lister les profils
./manage-profiles.sh list

# Ajouter un nouveau profil
./manage-profiles.sh add

# Regénérer docker-compose.yml
./manage-profiles.sh generate

# Regénérer docker-compose.yml
./manage-profiles.sh generate

# Synchroniser les secrets
./manage-profiles.sh sync-secrets
```

### Variables d'environnement partagées

Les scripts bash supportent également les variables d'environnement partagées via `config.yml` :

```bash
# Éditer la configuration
nano config.yml

# Ajouter vos variables partagées
# shared_env:
#   global:
#     - API_URL=https://api.example.com
#     - LOG_LEVEL=info

# Regénérer avec les variables partagées
./manage-profiles.sh generate
```

Le script affichera automatiquement le nombre de variables partagées injectées dans chaque service :

```
✅ Ajout : mon-service
   📌 6 variable(s) partagée(s)
```

📚 **Documentation complète :** [docs/shared-env-guide.md](docs/shared-env-guide.md)

### Orchestration des services

```bash
# Démarrer tous les services
./launch.sh start
# ou simplement
./launch.sh

# Démarrer avec des profils spécifiques
./launch.sh --profile andoc,recpro start

# Arrêter tous les services
./launch.sh stop

# Recréer les services
./launch.sh recreate

# Lister les containers
./launch.sh ps

# Éditer les secrets
./launch.sh edit-secrets

# Voir les secrets déchiffrés
./launch.sh view-secrets

# AWS SSO
./launch.sh sso

# Identité AWS
./launch.sh id

# Connexion Docker ECR
./launch.sh ecr-login
```

## 🔄 Équivalences PowerShell ↔ Bash

| PowerShell | Bash |
|------------|------|
| `.\menu.ps1` | `./menu.sh` |
| `.\manage-profiles.ps1 -Action add` | `./manage-profiles.sh add` |
| `.\launch.ps1 -p andoc,recpro` | `./launch.sh --profile andoc,recpro start` |
| `.\launch.ps1 -c edit-secrets` | `./launch.sh edit-secrets` |

## 📝 Différences avec PowerShell

### Fonctionnalités identiques
- ✅ Menu interactif complet (16 options)
- ✅ Création de profils avec prompts
- ✅ Génération docker-compose.yml et traefik/dynamic.yml
- ✅ Filtrage des ports
- ✅ Support docker profiles (always_active/docker_profile)
- ✅ Synchronisation des secrets avec section `secrets:`
- ✅ Intégration SOPS complète
- ✅ Support Traefik failover
- ✅ Configuration Dozzle

### Adaptations techniques
- **Couleurs** : ANSI escape codes au lieu de `Write-Host -ForegroundColor`
- **Pause** : `read -n 1 -s` au lieu de `$Host.UI.RawUI.ReadKey()`
- **Arrays associatifs** : `declare -A` au lieu de `@{}`
- **Regex** : `sed`/`grep` au lieu de `-match`
- **YAML parsing** : Combinaison `grep`/`sed` au lieu de regex PowerShell

## 🐧 Compatibilité

- ✅ Linux (Ubuntu, Debian, RHEL, etc.)
- ✅ macOS (Intel & Apple Silicon)
- ✅ WSL2 (Windows Subsystem for Linux)
- ✅ Git Bash (Windows, avec limitations)

## 🔐 Configuration SOPS

Identique pour PowerShell et Bash - éditez `.sops.yaml` :

```yaml
creation_rules:
  - kms: 'arn:aws:kms:ca-central-1:123456789012:key/your-key-id'
    # ou
  - age: 'age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
```

## 🎨 Caractères spéciaux

Les scripts bash utilisent les mêmes caractères UTF-8 que PowerShell :
- ╔═╗║└┘┌┐│ (box drawing)
- ✅❌🚀📋🔧 (emojis)

Assurez-vous que votre terminal supporte UTF-8 :

```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

## 📦 Structure des fichiers

Les scripts bash créent exactement les mêmes fichiers que PowerShell :
- `docker-compose.yml`
- `traefik/dynamic.yml`
- `profiles/*.yml`
- `secrets.env` (chiffré avec SOPS)
- `config.yml`

## 🐛 Dépannage

### "command not found: ./menu.sh"

```bash
chmod +x *.sh
```

### "SOPS n'est pas installé"

```bash
# macOS
brew install sops

# Linux
wget https://github.com/mozilla/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64
sudo mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops
chmod +x /usr/local/bin/sops
```

### Erreurs d'encodage UTF-8

```bash
export LANG=en_US.UTF-8
./menu.sh
```

### "Docker Compose v2+ requis"

```bash
# Vérifier la version
docker compose version

# Si vous avez docker-compose v1, installez v2
# https://docs.docker.com/compose/install/
```

## 🔄 Migration Windows → Linux

1. Copiez tout le dossier `Dev.Local.2.0`
2. Rendez les scripts bash exécutables : `chmod +x *.sh`
3. Vérifiez SOPS : `sops --version`
4. Lancez le menu : `./menu.sh`

Les profils et secrets sont 100% compatibles entre les deux plateformes.

## 📚 Ressources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [SOPS GitHub](https://github.com/mozilla/sops)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Age Encryption](https://github.com/FiloSottile/age)
