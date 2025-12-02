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
    [ValidateSet('add', 'list', 'remove', 'enable', 'disable', 'generate', 'init-secrets', 'sync-secrets')]
    [string]$Action = 'list'
)

$PSDefaultParameterValues['*:Encoding'] = 'UTF8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Chemins
$ProfilesDir = "profiles"
$DockerComposeFile = "docker-compose.yml"
$TraefikDynamicFile = "traefik/dynamic.yml"
$SecretsFile = "secrets.env"
$ConfigFile = "config.yml"

# Configuration par défaut
$DefaultConfig = @{
    dozzle_enabled = $true
    dozzle_port = 9999
}

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
    
    Write-Host "`n🔑 Activation du service" -ForegroundColor Yellow
    $alwaysActive = (Read-Host "Service toujours actif (démarré par défaut) ? (O/n)") -ne 'n'
    $dockerProfile = $null
    if (-not $alwaysActive) {
        $dockerProfile = Read-Host "Nom du profil Docker (pour démarrage conditionnel, ex: $name)"
        if ([string]::IsNullOrWhiteSpace($dockerProfile)) { $dockerProfile = $name }
    }
    
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
    $secretsDoc = @()
    while ($true) {
        $secret = Read-Host "Nom du secret"
        if ([string]::IsNullOrWhiteSpace($secret)) { break }
        $secretVar = $secret.ToUpper() -replace '[^A-Z0-9_]', '_'
        $secretDesc = Read-Host "  Description de $secretVar (optionnel)"
        if ([string]::IsNullOrWhiteSpace($secretDesc)) { $secretDesc = "Secret pour $name" }
        
        $secrets += "    - ${secretVar}=`${${secretVar}:-changeme}"
        $secretsDoc += @"
  - name: $secretVar
    description: "$secretDesc"
    default: changeme
"@
    }
    
    # Générer le fichier YAML
    $allEnv = ($envVars + $secrets) -join "`n"
    if ([string]::IsNullOrWhiteSpace($allEnv)) {
        $allEnv = "    # Aucune variable d'environnement"
    }
    
    $secretsSection = ""
    if ($secretsDoc.Count -gt 0) {
        $secretsSection = @"

# Variables de secrets requises (à définir dans secrets.env)
secrets:
$($secretsDoc -join "`n")

"@
    }
    
    $dockerProfileValue = if ($dockerProfile) { $dockerProfile } else { 'null' }
    
    $profileContent = @"
# Profil généré automatiquement
name: $name
description: "$description"
enabled: true
always_active: $($alwaysActive.ToString().ToLower())
docker_profile: $dockerProfileValue

docker-compose:
  image: $image
  container_name: $name
  ports:
    - "$($hostPort):$port"
  environment:
$allEnv
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:$port/health"]
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
$secretsSection
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

"@
    
    # Lire la configuration
    $config = $DefaultConfig.Clone()
    if (Test-Path $ConfigFile) {
        $configContent = Get-Content $ConfigFile -Raw
        if ($configContent -match 'dozzle_enabled:\s*(true|false)') {
            $config.dozzle_enabled = $matches[1] -eq 'true'
        }
        if ($configContent -match 'dozzle_port:\s*(\d+)') {
            $config.dozzle_port = $matches[1]
        }
    }
    
    # Ajouter Dozzle si activé
    if ($config.dozzle_enabled) {
        $compose += @"
  # Monitoring des logs
  dozzle:
    image: amir20/dozzle:latest
    container_name: dozzle
    ports:
      - "$($config.dozzle_port):8080"
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

"@
    }
    
    # Ajouter chaque service
    foreach ($profile in $profiles) {
        $content = Get-Content $profile.FullName -Raw
        $enabled = if ($content -match 'enabled:\s*(true|false)') { $matches[1] -eq 'true' } else { $true }
        
        if (-not $enabled) {
            Write-Host "  ⏭️  Ignoré (désactivé) : $($profile.BaseName)" -ForegroundColor DarkGray
            continue
        }
        
        Write-Host "  ✅ Ajout : $($profile.BaseName)" -ForegroundColor Green
        
        # Extraire le nom et la section docker-compose
        $name = if ($content -match '(?:^|[\r\n])name:\s*(.+)') { $matches[1].Trim() } else { $profile.BaseName }
        $alwaysActive = if ($content -match 'always_active:\s*(true|false)') { $matches[1] -eq 'true' } else { $true }
        $dockerProfile = if ($content -match 'docker_profile:\s*(.+)') { $matches[1].Trim() } else { $null }
        if ($dockerProfile -eq 'null') { $dockerProfile = $null }
        
        if ($content -match 'docker-compose:\s*[\r\n]+((  [^#\r\n].+[\r\n]+)+)') {
            # Extraire tout le contenu sous docker-compose:
            $rawContent = $matches[1] -replace '[\r\n]+$', ''
            
            # Filtrer la section ports: car on ne veut pas exposer les ports des services
            $lines = $rawContent -split '[\r\n]+'
            $filteredLines = @()
            $skipPortsSection = $false
            
            foreach ($line in $lines) {
                if ($line -match '^  ports:') {
                    $skipPortsSection = $true
                    continue
                }
                if ($skipPortsSection) {
                    # Continuer à sauter tant qu'on est dans la section ports (lignes avec 4+ espaces)
                    if ($line -match '^    ') {
                        continue
                    } else {
                        $skipPortsSection = $false
                    }
                }
                $filteredLines += $line
            }
            
            # Ajouter 2 espaces d'indentation à chaque ligne (passer de 2 à 4 espaces)
            $dockerComposeContent = ($filteredLines -join "`r`n") -replace '(?m)^  ', '    '
            
            # Section profiles: si not always_active
            $profilesSection = ""
            if (-not $alwaysActive -and $dockerProfile) {
                $profilesSection = @"

    profiles:
      - $dockerProfile
"@
            }
            
            $compose += @"
  # Service: $name
  ${name}:
$dockerComposeContent
    extra_hosts:
      - "external-ip:host-gateway"
    networks:
      - traefik-network$profilesSection

"@
        }
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

"@
    
    # Lire la configuration pour Dozzle
    $config = $DefaultConfig.Clone()
    if (Test-Path $ConfigFile) {
        $configContent = Get-Content $ConfigFile -Raw
        if ($configContent -match 'dozzle_enabled:\s*(true|false)') {
            $config.dozzle_enabled = $matches[1] -eq 'true'
        }
    }
    
    # Ajouter le router Dozzle si activé
    if ($config.dozzle_enabled) {
        $dynamic += @"
    dozzle:
      rule: "PathPrefix(``/logs``)"
      service: dozzle
      priority: 100

"@
    }
    
    $profiles = Get-ChildItem -Path $ProfilesDir -Filter "*.yml" -ErrorAction SilentlyContinue
    
    # Générer les routers pour chaque profil
    foreach ($profile in $profiles) {
        $content = Get-Content $profile.FullName -Raw
        $enabled = if ($content -match 'enabled:\s*(true|false)') { $matches[1] -eq 'true' } else { $true }
        $traefikEnabled = if ($content -match 'traefik:\s*[\r\n]+\s*enabled:\s*(true|false)') { $matches[1] -eq 'true' } else { $false }
        
        if (-not ($enabled -and $traefikEnabled)) { continue }
        
        $name = if ($content -match 'name:\s*(.+)') { $matches[1].Trim() } else { $profile.BaseName }
        $prefix = if ($content -match 'prefix:\s*(.+)') { $matches[1].Trim() } else { "/${name}" }
        $port = if ($content -match 'traefik:[\s\S]*?port:\s*(\d+)') { $matches[1] } else { '80' }
        $priority = if ($content -match 'priority:\s*(\d+)') { $matches[1] } else { '10' }
        $stripPrefix = if ($content -match 'strip_prefix:\s*(true|false)') { $matches[1] -eq 'true' } else { $false }
        
        $middlewares = if ($stripPrefix) { "`n      middlewares:`n        - ${name}-strip-prefix" } else { "" }
        
        $dynamic += @"
    ${name}:
      rule: "PathPrefix(``${prefix}``)"
      service: ${name}$middlewares
      priority: $priority

"@
    }
    
    # Section services
    $dynamic += @"
  services:
"@
    
    # Ajouter le service Dozzle si activé
    if ($config.dozzle_enabled) {
        $dynamic += @"

    dozzle:
      loadBalancer:
        healthCheck:
          path: /healthcheck
          interval: 5s
          timeout: 1s
        servers:
          - url: "http://dozzle:8080"
        passHostHeader: true
"@
    }
    
    foreach ($profile in $profiles) {
        $content = Get-Content $profile.FullName -Raw
        $enabled = if ($content -match 'enabled:\s*(true|false)') { $matches[1] -eq 'true' } else { $true }
        $traefikEnabled = if ($content -match 'traefik:\s*[\r\n]+\s*enabled:\s*(true|false)') { $matches[1] -eq 'true' } else { $false }
        
        if (-not ($enabled -and $traefikEnabled)) { continue }
        
        $name = if ($content -match 'name:\s*(.+)') { $matches[1].Trim() } else { $profile.BaseName }
        $port = if ($content -match 'traefik:[\s\S]*?port:\s*(\d+)') { $matches[1] } else { '80' }
        $healthPath = if ($content -match 'traefik:[\s\S]*?health_path:\s*(.+)') { $matches[1].Trim() } else { '/health' }
        $enableFailover = if ($content -match 'traefik:[\s\S]*?failover:\s*(true|false)') { $matches[1] -eq 'true' } else { $false }
        $hostPort = if ($content -match 'traefik:[\s\S]*?host_port:\s*(\d+)') { $matches[1] } else { $port }
        
        if ($enableFailover) {
            # Service avec failover (host + docker)
            $dynamic += @"

    ${name}:
      failover:
        service: ${name}-host
        fallback: ${name}-docker
    ${name}-host:
      loadBalancer:
        healthCheck:
          path: $healthPath
          interval: 5s
          timeout: 1s
        servers:
          - url: "http://external-ip:${hostPort}"
        passHostHeader: true
    ${name}-docker:
      loadBalancer:
        healthCheck:
          path: $healthPath
          interval: 5s
          timeout: 1s
        servers:
          - url: "http://${name}:${port}"
        passHostHeader: true
"@
        } else {
            # Service simple sans failover
            $dynamic += @"

    ${name}:
      loadBalancer:
        healthCheck:
          path: $healthPath
          interval: 5s
          timeout: 1s
        servers:
          - url: "http://${name}:${port}"
        passHostHeader: true
"@
        }
    }
    
    # Section middlewares
    $dynamic += @"

  middlewares:
"@
    
    foreach ($profile in $profiles) {
        $content = Get-Content $profile.FullName -Raw
        $enabled = if ($content -match 'enabled:\s*(true|false)') { $matches[1] -eq 'true' } else { $true }
        $traefikEnabled = if ($content -match 'traefik:\s*[\r\n]+\s*enabled:\s*(true|false)') { $matches[1] -eq 'true' } else { $false }
        
        if (-not ($enabled -and $traefikEnabled)) { continue }
        
        $name = if ($content -match 'name:\s*(.+)') { $matches[1].Trim() } else { $profile.BaseName }
        $prefix = if ($content -match 'prefix:\s*(.+)') { $matches[1].Trim() } else { "/${name}" }
        $stripPrefix = if ($content -match 'strip_prefix:\s*(true|false)') { $matches[1] -eq 'true' } else { $false }
        
        if ($stripPrefix) {
            $dynamic += @"

    ${name}-strip-prefix:
      stripPrefix:
        prefixes:
          - "${prefix}"
"@
        }
    }
    
    $dynamic | Out-File -FilePath $TraefikDynamicFile -Encoding UTF8
    Write-Host "✅ traefik/dynamic.yml généré" -ForegroundColor Green
}

# Fonction pour synchroniser secrets.env avec les profils
function Sync-Secrets {
    Write-Host "`n🔄 SYNCHRONISATION DES SECRETS" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    # Vérifier SOPS
    if (-not (Get-Command sops -ErrorAction SilentlyContinue)) {
        Write-Error "SOPS n'est pas installé. Cette fonctionnalité nécessite SOPS."
        Write-Host "`n  💡 Installez SOPS : https://github.com/mozilla/sops/releases" -ForegroundColor Yellow
        return
    }
    
    # Vérifier la configuration SOPS
    if (-not (Test-Path ".sops.yaml")) {
        Write-Error "Fichier .sops.yaml introuvable. Configurez SOPS d'abord."
        return
    }
    
    $sopsConfig = Get-Content ".sops.yaml" -Raw
    if (-not ($sopsConfig -match 'kms:' -or $sopsConfig -match 'age:')) {
        Write-Warning "SOPS n'est pas configuré avec une clé KMS ou Age."
        Write-Host "`n  💡 Éditez .sops.yaml et configurez :" -ForegroundColor Yellow
        Write-Host "     - AWS KMS : kms: 'arn:aws:kms:...'" -ForegroundColor Gray
        Write-Host "     - Age : age: 'age1...'" -ForegroundColor Gray
        Write-Host "`n  Pour générer une clé Age :" -ForegroundColor Yellow
        Write-Host "     age-keygen -o age-key.txt" -ForegroundColor Gray
        return
    }
    
    # Récupérer toutes les variables ${VAR:-default} des profils
    $profiles = Get-ChildItem -Path $ProfilesDir -Filter "*.yml" -ErrorAction SilentlyContinue
    $secretVars = @{}
    
    foreach ($profile in $profiles) {
        $content = Get-Content $profile.FullName -Raw
        $enabled = if ($content -match 'enabled:\s*(true|false)') { $matches[1] -eq 'true' } else { $true }
        
        if (-not $enabled) { continue }
        
        $profileName = if ($content -match 'name:\s*(.+)') { $matches[1].Trim() } else { $profile.BaseName }
        
        # Méthode 1 : Lire la section secrets: si elle existe
        if ($content -match 'secrets:\s*[\r\n]+((?:  - .+[\r\n]+(?:    .+[\r\n]+)*)+)') {
            $secretsSection = $matches[1]
            
            # Parser chaque secret avec ses propriétés
            $secretBlocks = $secretsSection -split '(?=  - name:)'
            foreach ($block in $secretBlocks) {
                if ($block -match '- name:\s*(.+)') {
                    $secretName = $matches[1].Trim()
                    $secretDesc = if ($block -match 'description:\s*"?([^"\r\n]+)"?') { $matches[1].Trim() } else { '' }
                    $secretDefault = if ($block -match 'default:\s*(.+)') { $matches[1].Trim() } else { 'changeme' }
                    
                    if (-not $secretVars.ContainsKey($secretName)) {
                        $secretVars[$secretName] = $secretDefault
                        Write-Host "  📌 [$profileName] $secretName = $secretDefault ($secretDesc)" -ForegroundColor Gray
                    }
                }
            }
        } else {
            # Méthode 2 (fallback) : Scanner les ${VAR:-default} dans environment:
            $matches = [regex]::Matches($content, '\$\{([A-Z_][A-Z0-9_]*):?-([^}]*)\}')
            foreach ($match in $matches) {
                $varName = $match.Groups[1].Value
                $defaultValue = $match.Groups[2].Value
                if ($defaultValue -eq '') { $defaultValue = 'changeme' }
                
                if (-not $secretVars.ContainsKey($varName)) {
                    $secretVars[$varName] = $defaultValue
                    Write-Host "  📌 [$profileName] $varName = $defaultValue (auto-détecté)" -ForegroundColor DarkGray
                }
            }
        }
    }
    
    if ($secretVars.Count -eq 0) {
        Write-Host "  ℹ️  Aucune variable de secrets trouvée dans les profils" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n  Total: $($secretVars.Count) variable(s) trouvée(s)" -ForegroundColor Cyan
    
    # Lire le fichier secrets.env existant (déchiffré)
    $existingSecrets = @{}
    $secretsContent = ""
    
    if (Test-Path $SecretsFile) {
        try {
            # Déchiffrer et lire
            $decrypted = sops -d $SecretsFile 2>&1
            if ($LASTEXITCODE -eq 0) {
                $secretsContent = $decrypted
                foreach ($line in $decrypted -split "`n") {
                    if ($line -match '^([A-Z_][A-Z0-9_]*)=(.*)$') {
                        $existingSecrets[$matches[1]] = $matches[2]
                    }
                }
                Write-Host "`n  ✅ Fichier secrets.env déchiffré ($($existingSecrets.Count) variables existantes)" -ForegroundColor Green
            } else {
                Write-Warning "Impossible de déchiffrer secrets.env. Création d'un nouveau fichier."
            }
        } catch {
            Write-Warning "Erreur lors de la lecture de secrets.env: $_"
        }
    }
    
    # Identifier les nouvelles variables à ajouter
    $newVars = @{}
    foreach ($var in $secretVars.Keys) {
        if (-not $existingSecrets.ContainsKey($var)) {
            $newVars[$var] = $secretVars[$var]
        }
    }
    
    if ($newVars.Count -eq 0) {
        Write-Host "`n  ✅ Toutes les variables sont déjà présentes dans secrets.env" -ForegroundColor Green
        return
    }
    
    Write-Host "`n  📝 Variables manquantes à ajouter:" -ForegroundColor Yellow
    foreach ($var in $newVars.Keys) {
        Write-Host "     - $var=$($newVars[$var])" -ForegroundColor Gray
    }
    
    # Demander confirmation
    Write-Host ""
    $confirm = Read-Host "  Ajouter ces variables à secrets.env ? (o/N)"
    if ($confirm -ne 'o') {
        Write-Host "  ⏭️  Annulé" -ForegroundColor Yellow
        return
    }
    
    # Construire le nouveau contenu
    $lines = @()
    if ($secretsContent) {
        $lines += $secretsContent -split "`n" | Where-Object { $_.Trim() -ne '' }
    }
    
    $lines += ""
    $lines += "# Variables ajoutées automatiquement le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    foreach ($var in $newVars.Keys | Sort-Object) {
        $lines += "$var=$($newVars[$var])"
    }
    
    $newContent = $lines -join "`n"
    
    # Sauvegarder temporairement en clair
    $tempFile = "$SecretsFile.tmp"
    $newContent | Out-File -FilePath $tempFile -Encoding UTF8 -NoNewline
    
    # Chiffrer avec SOPS
    try {
        sops -e $tempFile | Out-File -FilePath $SecretsFile -Encoding UTF8
        Remove-Item $tempFile -Force
        Write-Host "`n  ✅ secrets.env mis à jour et rechiffré ($($newVars.Count) variable(s) ajoutée(s))" -ForegroundColor Green
    } catch {
        Write-Error "Erreur lors du chiffrement: $_"
        if (Test-Path $tempFile) {
            Remove-Item $tempFile -Force
        }
    }
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
    'sync-secrets' { Sync-Secrets }
    default { Show-Profiles }
}
