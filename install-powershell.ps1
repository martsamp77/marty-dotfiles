#Requires -Version 5.1
# ══════════════════════════════════════════════════════════════════════════════
#  install-powershell.ps1 — Bootstrap Marty's dotfiles on Windows (PowerShell)
#
#  One-liner:
#    irm https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install-powershell.ps1 | iex
# 
#  Undo settings one-liner:
#    irm https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/undo-powershell.ps1 | iex
#
#  Or from a clone:
#    .\install-powershell.ps1
#
#  Installs chezmoi if needed, runs chezmoi init --apply, optionally Starship.
#  Starship setup follows the standard model: install binary + shell profile init.
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
# winget manifest id is lowercase (Twpayne.Chezmoi is invalid — exits -1978335212)
$ChezmoiWingetId = 'twpayne.chezmoi'

function Refresh-MartyPathEnv {
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [System.Environment]::GetEnvironmentVariable('Path', 'User')
}

function Install-ChezmoiFromGetChezmoiIo {
    param([string]$BinDir)
    if (-not (Test-Path -LiteralPath $BinDir)) {
        New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
    }
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    } catch {}
    $install = Invoke-RestMethod -Uri 'https://get.chezmoi.io/ps1' -UseBasicParsing
    & ([scriptblock]::Create($install)) -b $BinDir
}

function Get-MartyPowerShellProfileTargets {
    return @(
        (Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'),
        (Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1')
    )
}

# pwsh uses Documents\PowerShell\...; Windows PowerShell 5.1 uses Documents\WindowsPowerShell\...
# Always create parent dirs and re-apply each target so `. $PROFILE` works in either host after install.
function Ensure-MartyPowerShellProfiles {
    foreach ($dest in (Get-MartyPowerShellProfileTargets)) {
        # Use .NET (not Split-Path -LiteralPath -Parent) — PS 5.1 parameter-set clash on some builds.
        $parent = [System.IO.Path]::GetDirectoryName($dest)
        if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        step "PowerShell profile: $dest"
        chezmoi apply --verbose $dest
        if (-not $?) {
            warn "chezmoi apply exited $LASTEXITCODE for this profile — check: chezmoi managed"
        }
        if (Test-Path -LiteralPath $dest) {
            ok "Profile file present"
        } else {
            warn "Profile still missing — try: chezmoi apply `"$dest`""
        }
    }
}

step "Checking git..."
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    die "git not found. Install Git for Windows first."
}
ok "git present"

step "Checking chezmoi..."
if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
    $localBin = Join-Path $env:USERPROFILE '.local\bin'
    step "Installing chezmoi..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id $ChezmoiWingetId -e --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
            warn "winget install chezmoi exited $LASTEXITCODE — trying get.chezmoi.io"
        }
        Refresh-MartyPathEnv
    } else {
        warn "winget not found — installing chezmoi via get.chezmoi.io"
    }
    if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
        step "Installing chezmoi (get.chezmoi.io → $localBin)..."
        try {
            Install-ChezmoiFromGetChezmoiIo -BinDir $localBin
        } catch {
            die "chezmoi install failed: $_ — see https://www.chezmoi.io/install/"
        }
        Refresh-MartyPathEnv
        if ($env:Path -notlike "*${localBin}*") {
            $env:Path = $localBin + [IO.Path]::PathSeparator + $env:Path
        }
    }
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
Ensure-MartyPowerShellProfiles
ok "Dotfiles applied"

# Optional Starship if enabled in chezmoi data.
# Starship behavior is configured by ~/.config/starship.toml; profile init is managed by chezmoi templates.
try {
    $dataJson = chezmoi data --format json 2>$null | ConvertFrom-Json
    if ($dataJson.ps -and $dataJson.ps.starship -eq $true) {
        if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
            step "Installing Starship (enabled in preferences)..."
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                winget install --id Starship.Starship -e --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
                Refresh-MartyPathEnv
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
Write-Host "  Reload profiles (each host has its own path):"
Write-Host "      pwsh:             . `"$(Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1')`""
Write-Host "      Windows PS 5.1:   . `"$(Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1')`""
Write-Host "      (or in that host: . `"`$PROFILE`")"
Write-Host ""
Write-Host "  Commands:  dotup   dotupload   dotps show   dotps wizard   undotps   dottools"
Write-Host ""
