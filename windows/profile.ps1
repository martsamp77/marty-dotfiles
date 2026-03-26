# Marty's PowerShell profile — managed via marty-dotfiles
# Edit in repo at windows/profile.ps1, then run: dotsync

# ── PATH: prepend .local\bin ──────────────────────────────────────────────────
$__martyLocalBin = Join-Path $env:USERPROFILE '.local\bin'
if (Test-Path -LiteralPath $__martyLocalBin) {
    $env:Path = $__martyLocalBin + [IO.Path]::PathSeparator + $env:Path
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
