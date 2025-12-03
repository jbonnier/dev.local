#!/bin/bash
# Gestionnaire de profils pour Dev.Local 2.0
# Script pour ajouter, modifier, supprimer et lister des profils de services
# Génère automatiquement docker-compose.yml et la configuration Traefik

set -e

ACTION="${1:-list}"
PROFILES_DIR="profiles"
DOCKER_COMPOSE_FILE="docker-compose.yml"
TRAEFIK_DYNAMIC_FILE="traefik/dynamic.yml"
SECRETS_FILE="secrets.env"
CONFIG_FILE="config.yml"

# Configuration par défaut
DOZZLE_ENABLED=true
DOZZLE_PORT=9999

# Charger la configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        if grep -q "dozzle_enabled: false" "$CONFIG_FILE" 2>/dev/null; then
            DOZZLE_ENABLED=false
        fi
        # Extraire seulement le nombre du port (ignorer le commentaire #)
        local port=$(grep "dozzle_port:" "$CONFIG_FILE" 2>/dev/null | sed 's/.*dozzle_port: *//' | sed 's/ *#.*//' | tr -d '\r')
        if [ -n "$port" ]; then
            DOZZLE_PORT=$port
        fi
    fi
}

# Fonction pour charger les variables d'environnement partagées
get_shared_env_vars() {
    local service_name="$1"
    local shared_vars=""

    # Vérifier si le fichier config existe
    [ ! -f "$CONFIG_FILE" ] && echo "" && return

    # Vérifier si shared_env est activé
    local enabled=$(grep -A 10 "^shared_env_config:" "$CONFIG_FILE" | grep "enabled:" | sed 's/.*enabled: *//' | tr -d '\r' | head -1)
    [ "$enabled" = "false" ] && echo "" && return

    # Récupérer les groupes auto_inject
    local auto_inject_groups=""
    local in_auto_inject=false
    while IFS= read -r line; do
        if echo "$line" | grep -q "^  auto_inject:"; then
            in_auto_inject=true
            continue
        fi
        if [ "$in_auto_inject" = true ]; then
            if echo "$line" | grep -q "^    - "; then
                local group=$(echo "$line" | sed 's/.*- *//' | tr -d '\r')
                auto_inject_groups="${auto_inject_groups} ${group}"
            else
                break
            fi
        fi
    done < "$CONFIG_FILE"

    # Vérifier si le service est exclu
    if [ -n "$service_name" ]; then
        local in_exclude=false
        while IFS= read -r line; do
            if echo "$line" | grep -q "^  exclude_services:"; then
                in_exclude=true
                continue
            fi
            if [ "$in_exclude" = true ]; then
                if echo "$line" | grep -q "^    - "; then
                    local excluded_service=$(echo "$line" | sed 's/.*- *//' | tr -d '\r')
                    if [ "$excluded_service" = "$service_name" ]; then
                        echo ""
                        return
                    fi
                else
                    break
                fi
            fi
        done < "$CONFIG_FILE"
    fi

    # Récupérer les groupes service_specific pour ce service
    local service_groups=""
    if [ -n "$service_name" ]; then
        local in_service_specific=false
        local in_current_service=false
        while IFS= read -r line; do
            if echo "$line" | grep -q "^  service_specific:"; then
                in_service_specific=true
                continue
            fi
            if [ "$in_service_specific" = true ]; then
                if echo "$line" | grep -q "^    ${service_name}:"; then
                    in_current_service=true
                    continue
                fi
                if [ "$in_current_service" = true ]; then
                    if echo "$line" | grep -q "^      - "; then
                        local group=$(echo "$line" | sed 's/.*- *//' | tr -d '\r')
                        service_groups="${service_groups} ${group}"
                    else
                        in_current_service=false
                        [ $(echo "$line" | grep -c "^    [a-z]") -eq 0 ] && break
                    fi
                fi
            fi
        done < "$CONFIG_FILE"
    fi

    # Combiner tous les groupes
    local all_groups="${auto_inject_groups} ${service_groups}"

    # Extraire les variables de chaque groupe
    for group in $all_groups; do
        [ -z "$group" ] && continue

        local in_shared_env=false
        local in_group=false
        while IFS= read -r line; do
            if echo "$line" | grep -q "^shared_env:"; then
                in_shared_env=true
                continue
            fi
            if [ "$in_shared_env" = true ]; then
                if echo "$line" | grep -q "^  ${group}:"; then
                    in_group=true
                    continue
                fi
                if [ "$in_group" = true ]; then
                    if echo "$line" | grep -q "^    - "; then
                        local var=$(echo "$line" | sed 's/.*- *//' | tr -d '\r')
                        shared_vars="${shared_vars}${var}"$'\n'
                    else
                        in_group=false
                        [ $(echo "$line" | grep -c "^  [a-z]") -eq 0 ] && break
                    fi
                fi
            fi
        done < "$CONFIG_FILE"
    done

    echo "$shared_vars"
}

# Fonction pour lister les profils
show_profiles() {
    echo -e "\n\033[96m📋 PROFILS DISPONIBLES\033[0m"
    echo -e "\033[90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    
    if [ ! -d "$PROFILES_DIR" ] || [ -z "$(ls -A $PROFILES_DIR/*.yml 2>/dev/null)" ]; then
        echo -e "\033[93mAucun profil trouvé dans $PROFILES_DIR\033[0m"
        return
    fi
    
    for profile in $PROFILES_DIR/*.yml; do
        [ -f "$profile" ] || continue
        local basename=$(basename "$profile")
        local name=$(grep -m1 "^name:" "$profile" | sed 's/name: *//' | tr -d '\r' || echo "${basename%.yml}")
        local enabled=$(grep -m1 "^enabled:" "$profile" | sed 's/enabled: *//' | tr -d '\r' || echo "true")
        local description=$(grep -m1 '^description:' "$profile" | sed 's/description: *"//' | sed 's/"$//' | tr -d '\r' || echo "Sans description")
        
        if [ "$enabled" = "true" ]; then
            echo -e "  \033[97m$name\033[0m - \033[92m✅ Activé\033[0m"
        else
            echo -e "  \033[97m$name\033[0m - \033[91m❌ Désactivé\033[0m"
        fi
        echo -e "    \033[90m📝 $description\033[0m"
        echo -e "    \033[90m📁 $basename\033[0m"
        echo ""
    done
}

# Fonction pour ajouter un profil
add_profile() {
    echo -e "\n\033[96m➕ AJOUTER UN NOUVEAU PROFIL\033[0m"
    echo -e "\033[90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    
    # Collecter les informations
    read -p $'\nNom du service (ex: api-backend, frontend): ' name
    if [ -z "$name" ]; then
        echo -e "\033[91mLe nom est requis\033[0m"
        return 1
    fi
    
    # Nettoyer le nom
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
    filename="$PROFILES_DIR/$name.yml"
    
    if [ -f "$filename" ]; then
        echo -e "\033[91mUn profil '$name' existe déjà !\033[0m"
        return 1
    fi
    
    read -p "Description du service: " description
    read -p "Image Docker (ex: nginx:latest, registry.io/myapp:v1.0): " image
    read -p "Port du service (ex: 8000): " port
    read -p "Port hôte (Entrée pour utiliser le même): " host_port
    [ -z "$host_port" ] && host_port=$port
    
    echo -e "\n\033[93m🔑 Activation du service\033[0m"
    read -p "Service toujours actif (démarré par défaut) ? (O/n): " always_active_input
    always_active="true"
    docker_profile="null"
    if [ "$always_active_input" = "n" ]; then
        always_active="false"
        read -p "Nom du profil Docker (pour démarrage conditionnel, ex: $name): " docker_profile
        [ -z "$docker_profile" ] && docker_profile=$name
    fi
    
    echo -e "\n\033[93m🔧 Configuration Traefik\033[0m"
    read -p "Activer Traefik ? (o/N): " enable_traefik_input
    enable_traefik="false"
    traefik_prefix="/"
    strip_prefix="false"
    
    if [ "$enable_traefik_input" = "o" ]; then
        enable_traefik="true"
        read -p "Préfixe de route (ex: /api, /app): " traefik_prefix
        [ -z "$traefik_prefix" ] && traefik_prefix="/$name"
        read -p "Supprimer le préfixe avant transmission ? (O/n): " strip_prefix_input
        [ "$strip_prefix_input" != "n" ] && strip_prefix="true"
    fi
    
    echo -e "\n\033[93m🔐 Variables d'environnement\033[0m"
    echo "Entrez les variables (format: NOM=valeur), ligne vide pour terminer"
    env_vars=""
    while true; do
        read -p "Variable d'environnement: " env_var
        [ -z "$env_var" ] && break
        env_vars="${env_vars}    - ${env_var}"$'\n'
    done
    
    echo -e "\n\033[93m🔑 Secrets depuis secrets.env\033[0m"
    echo "Entrez les secrets (format: SECRET_NAME), ligne vide pour terminer"
    secrets=""
    secrets_doc=""
    while true; do
        read -p "Nom du secret: " secret
        [ -z "$secret" ] && break
        secret_var=$(echo "$secret" | tr '[:lower:]' '[:upper:]' | sed 's/[^A-Z0-9_]/_/g')
        read -p "  Description de $secret_var (optionnel): " secret_desc
        [ -z "$secret_desc" ] && secret_desc="Secret pour $name"
        
        secrets="${secrets}    - ${secret_var}=\${${secret_var}:-changeme}"$'\n'
        secrets_doc="${secrets_doc}  - name: ${secret_var}"$'\n'"    description: \"${secret_desc}\""$'\n'"    default: changeme"$'\n'
    done
    
    # Combiner env vars et secrets
    all_env="${env_vars}${secrets}"
    [ -z "$all_env" ] && all_env="    # Aucune variable d'environnement"
    
    # Section secrets si nécessaire
    secrets_section=""
    if [ -n "$secrets_doc" ]; then
        secrets_section=$'\n'"# Variables de secrets requises (à définir dans secrets.env)"$'\n'"secrets:"$'\n'"${secrets_doc}"
    fi
    
    # Générer le fichier YAML
    mkdir -p "$PROFILES_DIR"
    cat > "$filename" << EOF
# Profil généré automatiquement
name: $name
description: "$description"
enabled: true
always_active: $always_active
docker_profile: $docker_profile

docker-compose:
  image: $image
  container_name: $name
  ports:
    - "$host_port:$port"
  environment:
$all_env
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:$port/health"]
    interval: 30s
    timeout: 5s
    retries: 3
    start_period: 10s

traefik:
  enabled: $enable_traefik
  prefix: $traefik_prefix
  strip_prefix: $strip_prefix
  port: $port
  priority: 10
$secrets_section
metadata:
  category: custom
  tags:
    - $name
EOF
    
    echo -e "\n\033[92m✅ Profil créé : $filename\033[0m"
    echo -e "\033[90m📝 Vous pouvez éditer ce fichier pour personnaliser davantage\033[0m"
    
    # Proposer de regénérer docker-compose.yml
    read -p $'\nRegénérer docker-compose.yml maintenant ? (O/n): ' regen
    if [ "$regen" != "n" ]; then
        generate_docker_compose
    fi
}

# Fonction pour générer docker-compose.yml
generate_docker_compose() {
    echo -e "\n\033[96m🔧 GÉNÉRATION DE docker-compose.yml\033[0m"
    echo -e "\033[90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    
    if [ ! -d "$PROFILES_DIR" ] || [ -z "$(ls -A $PROFILES_DIR/*.yml 2>/dev/null)" ]; then
        echo -e "\033[93mAucun profil trouvé\033[0m"
        return 1
    fi
    
    load_config
    
    # Header avec timestamp
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    cat > "$DOCKER_COMPOSE_FILE" << EOF
# Généré automatiquement par manage-profiles.sh
# NE PAS ÉDITER MANUELLEMENT - Vos modifications seront écrasées
# Dernière génération : $timestamp

services:
  # Reverse Proxy Traefik
  traefik:
    image: traefik:v3.6.0
    container_name: traefik
    ports:
      - "8080:80"
      - "8081:8080"
    extra_hosts:
      - "external-ip:host-gateway"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/traefik.yml:/etc/traefik/traefik.yml:ro
      - ./traefik/dynamic.yml:/etc/traefik/dynamic.yml:ro
    networks:
      - traefik-network
    healthcheck:
      test: ["CMD-SHELL", "traefik healthcheck"]
      interval: 10s
      timeout: 5s
      retries: 3

EOF
    
    # Ajouter Dozzle si activé
    if [ "$DOZZLE_ENABLED" = "true" ]; then
        cat >> "$DOCKER_COMPOSE_FILE" << EOF
  # Monitoring des logs
  dozzle:
    image: amir20/dozzle:latest
    container_name: dozzle
    ports:
      - "$DOZZLE_PORT:8080"
    environment:
      - DOZZLE_TIMEOUT=15s
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    extra_hosts:
      - "external-ip:host-gateway"
    networks:
      - traefik-network
    healthcheck:
      test: ["CMD", "/dozzle", "healthcheck"]
      interval: 3s
      timeout: 30s

EOF
    fi
    
    # Ajouter chaque service
    for profile in $PROFILES_DIR/*.yml; do
        [ -f "$profile" ] || continue
        
        local enabled=$(grep -m1 "^enabled:" "$profile" | sed 's/enabled: *//' | tr -d '\r' || echo "true")
        if [ "$enabled" != "true" ]; then
            echo -e "  \033[90m⏭️  Ignoré (désactivé) : $(basename $profile .yml)\033[0m"
            continue
        fi
        
        local name=$(grep -m1 "^name:" "$profile" | sed 's/name: *//' | tr -d '\r' || basename "$profile" .yml)
        echo -e "  \033[92m✅ Ajout : $(basename $profile .yml)\033[0m"

        # Charger les variables partagées pour ce service
        local shared_env_vars=$(get_shared_env_vars "$name")
        local shared_count=0
        if [ -n "$shared_env_vars" ]; then
            shared_count=$(echo "$shared_env_vars" | grep -c "^" || echo 0)
            echo -e "    \033[90m📌 $shared_count variable(s) partagée(s)\033[0m"
        fi

        local always_active=$(grep -m1 "^always_active:" "$profile" | sed 's/always_active: *//' | sed 's/ *#.*//' | tr -d '\r' || echo "true")
        local docker_profile_raw=$(grep -m1 "^docker_profile:" "$profile" | sed 's/docker_profile: *//' | sed 's/ *#.*//' | tr -d '\r')
        # Considérer null, vide, ou whitespace comme absence de profil
        local docker_profile=$(echo "$docker_profile_raw" | xargs)  # trim whitespace
        if [ "$docker_profile" = "null" ] || [ -z "$docker_profile" ]; then
            docker_profile=""
        fi

        # Extraire la section docker-compose:
        local compose_section=$(sed -n '/^docker-compose:/,/^[a-z]/{//!p}' "$profile")
        
        # Traiter la section environment pour injecter les variables partagées
        local filtered_compose=""
        local in_ports=false
        local in_environment=false
        local environment_found=false
        local environment_indent="    "

        while IFS= read -r line; do
            # Gérer la section ports
            if echo "$line" | grep -q "^  ports:"; then
                in_ports=true
                continue
            fi
            if [ "$in_ports" = true ]; then
                if echo "$line" | grep -q "^    "; then
                    continue
                else
                    in_ports=false
                fi
            fi

            # Détecter la section environment
            if echo "$line" | grep -q "^  environment:"; then
                environment_found=true
                filtered_compose="${filtered_compose}${line}"$'\n'

                # Injecter les variables partagées juste après environment:
                if [ -n "$shared_env_vars" ]; then
                    filtered_compose="${filtered_compose}    # Variables partagées (depuis config.yml)"$'\n'
                    while IFS= read -r var; do
                        [ -n "$var" ] && filtered_compose="${filtered_compose}    - ${var}"$'\n'
                    done <<< "$shared_env_vars"
                fi
                in_environment=true
                continue
            fi

            filtered_compose="${filtered_compose}${line}"$'\n'
        done <<< "$compose_section"
        
        # Si pas de section environment, en créer une avec les variables partagées
        if [ "$environment_found" = false ] && [ -n "$shared_env_vars" ]; then
            local new_compose=""
            local added=false
            while IFS= read -r line; do
                new_compose="${new_compose}${line}"$'\n'
                # Ajouter environment après image/container_name
                if [ "$added" = false ] && echo "$line" | grep -q "^  container_name:"; then
                    new_compose="${new_compose}  environment:"$'\n'
                    new_compose="${new_compose}    # Variables partagées (depuis config.yml)"$'\n'
                    while IFS= read -r var; do
                        [ -n "$var" ] && new_compose="${new_compose}    - ${var}"$'\n'
                    done <<< "$shared_env_vars"
                    added=true
                fi
            done <<< "$filtered_compose"
            filtered_compose="$new_compose"
        fi

        # Ajouter 2 espaces d'indentation
        local indented=$(echo "$filtered_compose" | sed 's/^  /    /')
        
        # Nettoyer l'indentation (retirer les lignes vides en fin)
        indented=$(echo "$indented" | sed -e :a -e '/^\s*$/d;N;ba')

        # Section profiles si not always_active ET docker_profile n'est pas null/vide
        local profiles_section=""
        if [ "$always_active" != "true" ] && [ -n "$docker_profile" ] && [ "$docker_profile" != "null" ]; then
            profiles_section=$'\n'"    profiles:"$'\n'"      - $docker_profile"
        fi
        
        cat >> "$DOCKER_COMPOSE_FILE" << EOF
  # Service: $name
  $name:
$indented
    extra_hosts:
      - "external-ip:host-gateway"
    networks:
      - traefik-network$profiles_section

EOF
    done
    
    # Networks
    cat >> "$DOCKER_COMPOSE_FILE" << 'EOF'

networks:
  traefik-network:
    driver: bridge
EOF
    
    echo -e "\n\033[92m✅ docker-compose.yml généré\033[0m"
    
    # Générer aussi la config Traefik
    generate_traefik_dynamic
}

# Fonction pour générer traefik/dynamic.yml
generate_traefik_dynamic() {
    echo -e "\n\033[96m🔧 GÉNÉRATION DE traefik/dynamic.yml\033[0m"
    
    mkdir -p "traefik"
    
    cat > "$TRAEFIK_DYNAMIC_FILE" << 'EOF'
# Généré automatiquement par manage-profiles.sh
http:
  routers:
    traefik-dashboard:
      rule: "PathPrefix(`/traefik`)"
      service: api@internal
      priority: 1000

EOF
    
    load_config
    
    # Ajouter le router Dozzle si activé
    if [ "$DOZZLE_ENABLED" = "true" ]; then
        cat >> "$TRAEFIK_DYNAMIC_FILE" << 'EOF'
    dozzle:
      rule: "PathPrefix(`/logs`)"
      service: dozzle
      priority: 100

EOF
    fi
    
    # Générer les routers pour chaque profil
    for profile in $PROFILES_DIR/*.yml; do
        [ -f "$profile" ] || continue
        
        local enabled=$(grep -m1 "^enabled:" "$profile" | sed 's/enabled: *//' | tr -d '\r' || echo "true")
        local traefik_enabled=$(sed -n '/^traefik:/,/^[a-z]/{/enabled:/p}' "$profile" | sed 's/.*enabled: *//' | tr -d '\r')
        
        [ "$enabled" != "true" ] && continue
        [ "$traefik_enabled" != "true" ] && continue
        
        local name=$(grep -m1 "^name:" "$profile" | sed 's/name: *//' | tr -d '\r' || basename "$profile" .yml)
        local prefix=$(sed -n '/^traefik:/,/^[a-z]/{/prefix:/p}' "$profile" | sed 's/.*prefix: *//' | tr -d '\r' || echo "/$name")
        local port=$(sed -n '/^traefik:/,/^[a-z]/{/port:/p}' "$profile" | sed 's/.*port: *//' | tr -d '\r' || echo "80")
        local priority=$(sed -n '/^traefik:/,/^[a-z]/{/priority:/p}' "$profile" | sed 's/.*priority: *//' | tr -d '\r' || echo "10")
        local strip_prefix=$(sed -n '/^traefik:/,/^[a-z]/{/strip_prefix:/p}' "$profile" | sed 's/.*strip_prefix: *//' | tr -d '\r')
        
        local middlewares=""
        if [ "$strip_prefix" = "true" ]; then
            middlewares=$'\n'"      middlewares:"$'\n'"        - ${name}-strip-prefix"
        fi
        
        cat >> "$TRAEFIK_DYNAMIC_FILE" << EOF
    $name:
      rule: "PathPrefix(\`$prefix\`)"
      service: $name$middlewares
      priority: $priority

EOF
    done
    
    # Section services
    echo "  services:" >> "$TRAEFIK_DYNAMIC_FILE"
    
    # Ajouter le service Dozzle si activé
    if [ "$DOZZLE_ENABLED" = "true" ]; then
        cat >> "$TRAEFIK_DYNAMIC_FILE" << 'EOF'

    dozzle:
      loadBalancer:
        healthCheck:
          path: /healthcheck
          interval: 5s
          timeout: 1s
        servers:
          - url: "http://dozzle:8080"
        passHostHeader: true
EOF
    fi
    
    for profile in $PROFILES_DIR/*.yml; do
        [ -f "$profile" ] || continue
        
        local enabled=$(grep -m1 "^enabled:" "$profile" | sed 's/enabled: *//' | tr -d '\r' || echo "true")
        local traefik_enabled=$(sed -n '/^traefik:/,/^[a-z]/{/enabled:/p}' "$profile" | sed 's/.*enabled: *//' | tr -d '\r')
        
        [ "$enabled" != "true" ] && continue
        [ "$traefik_enabled" != "true" ] && continue
        
        local name=$(grep -m1 "^name:" "$profile" | sed 's/name: *//' | tr -d '\r' || basename "$profile" .yml)
        local port=$(sed -n '/^traefik:/,/^[a-z]/{/port:/p}' "$profile" | sed 's/.*port: *//' | tr -d '\r' || echo "80")
        local health_path=$(sed -n '/^traefik:/,/^[a-z]/{/health_path:/p}' "$profile" | sed 's/.*health_path: *//' | tr -d '\r' || echo "/health")
        local enable_failover=$(sed -n '/^traefik:/,/^[a-z]/{/failover:/p}' "$profile" | sed 's/.*failover: *//' | tr -d '\r')
        local host_port=$(sed -n '/^traefik:/,/^[a-z]/{/host_port:/p}' "$profile" | sed 's/.*host_port: *//' | tr -d '\r' || echo "$port")
        
        if [ "$enable_failover" = "true" ]; then
            # Service avec failover
            cat >> "$TRAEFIK_DYNAMIC_FILE" << EOF

    $name:
      failover:
        service: ${name}-host
        fallback: ${name}-docker
    ${name}-host:
      loadBalancer:
        healthCheck:
          path: $health_path
          interval: 5s
          timeout: 1s
        servers:
          - url: "http://external-ip:${host_port}"
        passHostHeader: true
    ${name}-docker:
      loadBalancer:
        healthCheck:
          path: $health_path
          interval: 5s
          timeout: 1s
        servers:
          - url: "http://${name}:${port}"
        passHostHeader: true
EOF
        else
            # Service simple
            cat >> "$TRAEFIK_DYNAMIC_FILE" << EOF

    $name:
      loadBalancer:
        healthCheck:
          path: $health_path
          interval: 5s
          timeout: 1s
        servers:
          - url: "http://${name}:${port}"
        passHostHeader: true
EOF
        fi
    done
    
    # Section middlewares
    echo -e "\n  middlewares:" >> "$TRAEFIK_DYNAMIC_FILE"
    
    for profile in $PROFILES_DIR/*.yml; do
        [ -f "$profile" ] || continue
        
        local enabled=$(grep -m1 "^enabled:" "$profile" | sed 's/enabled: *//' | tr -d '\r' || echo "true")
        local traefik_enabled=$(sed -n '/^traefik:/,/^[a-z]/{/enabled:/p}' "$profile" | sed 's/.*enabled: *//' | tr -d '\r')
        
        [ "$enabled" != "true" ] && continue
        [ "$traefik_enabled" != "true" ] && continue
        
        local name=$(grep -m1 "^name:" "$profile" | sed 's/name: *//' | tr -d '\r' || basename "$profile" .yml)
        local prefix=$(sed -n '/^traefik:/,/^[a-z]/{/prefix:/p}' "$profile" | sed 's/.*prefix: *//' | tr -d '\r' || echo "/$name")
        local strip_prefix=$(sed -n '/^traefik:/,/^[a-z]/{/strip_prefix:/p}' "$profile" | sed 's/.*strip_prefix: *//' | tr -d '\r')
        
        if [ "$strip_prefix" = "true" ]; then
            cat >> "$TRAEFIK_DYNAMIC_FILE" << EOF

    ${name}-strip-prefix:
      stripPrefix:
        prefixes:
          - "$prefix"
EOF
        fi
    done
    
    echo -e "\033[92m✅ traefik/dynamic.yml généré\033[0m"
}

# Fonction pour synchroniser secrets.env
sync_secrets() {
    echo -e "\n\033[96m🔄 SYNCHRONISATION DES SECRETS\033[0m"
    echo -e "\033[90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    
    # Vérifier SOPS
    if ! command -v sops &> /dev/null; then
        echo -e "\033[91mSOPS n'est pas installé. Cette fonctionnalité nécessite SOPS.\033[0m"
        echo -e "\n  \033[93m💡 Installez SOPS : https://github.com/mozilla/sops/releases\033[0m"
        return 1
    fi
    
    # Vérifier la configuration SOPS
    if [ ! -f ".sops.yaml" ]; then
        echo -e "\033[91mFichier .sops.yaml introuvable. Configurez SOPS d'abord.\033[0m"
        return 1
    fi
    
    if ! grep -qE '(kms:|age:)' ".sops.yaml"; then
        echo -e "\033[93mSOPS n'est pas configuré avec une clé KMS ou Age.\033[0m"
        echo -e "\n  \033[93m💡 Éditez .sops.yaml et configurez :\033[0m"
        echo -e "     \033[90m- AWS KMS : kms: 'arn:aws:kms:...'\033[0m"
        echo -e "     \033[90m- Age : age: 'age1...'\033[0m"
        echo -e "\n  \033[93mPour générer une clé Age :\033[0m"
        echo -e "     \033[90mage-keygen -o age-key.txt\033[0m"
        return 1
    fi
    
    # Récupérer toutes les variables des profils
    declare -A secret_vars
    
    for profile in $PROFILES_DIR/*.yml; do
        [ -f "$profile" ] || continue
        
        local enabled=$(grep -m1 "^enabled:" "$profile" | sed 's/enabled: *//' | tr -d '\r' || echo "true")
        [ "$enabled" != "true" ] && continue
        
        local profile_name=$(grep -m1 "^name:" "$profile" | sed 's/name: *//' | tr -d '\r' || basename "$profile" .yml)
        
        # Méthode 1 : Lire la section secrets:
        if grep -q "^secrets:" "$profile"; then
            local in_secrets=false
            while IFS= read -r line; do
                if echo "$line" | grep -q "^secrets:"; then
                    in_secrets=true
                    continue
                fi
                if [ "$in_secrets" = true ]; then
                    if echo "$line" | grep -q "^  - name:"; then
                        local secret_name=$(echo "$line" | sed 's/.*name: *//' | tr -d '\r')
                        local secret_desc=""
                        local secret_default="changeme"
                        
                        # Lire les lignes suivantes pour description et default
                        while IFS= read -r next_line; do
                            if echo "$next_line" | grep -q "^    description:"; then
                                secret_desc=$(echo "$next_line" | sed 's/.*description: *"//' | sed 's/"$//' | tr -d '\r')
                            elif echo "$next_line" | grep -q "^    default:"; then
                                secret_default=$(echo "$next_line" | sed 's/.*default: *//' | tr -d '\r')
                                break
                            elif echo "$next_line" | grep -qE "^(  -|[a-z])"; then
                                break
                            fi
                        done
                        
                        if [ -n "$secret_name" ] && [ -z "${secret_vars[$secret_name]}" ]; then
                            secret_vars["$secret_name"]="$secret_default"
                            echo -e "  \033[90m📌 [$profile_name] $secret_name = $secret_default ($secret_desc)\033[0m"
                        fi
                    elif echo "$line" | grep -qE "^[a-z]"; then
                        break
                    fi
                fi
            done < "$profile"
        fi
        
        # Méthode 2 (fallback) : Scanner les ${VAR:-default}
        while IFS= read -r match; do
            local var_name=$(echo "$match" | sed 's/.*\${\([A-Z_][A-Z0-9_]*\).*/\1/')
            local default_value=$(echo "$match" | sed 's/.*:-\([^}]*\)}.*/\1/')
            [ -z "$default_value" ] && default_value="changeme"
            
            if [ -n "$var_name" ] && [ -z "${secret_vars[$var_name]}" ]; then
                secret_vars["$var_name"]="$default_value"
                echo -e "  \033[90m📌 [$profile_name] $var_name = $default_value (auto-détecté)\033[0m"
            fi
        done < <(grep -o '\${[A-Z_][A-Z0-9_]*:-[^}]*}' "$profile" 2>/dev/null || true)
    done
    
    if [ ${#secret_vars[@]} -eq 0 ]; then
        echo -e "  \033[93mℹ️  Aucune variable de secrets trouvée dans les profils\033[0m"
        return 0
    fi
    
    echo -e "\n  \033[96mTotal: ${#secret_vars[@]} variable(s) trouvée(s)\033[0m"
    
    # Lire le fichier secrets.env existant
    declare -A existing_secrets
    local secrets_content=""
    
    if [ -f "$SECRETS_FILE" ]; then
        secrets_content=$(sops -d "$SECRETS_FILE" 2>&1)
        if [ $? -eq 0 ]; then
            while IFS='=' read -r key value; do
                if [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
                    existing_secrets["$key"]="$value"
                fi
            done <<< "$secrets_content"
            echo -e "\n  \033[92m✅ Fichier secrets.env déchiffré (${#existing_secrets[@]} variables existantes)\033[0m"
        else
            echo -e "\033[93mImpossible de déchiffrer secrets.env. Création d'un nouveau fichier.\033[0m"
        fi
    fi
    
    # Identifier les nouvelles variables
    declare -A new_vars
    for var in "${!secret_vars[@]}"; do
        if [ -z "${existing_secrets[$var]}" ]; then
            new_vars["$var"]="${secret_vars[$var]}"
        fi
    done
    
    if [ ${#new_vars[@]} -eq 0 ]; then
        echo -e "\n  \033[92m✅ Toutes les variables sont déjà présentes dans secrets.env\033[0m"
        return 0
    fi
    
    echo -e "\n  \033[93m📝 Variables manquantes à ajouter:\033[0m"
    for var in "${!new_vars[@]}"; do
        echo -e "     \033[90m- $var=${new_vars[$var]}\033[0m"
    done
    
    # Demander confirmation
    read -p $'\n  Ajouter ces variables à secrets.env ? (o/N): ' confirm
    if [ "$confirm" != "o" ]; then
        echo -e "  \033[93m⏭️  Annulé\033[0m"
        return 0
    fi
    
    # Construire le nouveau contenu
    local new_content="$secrets_content"
    [ -n "$new_content" ] && new_content="${new_content}"$'\n'
    new_content="${new_content}"$'\n'"# Variables ajoutées automatiquement le $(date '+%Y-%m-%d %H:%M:%S')"$'\n'
    for var in $(echo "${!new_vars[@]}" | tr ' ' '\n' | sort); do
        new_content="${new_content}${var}=${new_vars[$var]}"$'\n'
    done
    
    # Sauvegarder temporairement en clair
    local temp_file="${SECRETS_FILE}.tmp"
    echo -n "$new_content" > "$temp_file"
    
    # Chiffrer avec SOPS
    if sops -e "$temp_file" > "$SECRETS_FILE" 2>/dev/null; then
        rm -f "$temp_file"
        echo -e "\n  \033[92m✅ secrets.env mis à jour et rechiffré (${#new_vars[@]} variable(s) ajoutée(s))\033[0m"
    else
        echo -e "\033[91mErreur lors du chiffrement\033[0m"
        rm -f "$temp_file"
        return 1
    fi
}

# Fonction pour initialiser secrets.env
init_secrets() {
    echo -e "\n\033[96m🔐 INITIALISATION DES SECRETS\033[0m"
    echo -e "\033[90m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    
    if [ -f "$SECRETS_FILE" ]; then
        echo -e "\033[93mLe fichier $SECRETS_FILE existe déjà\033[0m"
        read -p "Écraser ? (o/N): " overwrite
        [ "$overwrite" != "o" ] && return 0
    fi
    
    # Vérifier SOPS
    if ! command -v sops &> /dev/null; then
        echo -e "\033[91mSOPS n'est pas installé. Installez-le d'abord.\033[0m"
        return 1
    fi
    
    # Copier l'exemple
    if [ -f "secrets.env.example" ]; then
        cp "secrets.env.example" "$SECRETS_FILE"
    else
        echo "# Secrets file - Edit with: sops secrets.env" > "$SECRETS_FILE"
    fi
    
    echo -e "\n\033[92m✅ Fichier $SECRETS_FILE créé\033[0m"
    echo -e "\033[93m📝 Éditez-le maintenant avec: sops $SECRETS_FILE\033[0m"
    
    read -p $'\nOuvrir l\'éditeur SOPS maintenant ? (O/n): ' open_editor
    if [ "$open_editor" != "n" ]; then
        sops "$SECRETS_FILE"
    fi
}

# Main
case "$ACTION" in
    add)
        add_profile
        ;;
    list)
        show_profiles
        ;;
    generate)
        generate_docker_compose
        ;;
    init-secrets)
        init_secrets
        ;;
    sync-secrets)
        sync_secrets
        ;;
    *)
        show_profiles
        ;;
esac
