# Dev.Local 2.0 - Justfile
# Command runner simple - délègue aux scripts PS1/SH

set windows-shell := ["pwsh.exe", "-NoLogo", "-Command"]

@default:
    just --list

# Services Docker
[windows]
start:
    .\launch.ps1 start

[unix]
start:
    ./launch.sh start

# Démarrer avec des profils spécifiques
[windows]
start-profile profiles:
    .\launch.ps1 -p {{profiles}} start

[unix]
start-profile profiles:
    ./launch.sh --profile {{profiles}} start

# Arrêter tous les services
[windows]
stop:
    .\launch.ps1 stop

[unix]
stop:
    ./launch.sh stop

# Redémarrer les services
[windows]
restart:
    .\launch.ps1 recreate

[unix]
restart:
    ./launch.sh recreate

# Lister les containers actifs
[windows]
ps:
    .\launch.ps1 ps

[unix]
ps:
    ./launch.sh ps

# Voir les logs d'un service
[windows]
logs service="":
    .\launch.ps1 logs -service {{service}}

[unix]
logs service="":
    ./launch.sh logs {{service}}

# Profils
[windows]
profiles:
    .\manage-profiles.ps1 list

[unix]
profiles:
    ./manage-profiles.sh list

# Regénérer docker-compose.yml et traefik
[windows]
generate:
    .\manage-profiles.ps1 generate

[unix]
generate:
    ./manage-profiles.sh generate

# Valider la configuration Docker Compose
validate:
    @docker compose config --quiet && echo "OK" || echo "ERREUR"

# Secrets
# Éditer les secrets SOPS
[windows]
secrets-edit:
    .\launch.ps1 -c edit-secrets

[unix]
secrets-edit:
    ./launch.sh edit-secrets

# Voir les secrets déchiffrés
[windows]
secrets-view:
    .\launch.ps1 -c view-secrets

[unix]
secrets-view:
    ./launch.sh view-secrets

# AWS
# Connexion AWS SSO
[windows]
aws-sso:
    .\launch.ps1 -c sso

[unix]
aws-sso:
    ./launch.sh sso

# Afficher l'identité AWS
[windows]
aws-id:
    .\launch.ps1 -c id

[unix]
aws-id:
    ./launch.sh id

# Connexion Docker à AWS ECR
[windows]
ecr-login:
    .\launch.ps1 -c ecr-login

[unix]
ecr-login:
    ./launch.sh ecr-login

# Connexion Docker à JFrog
[windows]
jfrog-login:
    .\launch.ps1 -c jfrog-login

[unix]
jfrog-login:
    ./launch.sh jfrog-login

# Utilitaires
# Nettoyer containers et volumes
clean:
    docker compose down -v

# Lancer le menu interactif
[windows]
menu:
    .\menu.ps1

[unix]
menu:
    ./menu.sh

# Afficher la configuration Docker Compose
config:
    docker compose config

# Aliases
alias up := start
alias down := stop
alias s := start
alias st := stop
alias r := restart
alias p := ps
alias g := generate
alias v := validate
