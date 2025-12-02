<#
.SYNOPSIS
    Gestionnaire de profils pour Dev.Local 2.0

.DESCRIPTION
    Script pour ajouter, modifier, supprimer et lister des profils de services.
    Génère automatiquement docker-compose.yml et la configuration Traefik.

.PARAMETER Action
    Action à effectuer : add, list, remove, generate, init-secrets

.EXAMPLE
    .\manage-profiles.ps1 -Action add
    Ajouter un nouveau profil de service

.EXAMPLE
    .\manage-profiles.ps1 -Action list
    Lister tous les profils

.EXAMPLE
    .\manage-profiles.ps1 -Action generate
    Regénérer docker-compose.yml et traefik/dynamic.yml
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('add', 'list', 'remove', 'enable', 'disable', 'generate', 'init-secrets')]
    [string]$Action = 'list'
)

$PSDefaultParameterValues['*:Encoding'] = 'UTF8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Chemins
$ProfilesDir = "profiles"
$DockerComposeFile = "docker-compose.yml"
$TraefikDynamicFile = "traefik/dynamic.yml"
$SecretsFile = "secrets.env"

# Fonction pour charger un profil YAML
function Read-ProfileYaml {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Error "Profil non trouvé : $Path"
        return $null
    }
    
    $content = Get-Content $Path -Raw
    # Conversion YAML simple (limité, pour une vraie app utiliser powershell-yaml)
    # Pour l'instant on retourne le contenu brut
    return $content
}

# Fonction pour lister les profils
function Show-Profiles {
    Write-Host "`n📋 PROFILS DISPONIBLES" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    $profiles = Get-ChildItem -Path $ProfilesDir -Filter "*.yml" -ErrorAction SilentlyContinue
    
    if ($profiles.Count -eq 0) {
        Write-Host "Aucun profil trouvé dans $ProfilesDir" -ForegroundColor Yellow
        return
    }
    
    foreach ($profile in $profiles) {
        $content = Get-Content $profile.FullName -Raw
        $name = if ($content -match 'name:\s*(.+)') { $matches[1].Trim() } else { $profile.BaseName }
        $enabled = if ($content -match 'enabled:\s*(true|false)') { $matches[1] -eq 'true' } else { $true }
        $description = if ($content -match 'description:\s*"(.+)"') { $matches[1] } else { "Sans description" }
        
        $status = if ($enabled) { "✅ Activé" } else { "❌ Désactivé" }
        $statusColor = if ($enabled) { "Green" } else { "Red" }
        
        Write-Host "  $name" -ForegroundColor White -NoNewline
        Write-Host " - $status" -ForegroundColor $statusColor
        Write-Host "    📝 $description" -ForegroundColor DarkGray
        Write-Host "    📁 $($profile.Name)" -ForegroundColor DarkGray
        Write-Host ""
    }
}

# Fonction pour ajouter un profil
function Add-Profile {
    Write-Host "`n➕ AJOUTER UN NOUVEAU PROFIL" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    # Collecter les informations
    $name = Read-Host "`nNom du service (ex: api-backend, frontend)"
    if ([string]::IsNullOrWhiteSpace($name)) {
        Write-Error "Le nom est requis"
        return
    }
    
    # Nettoyer le nom
    $name = $name.ToLower() -replace '[^a-z0-9-]', '-'
    $fileName = "$ProfilesDir\$name.yml"
    
    if (Test-Path $fileName) {
        Write-Error "Un profil '$name' existe déjà !"
        return
    }
    
    $description = Read-Host "Description du service"
    $image = Read-Host "Image Docker (ex: nginx:latest, registry.io/myapp:v1.0)"
    $port = Read-Host "Port du service (ex: 8000)"
    $hostPort = Read-Host "Port hôte (appuyez sur Entrée pour utiliser le même port)"
    if ([string]::IsNullOrWhiteSpace($hostPort)) { $hostPort = $port }
    
    Write-Host "`n🔧 Configuration Traefik" -ForegroundColor Yellow
    $enableTraefik = (Read-Host "Activer Traefik ? (o/N)") -eq 'o'
    $traefikPrefix = "/"
    $stripPrefix = $false
    
    if ($enableTraefik) {
        $traefikPrefix = Read-Host "Préfixe de route (ex: /api, /app)"
        if ([string]::IsNullOrWhiteSpace($traefikPrefix)) { $traefikPrefix = "/$name" }
        $stripPrefix = (Read-Host "Supprimer le préfixe avant transmission ? (O/n)") -ne 'n'
    }
    
    Write-Host "`n🔐 Variables d'environnement" -ForegroundColor Yellow
    Write-Host "Entrez les variables (format: NOM=valeur), ligne vide pour terminer"
    $envVars = @()
    while ($true) {
        $env = Read-Host "Variable d'environnement"
        if ([string]::IsNullOrWhiteSpace($env)) { break }
        $envVars += "    - $env"
    }
    
    Write-Host "`n🔑 Secrets depuis secrets.env" -ForegroundColor Yellow
    Write-Host "Entrez les secrets (format: SECRET_NAME), ligne vide pour terminer"
    $secrets = @()
    while ($true) {
        $secret = Read-Host "Nom du secret"
        if ([string]::IsNullOrWhiteSpace($secret)) { break }
        $secretVar = $secret.ToUpper() -replace '[^A-Z0-9_]', '_'
        $secrets += "    - ${secretVar}=`${${secretVar}:-changeme}"
    }
    
    # Générer le fichier YAML
    $allEnv = ($envVars + $secrets) -join "`n"
    if ([string]::IsNullOrWhiteSpace($allEnv)) {
        $allEnv = "    # Aucune variable d'environnement"
    }
    
    $profileContent = @"
# Profil généré automatiquement
name: $name
description: "$description"
enabled: true

service:
  image: ${image}
  container_name: $name
  ports:
    - "${hostPort}:${port}"
  environment:
$allEnv
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:${port}/health"]
    interval: 30s
    timeout: 5s
    retries: 3
    start_period: 10s

traefik:
  enabled: $($enableTraefik.ToString().ToLower())
  prefix: $traefikPrefix
  strip_prefix: $($stripPrefix.ToString().ToLower())
  port: $port
  priority: 10

metadata:
  category: custom
  tags:
    - $name
"@
    
    $profileContent | Out-File -FilePath $fileName -Encoding UTF8
    
    Write-Host "`n✅ Profil créé : $fileName" -ForegroundColor Green
    Write-Host "📝 Vous pouvez éditer ce fichier pour personnaliser davantage" -ForegroundColor Gray
    
    # Proposer de regénérer docker-compose.yml
    if ((Read-Host "`nRegénérer docker-compose.yml maintenant ? (O/n)") -ne 'n') {
        Generate-DockerCompose
    }
}

# Fonction pour générer docker-compose.yml
function Generate-DockerCompose {
    Write-Host "`n🔧 GÉNÉRATION DE docker-compose.yml" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    $profiles = Get-ChildItem -Path $ProfilesDir -Filter "*.yml" -ErrorAction SilentlyContinue
    
    if ($profiles.Count -eq 0) {
        Write-Warning "Aucun profil trouvé"
        return
    }
    
    # Header
    $compose = @"
# Généré automatiquement par manage-profiles.ps1
# NE PAS ÉDITER MANUELLEMENT - Vos modifications seront écrasées

services:
  # Reverse Proxy Traefik
  traefik:
    image: traefik:v3.6.0
    container_name: traefik
    ports:
      - "8080:80"
      - "8081:8080"
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

"@
    
    # Ajouter chaque service
    foreach ($profile in $profiles) {
        $content = Get-Content $profile.FullName -Raw
        $enabled = if ($content -match 'enabled:\s*(true|false)') { $matches[1] -eq 'true' } else { $true }
        
        if (-not $enabled) {
            Write-Host "  ⏭️  Ignoré (désactivé) : $($profile.BaseName)" -ForegroundColor DarkGray
            continue
        }
        
        Write-Host "  ✅ Ajout : $($profile.BaseName)" -ForegroundColor Green
        
        # Parser le YAML simplement (version basique)
        $name = if ($content -match 'name:\s*(.+)') { $matches[1].Trim() } else { $profile.BaseName }
        $image = if ($content -match 'image:\s*(.+)') { $matches[1].Trim() } else { 'nginx:latest' }
        $containerName = if ($content -match 'container_name:\s*(.+)') { $matches[1].Trim() } else { $name }
        
        # Extraire ports
        $portsSection = ""
        if ($content -match 'ports:\s*\n((?:\s+-\s*.+\n)+)') {
            $portsSection = "  ports:`n" + $matches[1]
        }
        
        # Extraire environment
        $envSection = ""
        if ($content -match 'environment:\s*\n((?:\s+-\s*.+\n)+)') {
            $envSection = "  environment:`n" + $matches[1]
        }
        
        # Extraire healthcheck
        $healthSection = ""
        if ($content -match 'healthcheck:\s*\n((?:\s+.+\n)+)') {
            $healthSection = "  healthcheck:`n" + $matches[1]
        }
        
        $compose += @"
  # Service: $name
  $name:
    image: $image
    container_name: $containerName
$portsSection$envSection    networks:
      - traefik-network
$healthSection
"@
    }
    
    # Networks
    $compose += @"

networks:
  traefik-network:
    driver: bridge
"@
    
    $compose | Out-File -FilePath $DockerComposeFile -Encoding UTF8
    Write-Host "`n✅ docker-compose.yml généré" -ForegroundColor Green
    
    # Générer aussi la config Traefik dynamique
    Generate-TraefikDynamic
}

# Fonction pour générer traefik/dynamic.yml
function Generate-TraefikDynamic {
    Write-Host "`n🔧 GÉNÉRATION DE traefik/dynamic.yml" -ForegroundColor Cyan
    
    if (-not (Test-Path "traefik")) {
        New-Item -ItemType Directory -Path "traefik" | Out-Null
    }
    
    $dynamic = @"
# Généré automatiquement par manage-profiles.ps1
http:
  routers:
    traefik-dashboard:
      rule: "PathPrefix(``/traefik``)"
      service: api@internal
      priority: 1000

  middlewares:
"@
    
    $profiles = Get-ChildItem -Path $ProfilesDir -Filter "*.yml" -ErrorAction SilentlyContinue
    
    foreach ($profile in $profiles) {
        $content = Get-Content $profile.FullName -Raw
        $enabled = if ($content -match 'enabled:\s*(true|false)') { $matches[1] -eq 'true' } else { $true }
        $traefikEnabled = if ($content -match 'traefik:\s*\n\s*enabled:\s*(true|false)') { $matches[1] -eq 'true' } else { $false }
        
        if (-not ($enabled -and $traefikEnabled)) { continue }
        
        $name = if ($content -match 'name:\s*(.+)') { $matches[1].Trim() } else { $profile.BaseName }
        $stripPrefix = if ($content -match 'strip_prefix:\s*(true|false)') { $matches[1] -eq 'true' } else { $false }
        
        if ($stripPrefix) {
            $dynamic += @"

    ${name}-strip-prefix:
      stripPrefix:
        prefixes:
          - "/${name}"
"@
        }
    }
    
    $dynamic | Out-File -FilePath $TraefikDynamicFile -Encoding UTF8
    Write-Host "✅ traefik/dynamic.yml généré" -ForegroundColor Green
}

# Fonction pour initialiser secrets.env
function Initialize-Secrets {
    Write-Host "`n🔐 INITIALISATION DES SECRETS" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    if (Test-Path $SecretsFile) {
        Write-Warning "Le fichier $SecretsFile existe déjà"
        if ((Read-Host "Écraser ? (o/N)") -ne 'o') {
            return
        }
    }
    
    # Vérifier SOPS
    if (-not (Get-Command sops -ErrorAction SilentlyContinue)) {
        Write-Error "SOPS n'est pas installé. Installez-le d'abord."
        return
    }
    
    # Copier l'exemple
    if (Test-Path "secrets.env.example") {
        Copy-Item "secrets.env.example" $SecretsFile
    } else {
        "# Secrets file - Edit with: sops secrets.env`n" | Out-File $SecretsFile -Encoding UTF8
    }
    
    Write-Host "`n✅ Fichier $SecretsFile créé" -ForegroundColor Green
    Write-Host "📝 Éditez-le maintenant avec: sops $SecretsFile" -ForegroundColor Yellow
    
    if ((Read-Host "`nOuvrir l'éditeur SOPS maintenant ? (O/n)") -ne 'n') {
        & sops $SecretsFile
    }
}

# Main
switch ($Action) {
    'add' { Add-Profile }
    'list' { Show-Profiles }
    'generate' { Generate-DockerCompose }
    'init-secrets' { Initialize-Secrets }
    default { Show-Profiles }
}
