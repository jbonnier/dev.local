#!/bin/bash
# Menu interactif pour Dev.Local 2.0
# Interface simple pour gérer services et profils

set -e

# Vérifier la présence de yq
if ! command -v yq &> /dev/null; then
    echo -e "\033[91mErreur: 'yq' n'est pas installé. Ce script nécessite yq pour parser les fichiers YAML.\033[0m"
    echo -e "Installez-le avec: sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && sudo chmod +x /usr/local/bin/yq"
    exit 1
fi

wait_key() {
    echo -e "\n\033[90m[Appuyez sur n'importe quelle touche pour continuer...]\033[0m"
    read -n 1 -s
}

show_menu() {
    clear
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║              🚀 DEV.LOCAL 2.0 - MENU PRINCIPAL                ║
║          Gestionnaire de Services Docker Modulaire            ║
╚═══════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────┐
│ 📦 SERVICES DOCKER                                          │
└─────────────────────────────────────────────────────────────┘
  1. ▶️ Démarrer tous les services
  m. 🚀 Démarrer services minimums (sans profils)
  2. 🎯 Démarrer avec profils spécifiques
  3. 🔄 Recréer les services (down + up)
  4. ⏹️ Arrêter tous les services
  5. 📋 Lister les containers actifs

┌─────────────────────────────────────────────────────────────┐
│ 🎭 GESTION DES PROFILS                                      │
└─────────────────────────────────────────────────────────────┘
  6. ➕ Ajouter un nouveau profil
  7. 📝 Lister les profils existants
  8. 🔧 Regénérer docker-compose.yml

┌─────────────────────────────────────────────────────────────┐
│ 🔐 GESTION DES SECRETS (SOPS)                               │
└─────────────────────────────────────────────────────────────┘
  9. ✏️ Éditer les secrets (sops secrets.env)
  10. 👁️ Voir les secrets déchiffrés
  11. 🆕 Initialiser secrets.env
  12. 🔄 Synchroniser secrets.env avec les profils

┌─────────────────────────────────────────────────────────────┐
│ ☁️  AWS & DOCKER                                            │
└─────────────────────────────────────────────────────────────┘
  13. 🔐 Connexion AWS SSO
  14. 🪪 Voir l'identité AWS
  15. 🐳 Connexion Docker ECR

┌─────────────────────────────────────────────────────────────┐
│ 📚 DOCUMENTATION                                            │
└─────────────────────────────────────────────────────────────┘
  16. 📖 Ouvrir README.md
  
  0. ❌ Quitter (ou 'q')

EOF
}

show_profiles() {
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║            📋 PROFILS DISPONIBLES                             ║
╚═══════════════════════════════════════════════════════════════╝

EOF
    
    if [ ! -d "profiles" ] || [ -z "$(ls -A profiles/*.yml 2>/dev/null)" ]; then
        echo -e "\033[93m  Aucun profil disponible\033[0m"
        echo "  Utilisez l'option 6 pour créer un profil"
        return
    fi
    
    # Init arrays
    names=()
    docker_profiles=()
    i=1
    
    for profile in profiles/*.yml; do
        [ -f "$profile" ] || continue
        
        # Use simpler yq extraction to avoid jq errors with undefined variables
        name=$(yq -r '.name' "$profile")
        if [ "$name" = "null" ] || [ -z "$name" ]; then 
            name=$(basename "$profile" .yml)
        fi
        
        enabled=$(yq -r '.enabled' "$profile")
        
        docker_profile=$(yq -r '.docker_profile' "$profile")
        if [ "$docker_profile" = "null" ] || [ -z "$docker_profile" ]; then 
            docker_profile="$name"
        fi
        
        if [ "$enabled" != "false" ]; then
            echo -e "  \033[96m[$i]\033[0m \033[92m✅ $name\033[0m"
            names[i]="$name"
            docker_profiles[i]="$docker_profile"
            ((i++))
        else
            echo -e "  \033[90m[-] ❌ $name (Désactivé)\033[0m"
        fi
    done
    
    echo -e "\nExemples:"
    echo "  1,2         (par numéros)"
    echo "  api,web     (par noms)"
    echo ""
    
    read -p "Entrez les profils (noms ou numéros, séparés par virgules): " input
    if [ -n "$input" ]; then
        selected_profiles=""
        IFS=',' read -ra ADDR <<< "$input"
        for val in "${ADDR[@]}"; do
            val=$(echo "$val" | tr -d '[:space:]')
            # Check if number
            if [[ "$val" =~ ^[0-9]+$ ]]; then
                if [ -n "${docker_profiles[$val]}" ]; then
                    if [ -z "$selected_profiles" ]; then
                        selected_profiles="${docker_profiles[$val]}"
                    else
                        selected_profiles="$selected_profiles,${docker_profiles[$val]}"
                    fi
                fi
            else
                if [ -z "$selected_profiles" ]; then
                    selected_profiles="$val"
                else
                    selected_profiles="$selected_profiles,$val"
                fi
            fi
        done
        
        if [ -n "$selected_profiles" ]; then
            echo -e "\033[96m▶️  Démarrage avec profils: $selected_profiles\033[0m"
            echo -e "\033[90mCommande: docker compose --profile $(echo $selected_profiles | sed 's/,/ --profile /g') up -d\033[0m"
            ./launch.sh --profile "$selected_profiles" up
            wait_key
        fi
    fi
}

# Boucle principale
while true; do
    show_menu
    read -p "Choisissez une option (0-16) ou 'q' pour quitter: " choice
    
    case $choice in
        1)
            echo -e "\033[96m▶️  Démarrage de tous les services...\033[0m"
            
            # Recueillir tous les profils actifs nécessaires
            profiles_list=""
            for profile in profiles/*.yml; do
                [ -f "$profile" ] || continue
                
                # Vérifier si activé (défaut: true)
                is_enabled=$(yq -r '.enabled' "$profile")
                if [ "$is_enabled" = "false" ]; then continue; fi
                
                # Vérifier si toujours actif (défaut: true)
                always_active=$(yq -r '.always_active' "$profile")
                
                if [ "$always_active" = "false" ]; then
                    p_name=$(yq -r '.docker_profile' "$profile")
                    
                    if [ -n "$p_name" ] && [ "$p_name" != "null" ]; then
                        if [ -z "$profiles_list" ]; then
                            profiles_list="$p_name"
                        else
                            profiles_list="$profiles_list,$p_name"
                        fi
                    fi
                fi
            done
            
            # Dédupliquer les profils
            if [ -n "$profiles_list" ]; then
                unique_profiles=$(echo "$profiles_list" | tr ',' '\n' | sort -u | tr '\n' ',' | sed 's/,$//')
                echo -e "\033[90mProfils inclus: $unique_profiles\033[0m"
                echo -e "\033[90mCommande: docker compose --profile $(echo $unique_profiles | sed 's/,/ --profile /g') up -d\033[0m"
                ./launch.sh --profile "$unique_profiles" up
            else
                echo -e "\033[90mCommande: docker compose up -d\033[0m"
                ./launch.sh up
            fi
            
            wait_key
            ;;
        m)
            echo -e "\033[96m▶️  Démarrage des services minimums (sans profils)...\033[0m"
            echo -e "\033[90mCommande: docker compose up -d\033[0m"
            ./launch.sh up
            wait_key
            ;;
        2)
            show_profiles
            ;;
        3)
            echo -e "\033[93m🔄 Recréation des services...\033[0m"
            echo -e "\033[90mCommande: docker compose down && docker compose up -d\033[0m"
            ./launch.sh down && ./launch.sh up
            wait_key
            ;;
        4)
            echo -e "\033[91m⏹️  Arrêt de tous les services...\033[0m"
            echo -e "\033[90mCommande: docker compose down\033[0m"
            ./launch.sh down
            wait_key
            ;;
        5)
            echo -e "\033[96m📋 Containers actifs:\033[0m"
            echo -e "\033[90mCommande: docker compose ps\033[0m"
            docker compose ps
            wait_key
            ;;
        6)
            echo -e "\033[96m➕ Ajout d'un nouveau profil...\033[0m"
            echo -e "\033[90mCommande: ./manage-profiles.sh add\033[0m"
            ./manage-profiles.sh add
            wait_key
            ;;
        7)
            echo -e "\033[96m📝 Liste des profils...\033[0m"
            echo -e "\033[90mCommande: ./manage-profiles.sh list\033[0m"
            ./manage-profiles.sh list
            wait_key
            ;;
        8)
            echo -e "\033[93m🔧 Regénération de docker-compose.yml...\033[0m"
            echo -e "\033[90mCommande: ./manage-profiles.sh generate\033[0m"
            ./manage-profiles.sh generate
            wait_key
            ;;
        9)
            echo -e "\033[96m✏️  Édition des secrets...\033[0m"
            echo -e "\033[90mCommande: ./launch.sh edit-secrets\033[0m"
            ./launch.sh edit-secrets
            wait_key
            ;;
        10)
            echo -e "\033[96m👁️  Affichage des secrets...\033[0m"
            echo -e "\033[90mCommande: ./launch.sh view-secrets\033[0m"
            ./launch.sh view-secrets
            wait_key
            ;;
        11)
            echo -e "\033[96m🆕 Initialisation de secrets.env...\033[0m"
            echo -e "\033[90mCommande: ./manage-profiles.sh init-secrets\033[0m"
            ./manage-profiles.sh init-secrets
            wait_key
            ;;
        12)
            echo -e "\033[96m🔄 Synchronisation de secrets.env...\033[0m"
            echo -e "\033[90mCommande: ./manage-profiles.sh sync-secrets\033[0m"
            ./manage-profiles.sh sync-secrets
            wait_key
            ;;
        13)
            echo -e "\033[96m🔐 Connexion AWS SSO...\033[0m"
            echo -e "\033[90mCommande: ./launch.sh sso\033[0m"
            ./launch.sh sso
            wait_key
            ;;
        14)
            echo -e "\033[96m🪪 Identité AWS actuelle:\033[0m"
            echo -e "\033[90mCommande: ./launch.sh id\033[0m"
            ./launch.sh id
            wait_key
            ;;
        15)
            echo -e "\033[96m🐳 Connexion Docker à AWS ECR...\033[0m"
            echo -e "\033[90mCommande: ./launch.sh ecr-login\033[0m"
            ./launch.sh ecr-login
            wait_key
            ;;
        16)
            echo -e "\033[96m📖 Ouverture de README.md...\033[0m"
            if command -v code &> /dev/null; then
                code README.md
            elif command -v nano &> /dev/null; then
                nano README.md
            else
                cat README.md | less
            fi
            ;;
        0|q|Q)
            echo -e "\033[92m👋 Au revoir!\033[0m"
            exit 0
            ;;
        *)
            echo -e "\033[91mOption invalide\033[0m"
            wait_key
            ;;
    esac
done
