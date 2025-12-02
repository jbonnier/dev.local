<#
.SYNOPSIS
    Script principal de gestion des services Dev.Local 2.0

.DESCRIPTION
    Gère le cycle de vie des services Docker avec support SOPS pour les secrets.

.PARAMETER p
    Profils à démarrer (séparés par virgules)

.PARAMETER c
    Commande : start, stop, recreate, ps, sso, id, ecr-login, jfrog-login, edit-secrets

.EXAMPLE
    .\launch.ps1
    Démarre tous les services

.EXAMPLE
    .\launch.ps1 -p api,frontend
    Démarre uniquement les services api et frontend

.EXAMPLE
    .\launch.ps1 -c edit-secrets
    Édite les secrets avec SOPS
#>

param(
    [string]$p,
    [Parameter(Position = 0)]
    [ValidateSet('start', 'stop', 'recreate', 'ps', 'logs', 'sso', 'id', 'ecr-login', 'jfrog-login', 'edit-secrets', 'view-secrets')]
    [string]$c='start',
    [string]$service
)

$PSDefaultParameterValues['*:Encoding'] = 'UTF8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Valider Docker Compose
function Validate-DockerCompose {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker n'est pas installé"
        exit 1
    }
    
    $ver = docker compose version 2>$null
    if (-not $ver) {
        Write-Error "Docker Compose v2+ requis"
        exit 1
    }
}

# Valider SOPS
function Validate-Sops {
    if (-not (Get-Command sops -ErrorAction SilentlyContinue)) {
        Write-Warning "SOPS n'est pas installé - la gestion des secrets ne sera pas disponible"
        return $false
    }
    return $true
}

# Charger et déchiffrer les secrets
function Load-Secrets {
    if (-not (Test-Path "secrets.env")) {
        Write-Warning "secrets.env non trouvé - créez-le avec: .\manage-profiles.ps1 -Action init-secrets"
        return
    }
    
    if (-not (Validate-Sops)) {
        return
    }
    
    Write-Host "🔐 Déchiffrement des secrets avec SOPS..." -ForegroundColor Cyan
    
    try {
        $decrypted = & sops -d secrets.env 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Échec du déchiffrement SOPS. Vérifiez votre configuration AWS/Age"
            return
        }
        
        # Charger les variables
        $decrypted -split "`n" | ForEach-Object {
            if ($_ -match '^\s*([^#][^=]+)=(.+)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                [Environment]::SetEnvironmentVariable($key, $value, "Process")
            }
        }
        
        Write-Host "✅ Secrets chargés" -ForegroundColor Green
    }
    catch {
        Write-Error "Erreur lors du déchiffrement : $_"
    }
}

# Éditer les secrets
function Edit-Secrets {
    if (-not (Validate-Sops)) {
        Write-Error "SOPS requis pour éditer les secrets"
        return
    }
    
    if (-not (Test-Path "secrets.env")) {
        Write-Host "Création de secrets.env..." -ForegroundColor Yellow
        & .\manage-profiles.ps1 -Action init-secrets
        return
    }
    
    Write-Host "📝 Ouverture de l'éditeur SOPS..." -ForegroundColor Cyan
    & sops secrets.env
}

# Voir les secrets déchiffrés
function View-Secrets {
    if (-not (Validate-Sops)) {
        Write-Error "SOPS requis"
        return
    }
    
    if (-not (Test-Path "secrets.env")) {
        Write-Error "secrets.env non trouvé"
        return
    }
    
    Write-Host "🔍 Secrets déchiffrés:" -ForegroundColor Cyan
    & sops -d secrets.env
}

# Démarrer les services
function Start-Services {
    param([string]$profiles)
    
    # Vérifier que docker-compose.yml existe
    if (-not (Test-Path "docker-compose.yml")) {
        Write-Warning "docker-compose.yml non trouvé. Génération..."
        & .\manage-profiles.ps1 -Action generate
    }
    
    Load-Secrets
    
    if ($profiles) {
        $env:COMPOSE_PROFILES = $profiles
        Write-Host "🚀 Démarrage des profils: $profiles" -ForegroundColor Cyan
    } else {
        if (Test-Path env:COMPOSE_PROFILES) {
            Remove-Item env:COMPOSE_PROFILES
        }
        Write-Host "🚀 Démarrage de tous les services" -ForegroundColor Cyan
    }
    
    docker compose up -d
}

# Arrêter les services
function Stop-Services {
    Write-Host "⏹️  Arrêt des services" -ForegroundColor Yellow
    docker compose down
}

# Recréer les services
function Recreate-Services {
    Write-Host "🔄 Recréation des services" -ForegroundColor Yellow
    docker compose down
    Start-Services
}

# Lister les containers
function List-Containers {
    Write-Host "`n📋 CONTAINERS ACTIFS" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    docker compose ps
    Write-Host "`n"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Afficher les logs
function Show-Logs {
    param([string]$service)
    
    if ($service) {
        Write-Host "📋 Logs du service: $service" -ForegroundColor Cyan
        docker compose logs -f $service
    } else {
        Write-Host "📋 Logs de tous les services" -ForegroundColor Cyan
        docker compose logs -f
    }
}

# AWS SSO
function Connect-AwsSso {
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Error "AWS CLI non installé"
        return
    }
    
    Write-Host "🔐 Connexion AWS SSO..." -ForegroundColor Cyan
    aws sso login --profile ESG-DV-PowerUser-SSO
}

# AWS Identity
function Show-AwsIdentity {
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Error "AWS CLI non installé"
        return
    }
    
    Write-Host "🪪 Identité AWS:" -ForegroundColor Cyan
    aws sts get-caller-identity
}

# Docker ECR Login
function Connect-EcrLogin {
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Error "AWS CLI non installé"
        return
    }
    
    Write-Host "🐳 Connexion Docker à AWS ECR..." -ForegroundColor Cyan
    aws ecr get-login-password --region ca-central-1 | docker login --username AWS --password-stdin 237029655182.dkr.ecr.ca-central-1.amazonaws.com
}

# Main
Validate-DockerCompose

switch ($c) {
    'start' { Start-Services -profiles $p }
    'stop' { Stop-Services }
    'recreate' { Recreate-Services }
    'ps' { List-Containers }
    'logs' { Show-Logs -service $service }
    'sso' { Connect-AwsSso }
    'id' { Show-AwsIdentity }
    'ecr-login' { Connect-EcrLogin }
    'edit-secrets' { Edit-Secrets }
    'view-secrets' { View-Secrets }
    default { Write-Error "Commande inconnue: $c" }
}
