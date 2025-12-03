<#
.SYNOPSIS
    Vérifie et corrige les permissions des fichiers .sh

.DESCRIPTION
    S'assure que tous les fichiers .sh ont le bit exécutable dans Git.
    Utile pour les développeurs travaillant sur Windows.

.EXAMPLE
    .\fix-sh-permissions.ps1
    Vérifie et corrige les permissions de tous les fichiers .sh
#>

$PSDefaultParameterValues['*:Encoding'] = 'UTF8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "`n🔧 VÉRIFICATION DES PERMISSIONS .sh" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

# Vérifier si on est dans un repo Git
if (-not (Test-Path ".git")) {
    Write-Error "Ce script doit être exécuté à la racine d'un dépôt Git"
    exit 1
}

# Trouver tous les fichiers .sh
$shFiles = Get-ChildItem -Path . -Filter "*.sh" -File -Recurse | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }

if ($shFiles.Count -eq 0) {
    Write-Host "`n  ℹ️  Aucun fichier .sh trouvé" -ForegroundColor Yellow
    exit 0
}

Write-Host "`n  📁 Fichiers .sh trouvés : $($shFiles.Count)" -ForegroundColor White

# Vérifier les permissions actuelles
$needsFixing = @()

foreach ($file in $shFiles) {
    $relativePath = $file.FullName.Replace((Get-Location).Path + [IO.Path]::DirectorySeparatorChar, '').Replace('\', '/')

    # Obtenir les permissions Git
    $gitMode = git ls-files -s $relativePath 2>$null

    if ($gitMode) {
        $mode = $gitMode.Substring(0, 6)

        if ($mode -eq '100755') {
            Write-Host "  ✅ $relativePath - Exécutable" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $relativePath - Non exécutable ($mode)" -ForegroundColor Red
            $needsFixing += $relativePath
        }
    } else {
        Write-Host "  ⚠️  $relativePath - Non suivi par Git" -ForegroundColor Yellow
    }
}

# Corriger les permissions si nécessaire
if ($needsFixing.Count -gt 0) {
    Write-Host "`n  🔧 Correction de $($needsFixing.Count) fichier(s)..." -ForegroundColor Yellow

    foreach ($file in $needsFixing) {
        git update-index --chmod=+x $file
        Write-Host "     ✓ $file" -ForegroundColor Gray
    }

    Write-Host "`n  ✅ Permissions corrigées !" -ForegroundColor Green
    Write-Host "  💡 N'oubliez pas de commiter ces changements :" -ForegroundColor Yellow
    Write-Host "     git add $($needsFixing -join ' ')" -ForegroundColor Gray
    Write-Host "     git commit -m 'Fix: Ajouter bit exécutable aux scripts .sh'" -ForegroundColor Gray
} else {
    Write-Host "`n  ✅ Toutes les permissions sont correctes !" -ForegroundColor Green
}

Write-Host ""

