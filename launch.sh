#!/bin/bash
# Script principal de gestion des services Dev.Local 2.0
# Gère le cycle de vie des services Docker avec support SOPS pour les secrets

set -e

COMMAND="${1:-start}"
PROFILES=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            PROFILES="$2"
            shift 2
            ;;
        up|start|stop|down|recreate|ps|sso|id|ecr-login|jfrog-login|edit-secrets|view-secrets)
            COMMAND="$1"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Valider Docker Compose
validate_docker_compose() {
    if ! command -v docker &> /dev/null; then
        echo -e "\033[91mDocker n'est pas installé\033[0m"
        exit 1
    fi
    
    if ! docker compose version &> /dev/null; then
        echo -e "\033[91mDocker Compose v2+ requis\033[0m"
        exit 1
    fi
}

# Valider SOPS
validate_sops() {
    if ! command -v sops &> /dev/null; then
        echo -e "\033[93mSOPS n'est pas installé - la gestion des secrets ne sera pas disponible\033[0m"
        return 1
    fi
    return 0
}

# Charger et déchiffrer les secrets
load_secrets() {
    if [ ! -f "secrets.env" ]; then
        echo -e "\033[93msecrets.env non trouvé - créez-le avec: ./manage-profiles.sh init-secrets\033[0m"
        return
    fi
    
    if ! validate_sops; then
        return
    fi
    
    echo -e "\033[96m🔐 Déchiffrement des secrets avec SOPS...\033[0m"
    
    local decrypted
    if decrypted=$(sops -d secrets.env 2>&1); then
        # Charger les variables dans l'environnement
        while IFS= read -r line; do
            # Ignorer les commentaires et lignes vides
            if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
                continue
            fi
            
            if [[ "$line" =~ ^[[:space:]]*([^=]+)=(.+)$ ]]; then
                local key="${BASH_REMATCH[1]}"
                local value="${BASH_REMATCH[2]}"
                export "$key=$value"
            fi
        done <<< "$decrypted"
        
        echo -e "\033[92m✅ Secrets chargés\033[0m"
    else
        echo -e "\033[91mÉchec du déchiffrement SOPS. Vérifiez votre configuration AWS/Age\033[0m"
        return 1
    fi
}

# Éditer les secrets
edit_secrets() {
    if ! validate_sops; then
        echo -e "\033[91mSOPS requis pour éditer les secrets\033[0m"
        return 1
    fi
    
    if [ ! -f "secrets.env" ]; then
        echo -e "\033[93mCréation de secrets.env...\033[0m"
        ./manage-profiles.sh init-secrets
        return
    fi
    
    echo -e "\033[96m📝 Ouverture de l'éditeur SOPS...\033[0m"
    sops secrets.env
}

# Voir les secrets déchiffrés
view_secrets() {
    if ! validate_sops; then
        echo -e "\033[91mSOPS requis\033[0m"
        return 1
    fi
    
    if [ ! -f "secrets.env" ]; then
        echo -e "\033[91msecrets.env non trouvé\033[0m"
        return 1
    fi
    
    echo -e "\033[96m🔍 Secrets déchiffrés:\033[0m"
    sops -d secrets.env
}

# Démarrer les services
start_services() {
    # Vérifier que docker-compose.yml existe
    if [ ! -f "docker-compose.yml" ]; then
        echo -e "\033[93mdocker-compose.yml non trouvé. Génération...\033[0m"
        ./manage-profiles.sh generate
    fi
    
    load_secrets
    
    if [ -n "$PROFILES" ]; then
        export COMPOSE_PROFILES="$PROFILES"
        echo -e "\033[96m🚀 Démarrage des profils: $PROFILES\033[0m"
        
        # Construire la commande avec --profile pour chaque profil
        local profile_args=""
        IFS=',' read -ra PROFILE_ARRAY <<< "$PROFILES"
        for profile in "${PROFILE_ARRAY[@]}"; do
            profile_args="$profile_args --profile $profile"
        done
        
        docker compose $profile_args up -d
    else
        unset COMPOSE_PROFILES
        echo -e "\033[96m🚀 Démarrage de tous les services\033[0m"
        docker compose up -d
    fi
}

# Arrêter les services
stop_services() {
    echo -e "\033[93m⏹️  Arrêt des services\033[0m"
    docker compose down
}

# Recréer les services
recreate_services() {
    echo -e "\033[93m🔄 Recréation des services\033[0m"
    docker compose down
    start_services
}

# Lister les containers
list_containers() {
    echo -e "\n\033[96m📋 CONTAINERS ACTIFS\033[0m"
    echo -e "\033[90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    docker compose ps
    echo ""
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# AWS SSO
connect_aws_sso() {
    if ! command -v aws &> /dev/null; then
        echo -e "\033[91mAWS CLI non installé\033[0m"
        return 1
    fi
    
    echo -e "\033[96m🔐 Connexion AWS SSO...\033[0m"
    aws sso login --profile ESG-DV-PowerUser-SSO
}

# AWS Identity
show_aws_identity() {
    if ! command -v aws &> /dev/null; then
        echo -e "\033[91mAWS CLI non installé\033[0m"
        return 1
    fi
    
    echo -e "\033[96m🪪 Identité AWS:\033[0m"
    aws sts get-caller-identity
}

# Docker ECR Login
connect_ecr_login() {
    if ! command -v aws &> /dev/null; then
        echo -e "\033[91mAWS CLI non installé\033[0m"
        return 1
    fi
    
    echo -e "\033[96m🐳 Connexion Docker à AWS ECR...\033[0m"
    aws ecr get-login-password --region ca-central-1 | docker login --username AWS --password-stdin 237029655182.dkr.ecr.ca-central-1.amazonaws.com
}

# Main
validate_docker_compose

case "$COMMAND" in
    start|up)
        start_services
        ;;
    stop|down)
        stop_services
        ;;
    recreate)
        recreate_services
        ;;
    ps)
        list_containers
        ;;
    sso)
        connect_aws_sso
        ;;
    id)
        show_aws_identity
        ;;
    ecr-login)
        connect_ecr_login
        ;;
    edit-secrets)
        edit_secrets
        ;;
    view-secrets)
        view_secrets
        ;;
    *)
        echo -e "\033[91mCommande inconnue: $COMMAND\033[0m"
        echo "Usage: $0 [start|stop|recreate|ps|sso|id|ecr-login|edit-secrets|view-secrets]"
        echo "       $0 --profile <profils> start"
        exit 1
        ;;
esac
