#!/bin/bash
# Menu interactif pour Dev.Local 2.0
# Interface simple pour gérer services et profils

set -e

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
  1. ▶️  Démarrer tous les services
  2. 🎯 Démarrer avec profils spécifiques
  3. 🔄 Recréer les services (down + up)
  4. ⏹️  Arrêter tous les services
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
  9. ✏️  Éditer les secrets (sops secrets.env)
  10. 👁️  Voir les secrets déchiffrés
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
    
    for profile in profiles/*.yml; do
        [ -f "$profile" ] || continue
        name=$(grep -m1 '^name:' "$profile" | sed 's/name: *//' | tr -d '\r')
        enabled=$(grep -m1 '^enabled:' "$profile" | sed 's/enabled: *//' | tr -d '\r')
        
        if [ "$enabled" = "true" ]; then
            echo -e "  \033[92m✅ $name\033[0m"
        else
            echo -e "  \033[91m❌ $name\033[0m"
        fi
    done
    
    echo -e "\nExemples de profils multiples:"
    echo "  andoc,recpro"
    echo "  service1,service2,service3"
    echo ""
    
    read -p "Entrez les profils (séparés par virgules): " selected_profiles
    if [ -n "$selected_profiles" ]; then
        echo -e "\033[96m▶️  Démarrage avec profils: $selected_profiles\033[0m"
        echo -e "\033[90mCommande: docker compose --profile $(echo $selected_profiles | sed 's/,/ --profile /g') up -d\033[0m"
        ./launch.sh --profile "$selected_profiles" up
        wait_key
    fi
}

# Boucle principale
while true; do
    show_menu
    read -p "Choisissez une option (0-16) ou 'q' pour quitter: " choice
    
    case $choice in
        1)
            echo -e "\033[96m▶️  Démarrage de tous les services...\033[0m"
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
