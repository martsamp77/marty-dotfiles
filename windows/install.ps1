# windows/install.ps1 — Bootstrap PowerShell profile from marty-dotfiles
#
# Usage (from repo root or windows/ subfolder):
#   .\windows\install.ps1
#   .\windows\install.ps1 -RepoPath "C:\path\to\marty-dotfiles"
#
# What it does:
#   1. Saves the repo path to ~/.marty-dotfiles.json (used by dotsync)
#   2. Copies windows/profile.ps1 to both PowerShell profile locations

param(
    [string]$RepoPath
)

# Resolve repo root: default to parent of this script's directory
if (-not $RepoPath) {
    $RepoPath = Split-Path $PSScriptRoot
}
$RepoPath = (Resolve-Path $RepoPath).Path

# Validate
$source = Join-Path $RepoPath 'windows\profile.ps1'
if (-not (Test-Path $source)) {
    Write-Error "Profile source not found: $source`nMake sure RepoPath points to the marty-dotfiles repo root."
    exit 1
}

# Save repo path so dotsync can find it later
$configFile = Join-Path $env:USERPROFILE '.marty-dotfiles.json'
@{ repoPath = $RepoPath } | ConvertTo-Json | Set-Content $configFile -Encoding UTF8
Write-Host "Config saved: $configFile"

# Deploy to both PowerShell profile locations
$targets = @(
    [IO.Path]::Combine($env:USERPROFILE, 'Documents', 'PowerShell', 'Microsoft.PowerShell_profile.ps1'),
    [IO.Path]::Combine($env:USERPROFILE, 'Documents', 'WindowsPowerShell', 'Microsoft.PowerShell_profile.ps1')
)
foreach ($target in $targets) {
    New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
    Copy-Item $source $target -Force
    Write-Host "Installed -> $target"
}

Write-Host ""
Write-Host "Done. Open a new PowerShell window, or reload with: . `$PROFILE"
Write-Host "To sync future repo changes: dotsync"
