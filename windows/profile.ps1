# Marty's PowerShell profile — managed via marty-dotfiles
# Customizations: windows/marty-profile.ps1 (in repo). Sync: dotsync

$configFile = Join-Path $env:USERPROFILE '.marty-dotfiles.json'
if (-not (Test-Path -LiteralPath $configFile)) {
    Write-Warning "Marty dotfiles not configured. Run windows\install.ps1 from the repo."
} else {
    $repoPath = (Get-Content $configFile -Raw | ConvertFrom-Json).repoPath
    $custom = Join-Path $repoPath 'windows\marty-profile.ps1'
    if (-not (Test-Path -LiteralPath $repoPath)) {
        Write-Warning "Repo not found at '$repoPath'. Update $configFile or re-run install.ps1."
    } elseif (-not (Test-Path -LiteralPath $custom)) {
        Write-Warning "Expected $custom — run git pull in the repo or check repo path."
    } else {
        . $custom
    }
}

# ── Sync profile from repo ────────────────────────────────────────────────────
function Sync-MartyProfile {
    $configFile = Join-Path $env:USERPROFILE '.marty-dotfiles.json'
    if (-not (Test-Path $configFile)) {
        Write-Error "Repo config not found at $configFile. Run windows\install.ps1 first."
        return
    }
    $repoPath = (Get-Content $configFile -Raw | ConvertFrom-Json).repoPath
    if (-not (Test-Path $repoPath)) {
        Write-Error "Repo not found at '$repoPath'. Update $configFile or re-run install.ps1."
        return
    }

    # Pull latest changes
    Push-Location $repoPath
    git pull
    Pop-Location

    # Copy profile to both PowerShell locations
    $source = Join-Path $repoPath 'windows\profile.ps1'

    $targets = @(
        $PROFILE,
        (Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1')
    )
    foreach ($target in $targets) {
        New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
        Copy-Item $source $target -Force
        Write-Host "Synced -> $target"
    }

    Write-Host ""
    Write-Host "Reload with: . `$PROFILE"
}
Set-Alias dotsync Sync-MartyProfile
