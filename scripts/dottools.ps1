#Requires -Version 5.1
# ══════════════════════════════════════════════════════════════════════════════
#  dottools.ps1 — upgrade PowerShell 7, chezmoi, Starship, Cursor, VS Code (Windows)
#
#  Run from profile: dottools
#  Kept separate from dotup so pulls stay fast.
# ══════════════════════════════════════════════════════════════════════════════

function step { param($msg) Write-Host "`n  " -NoNewline; Write-Host "▸ $msg" -ForegroundColor Cyan }
function ok   { param($msg) Write-Host "  ✓ $msg" -ForegroundColor Green }
function warn { param($msg) Write-Host "  ! $msg" -ForegroundColor Yellow }

Write-Host ""
Write-Host "════════════════════════════════════════════════════"
Write-Host "  dottools — Windows upgrades (winget)"
Write-Host "════════════════════════════════════════════════════"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    warn "winget not found. Install App Installer from the Microsoft Store."
    exit 1
}

$packages = @(
    @{ Id = 'Microsoft.PowerShell'; Name = 'PowerShell 7+' },
    @{ Id = 'Twpayne.Chezmoi'; Name = 'chezmoi' },
    @{ Id = 'Starship.Starship'; Name = 'Starship' },
    @{ Id = 'Anysphere.Cursor'; Name = 'Cursor' },
    @{ Id = 'Microsoft.VisualStudioCode'; Name = 'Visual Studio Code' }
)

foreach ($p in $packages) {
    step "$($p.Name) ($($p.Id))..."
    winget upgrade --id $p.Id -e --silent --accept-package-agreements --accept-source-agreements 2>$null
    if ($LASTEXITCODE -eq 0) { ok "upgrade OK (or no update)" }
    else { ok "skipped / not installed / already current" }
}

Write-Host ""
Write-Host "  dottools: done" -ForegroundColor Green
Write-Host ""
