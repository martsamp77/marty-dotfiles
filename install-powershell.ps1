#Requires -Version 5.1
[CmdletBinding()]
param(
    # Skip end-of-script pause (useful for automation/testing).
    [switch]$NoPause,
    # Pre-seed chezmoi PowerShell answers so first init is non-interactive.
    [switch]$NoPromptDefaults = $true,
    [bool]$StarshipEnabled = $true,
    [ValidateSet('none', 'history', 'historyandplugin')]
    [string]$PredictionSource = 'history',
    [ValidateSet('inline', 'list')]
    [string]$PredictionView = 'inline'
)

# ==============================================================================
#  install-powershell.ps1 - Bootstrap Marty's dotfiles on Windows (PowerShell)
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
# ==============================================================================

function step { param($msg) Write-Host "`n  " -NoNewline; Write-Host "> $msg" -ForegroundColor Cyan }
function ok   { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function warn { param($msg) Write-Host "  ! $msg" -ForegroundColor Yellow }
function die  { param($msg) Write-Host "  [X] $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "==============================================="
Write-Host "  Marty's Dotfiles - Windows (PowerShell) bootstrap"
Write-Host "==============================================="
Write-Host ""

$REPO_SSH = 'git@github.com:martsamp77/marty-dotfiles.git'
$REPO_HTTPS = 'https://github.com/martsamp77/marty-dotfiles.git'
# winget manifest id is lowercase (Twpayne.Chezmoi is invalid - exits -1978335212)
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

function Ensure-MartyChezmoiWindowsDefaults {
    param(
        [bool]$Starship,
        [string]$Prediction,
        [string]$PredictionViewStyle
    )
    $cfgDir = Join-Path $env:USERPROFILE '.config\chezmoi'
    $cfgPath = Join-Path $cfgDir 'chezmoi.toml'
    if (-not (Test-Path -LiteralPath $cfgDir)) {
        New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null
    }
    $lines = @()
    if (Test-Path -LiteralPath $cfgPath) {
        $lines = Get-Content -LiteralPath $cfgPath
    }
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '[data.ps]') { $start = $i; break }
    }
    $newBlock = @(
        '[data.ps]',
        "starship = $($Starship.ToString().ToLowerInvariant())",
        "prediction = `"$Prediction`"",
        "predictionview = `"$PredictionViewStyle`""
    )
    if ($start -lt 0) {
        if ($lines.Count -gt 0 -and $lines[-1].Trim().Length -gt 0) {
            $lines += ''
        }
        $lines += $newBlock
    } else {
        $end = $lines.Count
        for ($j = $start + 1; $j -lt $lines.Count; $j++) {
            $t = $lines[$j].Trim()
            if ($t.Length -gt 0 -and $t.StartsWith('[')) {
                $end = $j
                break
            }
        }
        $before = @()
        if ($start -gt 0) { $before = $lines[0..($start - 1)] }
        $after = @()
        if ($end -lt $lines.Count) { $after = $lines[$end..($lines.Count - 1)] }
        $lines = @($before + $newBlock + $after)
    }
    Set-Content -LiteralPath $cfgPath -Value $lines -Encoding utf8
    ok "Pre-seeded chezmoi PowerShell defaults in $cfgPath"
}

function Sync-MartyLocalRepoToChezmoiSource {
    param(
        [string]$FromPath,
        [string]$ToPath
    )
    if (-not (Test-Path -LiteralPath $ToPath)) {
        New-Item -ItemType Directory -Path $ToPath -Force | Out-Null
    }
    Get-ChildItem -LiteralPath $FromPath -Force | Where-Object { $_.Name -ne '.git' } | ForEach-Object {
        $dest = Join-Path $ToPath $_.Name
        Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force
    }
}

function Get-MartyPowerShellProfileTargets {
    return @(
        (Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'),
        (Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1')
    )
}

# pwsh uses Documents\PowerShell\...; Windows PowerShell 5.1 uses Documents\WindowsPowerShell\...
# Always create parent dirs, then apply once so `. $PROFILE` works in either host after install.
function Ensure-MartyPowerShellProfiles {
    $targets = Get-MartyPowerShellProfileTargets
    foreach ($dest in $targets) {
        # Use .NET (not Split-Path -LiteralPath -Parent) - PS 5.1 parameter-set clash on some builds.
        $parent = [System.IO.Path]::GetDirectoryName($dest)
        if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
    }
    step "Applying chezmoi source..."
    chezmoi apply -v --exclude=scripts
    if (-not $?) {
        warn "chezmoi apply exited $LASTEXITCODE - run: chezmoi init && chezmoi apply -v"
    }
    foreach ($dest in $targets) {
        step "PowerShell profile: $dest"
        if (Test-Path -LiteralPath $dest) {
            ok "Profile file present"
        } else {
            warn "Profile still missing - try: chezmoi apply `"$dest`""
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
            warn "winget install chezmoi exited $LASTEXITCODE - trying get.chezmoi.io"
        }
        Refresh-MartyPathEnv
    } else {
        warn "winget not found - installing chezmoi via get.chezmoi.io"
    }
    if (-not (Get-Command chezmoi -ErrorAction SilentlyContinue)) {
        step "Installing chezmoi (get.chezmoi.io to $localBin)..."
        try {
            Install-ChezmoiFromGetChezmoiIo -BinDir $localBin
        } catch {
            die "chezmoi install failed: $_ - see https://www.chezmoi.io/install/"
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

$scriptRoot = Split-Path -Parent $PSCommandPath
$localRepoCandidate = $scriptRoot
$hasLocalChezmoi = Test-Path (Join-Path $localRepoCandidate '.chezmoi')
$useSsh = $false
if ($hasLocalChezmoi) {
    $REPO = $localRepoCandidate
    ok "Local dotfiles repo detected - using $REPO"
} else {
    step "Detecting GitHub access (SSH vs HTTPS)..."
    $sshTest = ssh -o ConnectTimeout=5 -T git@github.com 2>&1 | Out-String
    if ($sshTest -match 'Hi martsamp77') {
        $useSsh = $true
        ok "GitHub SSH OK - using $REPO_SSH"
    } else {
        warn 'GitHub SSH not available - using HTTPS (add a key later if you want)'
    }
    $REPO = if ($useSsh) { $REPO_SSH } else { $REPO_HTTPS }
}

if ($NoPromptDefaults) {
    step "Pre-seeding chezmoi PowerShell answers (non-interactive defaults)..."
    Ensure-MartyChezmoiWindowsDefaults -Starship $StarshipEnabled -Prediction $PredictionSource -PredictionViewStyle $PredictionView
}

step "Initializing chezmoi with non-interactive PowerShell preferences..."
$sourceDir = Join-Path $env:USERPROFILE '.local\share\chezmoi'
if (Test-Path (Join-Path $sourceDir '.git')) {
    warn "chezmoi source already exists - running update + apply"
    chezmoi git pull 2>$null
    if (-not $?) {
        warn "chezmoi git pull failed - continuing with apply"
    }
    chezmoi apply -v --exclude=scripts
} else {
    # Init first, then apply. This avoids aborting before we can report/fix apply issues.
    $boolValue = $StarshipEnabled.ToString().ToLowerInvariant()
    if ($hasLocalChezmoi) {
        step "Syncing local repo into chezmoi source directory..."
        Sync-MartyLocalRepoToChezmoiSource -FromPath $localRepoCandidate -ToPath $sourceDir
        & chezmoi apply -S $sourceDir -v --exclude=scripts
        if (-not $?) { warn "chezmoi apply failed after local source sync - continuing with profile checks" }
    } else {
        & chezmoi init $REPO --promptBool "ps.starship=$boolValue" --promptChoice "ps.prediction=$PredictionSource" --promptChoice "ps.predictionview=$PredictionView" --no-tty
        if (-not $?) { die "chezmoi init failed" }
        chezmoi apply -v --exclude=scripts
        if (-not $?) { warn "chezmoi apply failed after init - continuing with profile checks" }
    }
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
    warn "Could not read chezmoi data for Starship check - install Starship manually if wanted"
}

Write-Host ""
Write-Host "==============================================="
Write-Host "  All done!" -ForegroundColor Green
Write-Host "==============================================="
Write-Host ""
Write-Host "  Reload profiles (each host has its own path):"
$pwshProfile = Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
$ps51Profile = Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
Write-Host "      pwsh:             . '$pwshProfile'"
Write-Host "      Windows PS 5.1:   . '$ps51Profile'"
Write-Host "      (or in that host: . `$PROFILE)"
Write-Host ""
step "Reloading profile(s) in this session..."
foreach ($p in (Get-MartyPowerShellProfileTargets)) {
    if (Test-Path -LiteralPath $p) {
        try {
            . $p
            ok "Reloaded: $p"
        } catch {
            warn "Profile reload failed: $p - $_"
        }
    }
}

$candidateCommands = @('dotup', 'dotupload', 'dotps', 'undotps', 'dottools')
$available = @()
foreach ($c in $candidateCommands) {
    if (Get-Command $c -ErrorAction SilentlyContinue) {
        $available += $c
    }
}
if ($available.Count -gt 0) {
    Write-Host "  Available commands: $($available -join '   ')"
} else {
    warn "No dot* helper commands found in this session."
}
Write-Host ""
if (-not $NoPause) {
    Read-Host "Press Enter to continue"
}
