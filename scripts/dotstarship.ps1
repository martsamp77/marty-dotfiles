#Requires -Version 5.1
# ══════════════════════════════════════════════════════════════════════════════
#  dotstarship.ps1 — update Starship to latest release
#
#  Profile:  starshipupdate
#  Manual:   .\scripts\dotstarship.ps1 update
#
#  Uses https://starship.rs/install.ps1 (fetches the Windows binary from GitHub).
#  If winget is available, runs  winget upgrade Starship.Starship  first.
# ══════════════════════════════════════════════════════════════════════════════

param(
    [Parameter(Position = 0)]
    [ValidateSet('update')]
    [string] $Command = 'update'
)

$ErrorActionPreference = 'Stop'

function Refresh-MartyPathEnv {
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [System.Environment]::GetEnvironmentVariable('Path', 'User')
}

switch ($Command) {
    'update' {
        Write-Host ''
        Write-Host '  starshipupdate' -ForegroundColor Cyan
        Write-Host ''

        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host '  winget upgrade Starship.Starship...' -ForegroundColor DarkGray
            winget upgrade --id Starship.Starship -e --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
            Refresh-MartyPathEnv
        }

        Write-Host '  https://starship.rs/install.ps1 (GitHub release)...' -ForegroundColor DarkGray
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        } catch {}
        $installPs1 = Invoke-RestMethod -Uri 'https://starship.rs/install.ps1' -UseBasicParsing
        Invoke-Expression $installPs1
        Refresh-MartyPathEnv

        if (Get-Command starship -ErrorAction SilentlyContinue) {
            $ver = & starship --version 2>$null
            Write-Host "  OK: $ver" -ForegroundColor Green
        } else {
            Write-Warning '  starship not on PATH — open a new terminal or fix PATH.'
        }
    }
}
