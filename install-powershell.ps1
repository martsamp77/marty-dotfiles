#Requires -Version 5.1
# ══════════════════════════════════════════════════════════════════════════════
#  install-powershell.ps1 — Bootstrap Marty's dotfiles on Windows (PowerShell)
#
#  One-liner:
#    irm https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install-powershell.ps1 | iex
#
#  Or from a clone:
#    .\install-powershell.ps1
#
#  Installs chezmoi if needed, runs chezmoi init --apply, optionally Starship.
# ══════════════════════════════════════════════════════════════════════════════

function step { param($msg) Write-Host "`n  " -NoNewline; Write-Host "▸ $msg" -ForegroundColor Cyan }
function ok   { param($msg) Write-Host "  ✓ $msg" -ForegroundColor Green }
function warn { param($msg) Write-Host "  ! $msg" -ForegroundColor Yellow }
function die  { param($msg) Write-Host "  ✗ $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "════════════════════════════════════════════════════"
Write-Host "  Marty's Dotfiles — Windows (PowerShell) bootstrap"
Write-Host "════════════════════════════════════════════════════"
Write-Host ""

$REPO_SSH = 'git@github.com:martsamp77/marty-dotfiles.git'
$REPO_HTTPS = 'https://github.com/martsamp77/marty-dotfiles.git'

step "Checking git..."
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    die "git not found. Install Git for Windows first."
}
ok "git present"

step "Checking chezmoi..."
if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
    step "Installing chezmoi..."
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        die "winget not found. Install App Installer / winget, then: winget install Twpayne.Chezmoi — or see https://www.chezmoi.io/install/"
    }
    winget install --id Twpayne.Chezmoi -e --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
        warn "winget install chezmoi exited $LASTEXITCODE"
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [System.Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
        die "chezmoi not on PATH after install. Open a new terminal and re-run, or install manually: https://www.chezmoi.io/install/"
    }
    ok "chezmoi installed"
} else {
    ok "chezmoi present"
}

$useSsh = $false
step "Detecting GitHub access (SSH vs HTTPS)..."
$sshTest = ssh -o ConnectTimeout=5 -T git@github.com 2>&1 | Out-String
if ($sshTest -match 'Hi martsamp77') {
    $useSsh = $true
    ok "GitHub SSH OK — using $REPO_SSH"
} else {
    warn "GitHub SSH not available — using HTTPS (add a key later if you want)"
}

$REPO = if ($useSsh) { $REPO_SSH } else { $REPO_HTTPS }

step "Initializing chezmoi (you may be prompted for PowerShell preferences)..."
$sourceDir = Join-Path $env:USERPROFILE '.local\share\chezmoi'
if (Test-Path (Join-Path $sourceDir '.git')) {
    warn "chezmoi source already exists — running update + apply"
    chezmoi git pull
    chezmoi apply -v
} else {
    chezmoi init --apply $REPO
    if (-not $?) { die "chezmoi init --apply failed" }
}
ok "Dotfiles applied"

# Optional Starship if enabled in chezmoi data
try {
    $dataJson = chezmoi data --format json 2>$null | ConvertFrom-Json
    if ($dataJson.ps -and $dataJson.ps.starship -eq $true) {
        if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
            step "Installing Starship (enabled in preferences)..."
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                winget install --id Starship.Starship -e --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
                $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                    [System.Environment]::GetEnvironmentVariable('Path', 'User')
            }
            if (Get-Command starship -ErrorAction SilentlyContinue) { ok "Starship installed" }
            else { warn "Install Starship manually: winget install Starship.Starship" }
        }
    }
} catch {
    warn "Could not read chezmoi data for Starship check — install Starship manually if wanted"
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════"
Write-Host "  All done!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════"
Write-Host ""
Write-Host "  Reload your profile:"
Write-Host "      . `$PROFILE"
Write-Host ""
Write-Host "  Commands:  dotup   dotupload   dotps show   dotps wizard   undotps   dottools"
Write-Host ""
