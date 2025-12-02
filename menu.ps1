<#
.SYNOPSIS
    Menu interactif pour Dev.Local 2.0

.DESCRIPTION
    Interface simple pour gérer services et profils

.EXAMPLE
    .\menu.ps1
#>

$PSDefaultParameterValues['*:Encoding'] = 'UTF8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Wait-AnyKey {
    Write-Host "`n[Appuyez sur n'importe quelle touche pour continuer...]" -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-Menu {
    Clear-Host
    Write-Host @"
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

┌─────────────────────────────────────────────────────────────┐
│ ☁️  AWS & DOCKER                                            │
└─────────────────────────────────────────────────────────────┘
  12. 🔐 Connexion AWS SSO
  13. 🪪 Voir l'identité AWS
  14. 🐳 Connexion Docker ECR

┌─────────────────────────────────────────────────────────────┐
│ 📚 DOCUMENTATION                                            │
└─────────────────────────────────────────────────────────────┘
  15. 📖 Ouvrir README.md
  
  0. ❌ Quitter (ou 'q')

"@
}

function Show-Profiles {
    Write-Host @"
╔═══════════════════════════════════════════════════════════════╗
║            📋 PROFILS DISPONIBLES                             ║
╚═══════════════════════════════════════════════════════════════╝

"@
    
    $profiles = Get-ChildItem -Path "profiles" -Filter "*.yml" -ErrorAction SilentlyContinue
    
    if ($profiles.Count -eq 0) {
        Write-Host "  Aucun profil disponible" -ForegroundColor Yellow
        Write-Host "  Utilisez l'option 6 pour créer un profil`n"
        return
    }
    
    foreach ($profile in $profiles) {
        $content = Get-Content $profile.FullName -Raw
        $name = if ($content -match 'name:\s*(.+)') { $matches[1].Trim() } else { $profile.BaseName }
        $enabled = if ($content -match 'enabled:\s*(true|false)') { $matches[1] -eq 'true' } else { $true }
        $status = if ($enabled) { "✅" } else { "❌" }
        
        Write-Host "  $status $name" -ForegroundColor Cyan
    }
    
    Write-Host "`nExemples de profils multiples:"
    Write-Host "  api,frontend"
    Write-Host "  service1,service2,service3`n"
    
    $selectedProfiles = Read-Host "Entrez les profils (séparés par virgules)"
    if ($selectedProfiles) {
        Write-Host "▶️  Démarrage avec profils: $selectedProfiles" -ForegroundColor Cyan
        Write-Host "Commande: " -NoNewline -ForegroundColor DarkGray
        Write-Host ".\launch.ps1 -p $selectedProfiles" -ForegroundColor Yellow
        & .\launch.ps1 -p $selectedProfiles
    }
}

function Main {
    do {
        Show-Menu
        $choice = Read-Host "Choisissez une option (0-15) ou 'q' pour quitter"
        
        switch ($choice) {
            "1" {
                Write-Host "▶️  Démarrage de tous les services..." -ForegroundColor Cyan
                Write-Host "Commande: " -NoNewline -ForegroundColor DarkGray
                Write-Host ".\launch.ps1" -ForegroundColor Yellow
                & .\launch.ps1
                Wait-AnyKey
            }
            "2" {
                Show-Profiles
                Wait-AnyKey
            }
            "3" {
                Write-Host "🔄 Recréation des services..." -ForegroundColor Yellow
                Write-Host "Commande: " -NoNewline -ForegroundColor DarkGray
                Write-Host ".\launch.ps1 -c recreate" -ForegroundColor Yellow
                & .\launch.ps1 -c recreate
                Wait-AnyKey
            }
            "4" {
                Write-Host "⏹️  Arrêt de tous les services..." -ForegroundColor Red
                Write-Host "Commande: " -NoNewline -ForegroundColor DarkGray
                Write-Host ".\launch.ps1 -c stop" -ForegroundColor Yellow
                & .\launch.ps1 -c stop
                Wait-AnyKey
            }
            "5" {
                Write-Host "📋 Listing des containers actifs..." -ForegroundColor Cyan
                Write-Host "Commande: " -NoNewline -ForegroundColor DarkGray
                Write-Host ".\launch.ps1 -c ps" -ForegroundColor Yellow
                & .\launch.ps1 -c ps
                Wait-AnyKey
            }
            "6" {
                Write-Host "➕ Ajout d'un nouveau profil..." -ForegroundColor Cyan
                Write-Host "Commande: " -NoNewline -ForegroundColor DarkGray
                Write-Host ".\manage-profiles.ps1 -Action add" -ForegroundColor Yellow
                & .\manage-profiles.ps1 -Action add
                Wait-AnyKey
            }
            "7" {
                Write-Host "📝 Liste des profils..." -ForegroundColor Cyan
                Write-Host "Commande: " -NoNewline -ForegroundColor DarkGray
                Write-Host ".\manage-profiles.ps1 -Action list" -ForegroundColor Yellow
                & .\manage-profiles.ps1 -Action list
                Wait-AnyKey
            }
            "8" {
                Write-Host "🔧 Regénération de docker-compose.yml..." -ForegroundColor Yellow
                Write-Host "Commande: " -NoNewline -ForegroundColor DarkGray
                Write-Host ".\manage-profiles.ps1 -Action generate" -ForegroundColor Yellow
                & .\manage-profiles.ps1 -Action generate
                Wait-AnyKey
            }
            "9" {
                Write-Host "✏️  Édition des secrets..." -ForegroundColor Cyan
                Write-Host "Commande: " -NoNewline -ForegroundColor DarkGray
                Write-Host ".\launch.ps1 -c edit-secrets" -ForegroundColor Yellow
                & .\launch.ps1 -c edit-secrets
                Wait-AnyKey
            }
            "10" {
                Write-Host "👁️  Affichage des secrets..." -ForegroundColor Cyan
                Write-Host "Commande: " -NoNewline -ForegroundColor DarkGray
                Write-Host ".\launch.ps1 -c view-secrets" -ForegroundColor Yellow
                & .\launch.ps1 -c view-secrets
                Wait-AnyKey
            }
            "11" {
                Write-Host "🆕 Initialisation de secrets.env..." -ForegroundColor Cyan
                Write-Host "Commande: " -NoNewline -ForegroundColor DarkGray
                Write-Host ".\manage-profiles.ps1 -Action init-secrets" -ForegroundColor Yellow
                & .\manage-profiles.ps1 -Action init-secrets
                Wait-AnyKey
            }
            "12" {
                Write-Host "🔐 Connexion AWS SSO..." -ForegroundColor Cyan
                Write-Host "Commande: " -NoNewline -ForegroundColor DarkGray
                Write-Host ".\launch.ps1 -c sso" -ForegroundColor Yellow
                & .\launch.ps1 -c sso
                Wait-AnyKey
            }
            "13" {
                Write-Host "🪪 Identité AWS actuelle:" -ForegroundColor Cyan
                Write-Host "Commande: " -NoNewline -ForegroundColor DarkGray
                Write-Host ".\launch.ps1 -c id" -ForegroundColor Yellow
                & .\launch.ps1 -c id
                Wait-AnyKey
            }
            "14" {
                Write-Host "🐳 Connexion Docker à AWS ECR..." -ForegroundColor Cyan
                Write-Host "Commande: " -NoNewline -ForegroundColor DarkGray
                Write-Host ".\launch.ps1 -c ecr-login" -ForegroundColor Yellow
                & .\launch.ps1 -c ecr-login
                Wait-AnyKey
            }
            "15" {
                Write-Host "📖 Ouverture de README.md..." -ForegroundColor Cyan
                if (Test-Path README.md) {
                    if (Get-Command code -ErrorAction SilentlyContinue) {
                        & code README.md
                    } else {
                        & notepad README.md
                    }
                } else {
                    Write-Warning "README.md non trouvé"
                }
            }
            "0" {
                Write-Host "👋 Au revoir!" -ForegroundColor Green
                exit 0
            }
            "q" {
                Write-Host "👋 Au revoir!" -ForegroundColor Green
                exit 0
            }
            default {
                Write-Host "❌ Option invalide. Veuillez réessayer." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

# Vérifier que les fichiers nécessaires existent
if (-not (Test-Path .\launch.ps1)) {
    Write-Error "❌ launch.ps1 non trouvé"
    exit 1
}

if (-not (Test-Path .\manage-profiles.ps1)) {
    Write-Error "❌ manage-profiles.ps1 non trouvé"
    exit 1
}

# Lancer le menu
Main
