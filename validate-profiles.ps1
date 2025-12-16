#!/usr/bin/env pwsh
# Script de validation des profils Dev.Local 2.0
# Valide la syntaxe YAML, les champs requis et les valeurs des profils

param(
    [switch]$Help
)

$ErrorActionPreference = "Continue"
$ProfilesDir = "profiles"
$Script:Errors = 0
$Script:Warnings = 0
$Script:Validated = 0

# Détection de yq (mikefarah v4+)
$Script:YqCmd = $null

function Test-YqAvailable {
    try {
        $yqPath = Get-Command yq -ErrorAction SilentlyContinue
        if (-not $yqPath) {
            return $false
        }

        # Vérifier que c'est mikefarah/yq (a la commande 'eval')
        $help = yq --help 2>&1 | Out-String
        if ($help -match "eval") {
            # Vérifier la version (v4+)
            $version = yq --version 2>&1 | Out-String
            if ($version -match "version [v]?(\d+)") {
                $versionNum = [int]$Matches[1]
                if ($versionNum -ge 4) {
                    $Script:YqCmd = "yq"
                    return $true
                }
            }
        }
        return $false
    }
    catch {
        return $false
    }
}

# Initialiser yq
$yqAvailable = Test-YqAvailable

# Fonctions d'affichage colorées
function Write-Error-Message {
    param([string]$Profile, [string]$Message)
    Write-Host "❌ ERREUR " -ForegroundColor Red -NoNewline
    Write-Host "[$Profile]: $Message"
    $Script:Errors++
}

function Write-Warning-Message {
    param([string]$Profile, [string]$Message)
    Write-Host "⚠️  AVERTISSEMENT " -ForegroundColor Yellow -NoNewline
    Write-Host "[$Profile]: $Message"
    $Script:Warnings++
}

function Write-Success-Message {
    param([string]$Profile)
    Write-Host "✅" -ForegroundColor Green -NoNewline
    Write-Host " $Profile"
}

# Fonction pour extraire une valeur YAML
function Get-YamlValue {
    param(
        [string]$File,
        [string]$Path,
        [string]$Default = ""
    )

    if ($Script:YqCmd) {
        try {
            # Ne pas utiliser // car il traite false comme falsy
            $value = & yq e $Path $File 2>$null

            # Si la valeur est null ou vide, utiliser le défaut
            if ([string]::IsNullOrEmpty($value) -or $value -eq "null") {
                return $Default
            }
            return $value
        }
        catch {
            return $Default
        }
    }
    else {
        # Fallback: parsing avec regex PowerShell
        $key = $Path -replace '^\.' -replace '.*\.'
        $content = Get-Content $File -Raw

        if ($content -match "(?m)^[[:space:]]*${key}:[[:space:]]*(.+?)(?:#.*)?$") {
            $value = $Matches[1].Trim()
            return $value
        }
        return $Default
    }
}

# Validation 1: Syntaxe YAML
function Test-YamlSyntax {
    param([string]$ProfilePath)

    $basename = [System.IO.Path]::GetFileNameWithoutExtension($ProfilePath)

    if ($Script:YqCmd) {
        try {
            $null = & yq e '.' $ProfilePath 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Error-Message $basename "Syntaxe YAML invalide"
                return $false
            }
        }
        catch {
            Write-Error-Message $basename "Syntaxe YAML invalide"
            return $false
        }
    }
    else {
        # Validation basique sans yq
        $content = Get-Content $ProfilePath -Raw -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-Error-Message $basename "Fichier vide ou invalide"
            return $false
        }
    }

    return $true
}

# Validation 2: Champs requis
function Test-RequiredFields {
    param([string]$ProfilePath)

    $basename = [System.IO.Path]::GetFileNameWithoutExtension($ProfilePath)
    $hasErrors = $false

    # Champs obligatoires au niveau racine
    $name = Get-YamlValue -File $ProfilePath -Path ".name"
    if ([string]::IsNullOrEmpty($name) -or $name -eq "null") {
        Write-Error-Message $basename "Champ 'name' manquant ou vide"
        $hasErrors = $true
    }

    $enabled = Get-YamlValue -File $ProfilePath -Path ".enabled"
    if ($enabled -ne "true" -and $enabled -ne "false") {
        Write-Error-Message $basename "Champ 'enabled' doit être true ou false (trouvé: '$enabled')"
        $hasErrors = $true
    }

    # Validation docker-compose
    $content = Get-Content $ProfilePath -Raw
    if ($content -notmatch "(?m)^docker-compose:") {
        Write-Error-Message $basename "Section 'docker-compose' manquante"
        return $false
    }

    $image = Get-YamlValue -File $ProfilePath -Path ".docker-compose.image"
    if ([string]::IsNullOrEmpty($image) -or $image -eq "null") {
        Write-Error-Message $basename "Champ 'docker-compose.image' manquant ou vide"
        $hasErrors = $true
    }

    $containerName = Get-YamlValue -File $ProfilePath -Path ".docker-compose.container_name"
    if ([string]::IsNullOrEmpty($containerName) -or $containerName -eq "null") {
        Write-Warning-Message $basename "Champ 'docker-compose.container_name' recommandé"
    }

    return -not $hasErrors
}

# Validation 3: Valeurs et types
function Test-Values {
    param([string]$ProfilePath)

    $basename = [System.IO.Path]::GetFileNameWithoutExtension($ProfilePath)
    $hasErrors = $false

    # Validation always_active vs docker_profile
    $alwaysActive = Get-YamlValue -File $ProfilePath -Path ".always_active" -Default "false"
    $dockerProfile = Get-YamlValue -File $ProfilePath -Path ".docker_profile"

    if ($alwaysActive -eq "true" -and $dockerProfile -ne "null" -and -not [string]::IsNullOrEmpty($dockerProfile)) {
        Write-Warning-Message $basename "always_active=true mais docker_profile='$dockerProfile' (devrait être null)"
    }

    if ($alwaysActive -eq "false" -and ($dockerProfile -eq "null" -or [string]::IsNullOrEmpty($dockerProfile))) {
        Write-Error-Message $basename "always_active=false nécessite un docker_profile valide"
        $hasErrors = $true
    }

    # Validation des ports
    $content = Get-Content $ProfilePath -Raw
    if ($content -match "(?m)^[[:space:]]*ports:") {
        if ($content -match '"non"') {
            Write-Error-Message $basename "Valeur de port invalide: 'non' (devrait être 'none' ou un port valide)"
            $hasErrors = $true
        }
    }

    # Validation Traefik si activé
    if ($content -match "(?m)^traefik:") {
        $traefikEnabled = Get-YamlValue -File $ProfilePath -Path ".traefik.enabled" -Default "false"

        if ($traefikEnabled -eq "true") {
            $prefix = Get-YamlValue -File $ProfilePath -Path ".traefik.prefix"
            if ([string]::IsNullOrEmpty($prefix) -or $prefix -eq "null") {
                Write-Error-Message $basename "traefik.prefix requis quand traefik est activé"
                $hasErrors = $true
            }
            elseif ($prefix -notmatch "^/") {
                Write-Error-Message $basename "traefik.prefix doit commencer par '/' (trouvé: '$prefix')"
                $hasErrors = $true
            }

            $dockerPort = Get-YamlValue -File $ProfilePath -Path ".traefik.docker_port" -Default "80"
            if ($dockerPort -notmatch "^\d+$" -or [int]$dockerPort -lt 1 -or [int]$dockerPort -gt 65535) {
                Write-Error-Message $basename "traefik.docker_port doit être entre 1 et 65535 (trouvé: '$dockerPort')"
                $hasErrors = $true
            }

            $localPort = Get-YamlValue -File $ProfilePath -Path ".traefik.local_port" -Default "80"
            if ($localPort -notmatch "^\d+$" -or [int]$localPort -lt 1 -or [int]$localPort -gt 65535) {
                Write-Error-Message $basename "traefik.local_port doit être entre 1 et 65535 (trouvé: '$localPort')"
                $hasErrors = $true
            }

            $priority = Get-YamlValue -File $ProfilePath -Path ".traefik.priority" -Default "10"
            if ($priority -notmatch "^\d+$") {
                Write-Warning-Message $basename "traefik.priority doit être un entier (trouvé: '$priority')"
            }
        }
    }

    return -not $hasErrors
}

# Validation 4: Validations inter-profils
function Test-CrossProfile {
    $containerNames = @{}
    $hostPorts = @{}
    $hasErrors = $false

    $profiles = Get-ChildItem -Path $ProfilesDir -Filter "*.yml" -File

    foreach ($profile in $profiles) {
        $enabled = Get-YamlValue -File $profile.FullName -Path ".enabled" -Default "true"
        if ($enabled -ne "true") { continue }

        $basename = $profile.BaseName

        # Vérifier l'unicité des noms de containers
        $containerName = Get-YamlValue -File $profile.FullName -Path ".docker-compose.container_name"
        if (-not [string]::IsNullOrEmpty($containerName) -and $containerName -ne "null") {
            if ($containerNames.ContainsKey($containerName)) {
                Write-Error-Message $basename "Nom de container '$containerName' déjà utilisé par $($containerNames[$containerName])"
                $hasErrors = $true
            }
            else {
                $containerNames[$containerName] = $basename
            }
        }

        # Vérifier les conflits de ports
        $content = Get-Content $profile.FullName -Raw
        if ($content -match "(?m)^[[:space:]]*ports:") {
            $portMatches = [regex]::Matches($content, '(?m)^[[:space:]]*-[[:space:]]*"?(\d+):')
            foreach ($match in $portMatches) {
                $hostPort = $match.Groups[1].Value
                if ($hostPorts.ContainsKey($hostPort)) {
                    Write-Warning-Message $basename "Port hôte $hostPort déjà utilisé par $($hostPorts[$hostPort])"
                }
                else {
                    $hostPorts[$hostPort] = $basename
                }
            }
        }
    }

    return -not $hasErrors
}

# Fonction principale de validation
function Test-Profile {
    param([string]$ProfilePath)

    if (-not (Test-YamlSyntax $ProfilePath)) { return $false }
    if (-not (Test-RequiredFields $ProfilePath)) { return $false }
    if (-not (Test-Values $ProfilePath)) { return $false }

    return $true
}

# Main
function Main {
    Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     VALIDATION DES PROFILS DEV.LOCAL 2.0            ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    if ($yqAvailable) {
        Write-Host "✓" -ForegroundColor Green -NoNewline
        Write-Host " yq détecté - validation complète activée"
    }
    else {
        Write-Host "⚠" -ForegroundColor Yellow -NoNewline
        Write-Host " yq non disponible - validation basique seulement"
    }
    Write-Host ""

    if (-not (Test-Path $ProfilesDir)) {
        Write-Host "Aucun profil trouvé dans $ProfilesDir" -ForegroundColor Yellow
        exit 0
    }

    $profiles = Get-ChildItem -Path $ProfilesDir -Filter "*.yml" -File
    if ($profiles.Count -eq 0) {
        Write-Host "Aucun profil trouvé dans $ProfilesDir" -ForegroundColor Yellow
        exit 0
    }

    Write-Host "📋 Validation individuelle des profils:" -ForegroundColor Cyan
    Write-Host ""

    foreach ($profile in $profiles) {
        if (Test-Profile $profile.FullName) {
            Write-Success-Message $profile.BaseName
            $Script:Validated++
        }
    }

    Write-Host ""
    Write-Host "🔍 Validations inter-profils:" -ForegroundColor Cyan
    Write-Host ""

    Test-CrossProfile | Out-Null

    # Résumé
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    RÉSUMÉ                            ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Profils validés    : " -NoNewline
    Write-Host $Script:Validated -ForegroundColor Green
    Write-Host "  Erreurs            : " -NoNewline
    Write-Host $Script:Errors -ForegroundColor Red
    Write-Host "  Avertissements     : " -NoNewline
    Write-Host $Script:Warnings -ForegroundColor Yellow
    Write-Host ""

    if ($Script:Errors -gt 0) {
        Write-Host "❌ La validation a échoué avec $($Script:Errors) erreur(s)" -ForegroundColor Red
        exit 1
    }
    elseif ($Script:Warnings -gt 0) {
        Write-Host "⚠️  La validation a réussi mais avec $($Script:Warnings) avertissement(s)" -ForegroundColor Yellow
        exit 0
    }
    else {
        Write-Host "✅ Tous les profils sont valides !" -ForegroundColor Green
        exit 0
    }
}

# Afficher l'aide si demandé
if ($Help) {
    Write-Host @"
VALIDATION DES PROFILS DEV.LOCAL 2.0

Usage:
    .\validate-profiles.ps1          # Valider tous les profils
    .\validate-profiles.ps1 -Help    # Afficher cette aide

Description:
    Valide la syntaxe YAML, les champs requis et les valeurs des profils
    dans le répertoire profiles/

Validations effectuées:
    1. Syntaxe YAML valide
    2. Champs requis présents (name, enabled, docker-compose.image)
    3. Valeurs correctes (ports, prefixes Traefik, types)
    4. Validations inter-profils (noms uniques, conflits de ports)

Codes de sortie:
    0 - Tous les profils sont valides
    1 - Erreurs détectées

"@
    exit 0
}

# Exécuter
Main