#Requires -Version 5.1
<#
Undo Marty's dotfiles PowerShell setup.

This script is intentionally conservative:
- Creates a timestamped backup of every file/folder it touches.
- Resets both pwsh and Windows PowerShell profile files to a minimal baseline.
- Removes chezmoi source/config folders created by bootstrap.
- By default, does NOT uninstall Starship (settings rollback only).
- Optionally uninstalls chezmoi and Starship when -UninstallPackages is used.

One-liner:
  irm https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/undo-powershell.ps1 | iex
#>

[CmdletBinding()]
param(
    [switch]$UninstallPackages
)

$ErrorActionPreference = 'Stop'

function Step([string]$Message) { Write-Host "`n[>] $Message" -ForegroundColor Cyan }
function Ok([string]$Message) { Write-Host "[OK] $Message" -ForegroundColor Green }
function Warn([string]$Message) { Write-Host "[!!] $Message" -ForegroundColor Yellow }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $env:USERPROFILE "dotfiles-undo-backup-$stamp"
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
Ok "Backup directory: $backupRoot"

function Backup-Path {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $safe = $Path -replace '[:\\\/]+', '_'
    $dest = Join-Path $backupRoot $safe
    Copy-Item -LiteralPath $Path -Destination $dest -Recurse -Force
    return $true
}

function Reset-Profile {
    param(
        [Parameter(Mandatory = $true)][string]$ProfilePath
    )

    $parent = [System.IO.Path]::GetDirectoryName($ProfilePath)
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (Backup-Path -Path $ProfilePath) {
        Ok "Backed up: $ProfilePath"
    }

    @(
        '# Reset by undo-powershell.ps1'
        '# Intentionally minimal profile to recover a working shell.'
        ''
    ) | Set-Content -LiteralPath $ProfilePath -Encoding utf8

    Ok "Reset profile: $ProfilePath"
}

Step 'Resetting PowerShell profile files'
$profiles = @(
    (Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1')
)
foreach ($p in $profiles) {
    Reset-Profile -ProfilePath $p
}

Step 'Removing chezmoi config/source used by dotfiles bootstrap'
$removeTargets = @(
    (Join-Path $env:USERPROFILE '.config\chezmoi'),
    (Join-Path $env:USERPROFILE '.local\share\chezmoi')
)
foreach ($target in $removeTargets) {
    if (Test-Path -LiteralPath $target) {
        Backup-Path -Path $target | Out-Null
        Remove-Item -LiteralPath $target -Recurse -Force
        Ok "Removed: $target"
    } else {
        Warn "Not found (skipped): $target"
    }
}

Step 'Removing fallback chezmoi binary if present'
$chezmoiBin = Join-Path $env:USERPROFILE '.local\bin\chezmoi.exe'
if (Test-Path -LiteralPath $chezmoiBin) {
    Backup-Path -Path $chezmoiBin | Out-Null
    Remove-Item -LiteralPath $chezmoiBin -Force
    Ok "Removed: $chezmoiBin"
} else {
    Warn "Not found (skipped): $chezmoiBin"
}

if ($UninstallPackages) {
    Step 'Uninstalling winget packages (chezmoi + Starship)'
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        & winget uninstall --id twpayne.chezmoi -e --accept-source-agreements | Out-Null
        if ($LASTEXITCODE -eq 0) { Ok 'Uninstalled twpayne.chezmoi' } else { Warn "winget uninstall twpayne.chezmoi exit $LASTEXITCODE" }

        & winget uninstall --id Starship.Starship -e --accept-source-agreements | Out-Null
        if ($LASTEXITCODE -eq 0) { Ok 'Uninstalled Starship.Starship' } else { Warn "winget uninstall Starship.Starship exit $LASTEXITCODE" }
    } else {
        Warn 'winget not found; package uninstall skipped.'
    }
}

Write-Host ''
Write-Host 'Undo complete.' -ForegroundColor Green
Write-Host "Backups are in: $backupRoot" -ForegroundColor Green
Write-Host 'Close all PowerShell windows and open a new one.' -ForegroundColor Green
