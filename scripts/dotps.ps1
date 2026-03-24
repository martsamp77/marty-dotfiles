#Requires -Version 5.1
# ══════════════════════════════════════════════════════════════════════════════
#  dotps — manage PowerShell dotfile preferences ([data.ps] in chezmoi.toml)
#
#  Usage: dotps show | dotps wizard | dotps off | dotps reset
#  Starship toggle subcommands are intentionally disabled in PowerShell.
#  (Usually invoked via the dotps function in $PROFILE.)
# ══════════════════════════════════════════════════════════════════════════════

param(
    [Parameter(Position = 0)]
    [ValidateSet('show', 'wizard', 'off', 'reset', 'starship-on', 'starship-off', 'starshipon', 'starshipoff')]
    [string] $Command = 'show'
)

$ErrorActionPreference = 'Stop'

function Get-ChezmoiConfigPath {
    Join-Path $env:USERPROFILE '.config\chezmoi\chezmoi.toml'
}

function Get-LinesFromToml {
    param([string] $Path)
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    return Get-Content -LiteralPath $Path
}

function Save-LinesToToml {
    param([string] $Path, [string[]] $Lines)
    $dir = [System.IO.Path]::GetDirectoryName($Path)
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value $Lines -Encoding utf8
}

function Replace-DataPsBlock {
    param(
        [string[]] $AllLines,
        [bool] $Starship,
        [string] $Prediction,
        [string] $PredictionView
    )
    $newBlock = @(
        '[data.ps]',
        "starship = $($Starship.ToString().ToLowerInvariant())",
        "prediction = `"$Prediction`"",
        "predictionview = `"$PredictionView`""
    )
    $start = -1
    for ($i = 0; $i -lt $AllLines.Count; $i++) {
        if ($AllLines[$i].Trim() -eq '[data.ps]') { $start = $i; break }
    }
    if ($start -lt 0) {
        $tail = $AllLines | Where-Object { $_ -ne $null }
        if ($tail.Count -eq 0) { return $newBlock }
        return @($tail + '' + $newBlock)
    }
    $end = $AllLines.Count
    for ($j = $start + 1; $j -lt $AllLines.Count; $j++) {
        $t = $AllLines[$j].Trim()
        if ($t.Length -gt 0 -and $t.StartsWith('[')) {
            $end = $j
            break
        }
    }
    $before = @()
    if ($start -gt 0) { $before = $AllLines[0..($start - 1)] }
    $after = @()
    if ($end -lt $AllLines.Count) { $after = $AllLines[$end..($AllLines.Count - 1)] }
    return @($before + $newBlock + $after)
}

function Remove-DataPsBlock {
    param([string[]] $AllLines)
    $start = -1
    for ($i = 0; $i -lt $AllLines.Count; $i++) {
        if ($AllLines[$i].Trim() -eq '[data.ps]') { $start = $i; break }
    }
    if ($start -lt 0) { return $AllLines }
    $end = $AllLines.Count
    for ($j = $start + 1; $j -lt $AllLines.Count; $j++) {
        $t = $AllLines[$j].Trim()
        if ($t.Length -gt 0 -and $t.StartsWith('[')) {
            $end = $j
            break
        }
    }
    $before = @()
    if ($start -gt 0) { $before = $AllLines[0..($start - 1)] }
    $after = @()
    if ($end -lt $AllLines.Count) { $after = $AllLines[$end..($AllLines.Count - 1)] }
    return @($before + $after)
}

function Read-CurrentPsData {
    $path = Get-ChezmoiConfigPath
    if (-not (Test-Path -LiteralPath $path)) {
        return @{
            Starship = $false
            Prediction = 'none'
            PredictionView = 'inline'
        }
    }
    $text = Get-Content -LiteralPath $path -Raw
    $starship = $false
    if ($text -match '(?m)^\s*starship\s*=\s*(true|false)\s*$') {
        $starship = ($Matches[1] -eq 'true')
    }
    $prediction = 'none'
    if ($text -match '(?m)^\s*prediction\s*=\s*"([^"]+)"\s*$') {
        $prediction = $Matches[1]
    }
    $view = 'inline'
    if ($text -match '(?m)^\s*predictionview\s*=\s*"([^"]+)"\s*$') {
        $view = $Matches[1]
    }
    return @{
        Starship = $starship
        Prediction = $prediction
        PredictionView = $view
    }
}

switch ($Command) {
    'show' {
        Write-Host "`n  Current [data.ps] (from chezmoi data):" -ForegroundColor Cyan
        try {
            $json = chezmoi data --format json 2>$null
            if (-not $json) { throw 'empty' }
            $d = $json | ConvertFrom-Json
            if ($d.ps) {
                $d.ps | Format-List | Out-String | Write-Host
            } else {
                Write-Host '  (no ps key — run: chezmoi init  or  dotps wizard)' -ForegroundColor Yellow
            }
        } catch {
            Write-Host '  chezmoi data failed — is chezmoi initialized?' -ForegroundColor Red
        }
    }
    'wizard' {
        $cur = Read-CurrentPsData
        Write-Host "`n  dotps wizard — PowerShell dotfile preferences`n" -ForegroundColor Cyan
        $yn = Read-Host "  Use Starship prompt? (y/N) [$(if ($cur.Starship) { 'Y' } else { 'N' })]"
        if ([string]::IsNullOrWhiteSpace($yn)) { $st = $cur.Starship }
        else { $st = $yn -match '^[yY]' }

        Write-Host "`n  PSReadLine prediction: 1=none  2=history  3=history+plugin [default from current: $($cur.Prediction)]"
        $pc = Read-Host '  Choice (1-3)'
        $pred = switch ($pc) {
            '1' { 'none' }
            '2' { 'history' }
            '3' { 'historyandplugin' }
            default { $cur.Prediction }
        }

        Write-Host "`n  Prediction view: 1=inline  2=list [current: $($cur.PredictionView)]"
        $vc = Read-Host '  Choice (1-2)'
        $view = $cur.PredictionView
        if ($vc -eq '1') { $view = 'inline' }
        elseif ($vc -eq '2') { $view = 'list' }

        $path = Get-ChezmoiConfigPath
        $lines = Get-LinesFromToml $path
        $merged = Replace-DataPsBlock -AllLines $lines -Starship $st -Prediction $pred -PredictionView $view
        Save-LinesToToml -Path $path -Lines $merged
        Write-Host "`n  Saved $path" -ForegroundColor Green
        Write-Host '  Applying profile(s)...' -ForegroundColor Cyan
        try { chezmoi apply -v } catch { Write-Warning "chezmoi apply failed: $_" }
        Write-Host "`n  Reload:  . `$PROFILE`n" -ForegroundColor Green
    }
    'off' {
        $path = Get-ChezmoiConfigPath
        $lines = Get-LinesFromToml $path
        $merged = Replace-DataPsBlock -AllLines $lines -Starship $false -Prediction 'none' -PredictionView 'inline'
        Save-LinesToToml -Path $path -Lines $merged
        Write-Host '  [data.ps] set to minimal (Starship off, prediction none).' -ForegroundColor Green
        try { chezmoi apply -v } catch { Write-Warning "chezmoi apply failed: $_" }
        Write-Host '  Reload:  . $PROFILE' -ForegroundColor Green
    }
    'starship-on' {
        Write-Warning 'Starship sync toggles are disabled for PowerShell in this setup.'
        Write-Host '  No changes were written and chezmoi apply was not run.' -ForegroundColor Yellow
    }
    'starshipon' {
        Write-Warning 'Starship sync toggles are disabled for PowerShell in this setup.'
        Write-Host '  No changes were written and chezmoi apply was not run.' -ForegroundColor Yellow
    }
    'starship-off' {
        Write-Warning 'Starship sync toggles are disabled for PowerShell in this setup.'
        Write-Host '  No changes were written and chezmoi apply was not run.' -ForegroundColor Yellow
    }
    'starshipoff' {
        Write-Warning 'Starship sync toggles are disabled for PowerShell in this setup.'
        Write-Host '  No changes were written and chezmoi apply was not run.' -ForegroundColor Yellow
    }
    'reset' {
        $path = Get-ChezmoiConfigPath
        if (-not (Test-Path -LiteralPath $path)) {
            Write-Error "No chezmoi config at $path — run install-powershell.ps1 or chezmoi init first."
            exit 1
        }
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $bak = "$path.bak.$stamp"
        Copy-Item -LiteralPath $path -Destination $bak -Force
        Write-Host "  Backup: $bak" -ForegroundColor Yellow
        $lines = Get-LinesFromToml $path
        $trimmed = Remove-DataPsBlock -AllLines $lines
        Save-LinesToToml -Path $path -Lines $trimmed
        Write-Host '  Removed [data.ps]. Run chezmoi init to re-prompt (merge with your template).' -ForegroundColor Cyan
        Write-Host '    chezmoi init' -ForegroundColor White
    }
}
