# windows/tools.ps1 — Upgrade Windows packages via winget
# Usage: .\windows\tools.ps1

$packages = @(
    'Microsoft.PowerShell',
    'Git.Git'
)

foreach ($pkg in $packages) {
    Write-Host "Upgrading $pkg ..."
    winget upgrade --id $pkg --silent --accept-package-agreements --accept-source-agreements
}

Write-Host ""
Write-Host "All packages up to date."
