#Requires -Version 5.1
# ══════════════════════════════════════════════════════════════════════════════
#  install-starship.ps1 — Starship prompt setup for Windows PowerShell
#
#  One-liner install:
#    irm https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install-starship.ps1 | iex
#
#  Or locally:
#    .\install-starship.ps1
#
#  Safe to re-run: every step checks before acting.
# ══════════════════════════════════════════════════════════════════════════════

# ── Output helpers ───────────────────────────────────────────────────────────
function step { param($msg) Write-Host "`n  " -NoNewline; Write-Host "▸ $msg" -ForegroundColor Cyan }
function ok   { param($msg) Write-Host "  ✓ $msg" -ForegroundColor Green }
function warn { param($msg) Write-Host "  ! $msg" -ForegroundColor Yellow }
function die  { param($msg) Write-Host "  ✗ $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "════════════════════════════════════════════════════"
Write-Host "  Starship — PowerShell Setup"
Write-Host "════════════════════════════════════════════════════"
Write-Host ""

# ── Install Starship via winget ──────────────────────────────────────────────
step "Checking Starship..."
$starshipPath = $null
try {
    $starshipPath = Get-Command starship -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
} catch {}

if ($starshipPath) {
    ok "Starship already installed ($starshipPath)"
} else {
    step "Installing Starship via winget..."
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        die "winget not found. Install Windows 10 1809+ or Windows 11, or install the App Installer from the Microsoft Store."
    }
    $result = & winget install --id Starship.Starship -e --accept-package-agreements --accept-source-agreements 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0 -and $exitCode -ne -1978335189) {
        # -1978335189 = already installed
        die "winget install failed (exit $exitCode). Run manually: winget install Starship.Starship"
    }
    ok "Starship installed"
    # Refresh PATH so starship is found in this session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# ── Configure PowerShell profile ─────────────────────────────────────────────
step "Configuring PowerShell profile..."
$profileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    ok "Created profile directory: $profileDir"
}
$initLine = "Invoke-Expression (&starship init powershell)"
$profileContent = ""
if (Test-Path $PROFILE) {
    $profileContent = Get-Content $PROFILE -Raw
}
if ($profileContent -and $profileContent.Contains($initLine)) {
    ok "Profile already contains Starship init"
} else {
    Add-Content -Path $PROFILE -Value "`n$initLine"
    ok "Added Starship init to $PROFILE"
}

# ── Done ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "════════════════════════════════════════════════════"
Write-Host "  All done!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════"
Write-Host ""
Write-Host "  Restart PowerShell or run:"
Write-Host ""
Write-Host "      . `$PROFILE"
Write-Host ""
warn "Recommended: Install CaskaydiaCove NF or MesloLGS NF from https://www.nerdfonts.com/"
Write-Host "  and set it in Windows Terminal → Settings → Profiles → PowerShell → Appearance → Font face"
Write-Host ""
Write-Host "  If using chezmoi, dot_config/starship.toml is already in your dotfiles — run 'chezmoi apply' to sync."
Write-Host ""
