# Marty's PowerShell customizations — edit this file, then run: dotsync
# Loaded by windows/profile.ps1 from the repo clone (see ~/.marty-dotfiles.json).

$__martyLocalBin = Join-Path $env:USERPROFILE '.local\bin'
if (Test-Path -LiteralPath $__martyLocalBin) {
    $env:Path = $__martyLocalBin + [IO.Path]::PathSeparator + $env:Path
}

function npp  { notepad++ @args }

function Get-CCProjects {
    $path = "$HOME\.claude\projects.json"
    if (-not (Test-Path $path)) {
        Write-Host "  No projects file found at $path" -ForegroundColor Red
        return $null
    }
    return Get-Content $path | ConvertFrom-Json -AsHashtable
}

function Select-Project {
    $projects = Get-CCProjects
    if (-not $projects) { return $null }

    $keys = $projects.Keys | Sort-Object
    $selected = 0

    Write-Host ""
    Write-Host "  Select a project:" -ForegroundColor Yellow
    Write-Host "  (Use arrow keys, press Enter to confirm)" -ForegroundColor DarkGray
    Write-Host ""

    $top = [Console]::CursorTop

    while ($true) {
        [Console]::SetCursorPosition(0, $top)
        for ($i = 0; $i -lt $keys.Count; $i++) {
            if ($i -eq $selected) {
                Write-Host "  > $($keys[$i])".PadRight($Host.UI.RawUI.WindowSize.Width) -ForegroundColor Cyan
            } else {
                Write-Host "    $($keys[$i])".PadRight($Host.UI.RawUI.WindowSize.Width) -ForegroundColor DarkGray
            }
        }
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "UpArrow"   { if ($selected -gt 0) { $selected-- } }
            "DownArrow" { if ($selected -lt ($keys.Count - 1)) { $selected++ } }
            "Enter"     { Write-Host ""; return @{ Name = $keys[$selected]; Path = $projects[$keys[$selected]] } }
            "Escape"    { Write-Host ""; return $null }
        }
    }
}

function Invoke-CCLaunch {
    param([string]$Project, [switch]$Resume, [string[]]$PassArgs)

    if ($Project) {
        $projects = Get-CCProjects
        if (-not $projects -or -not $projects[$Project]) {
            Write-Host "  Unknown project: '$Project'" -ForegroundColor Red
            Write-Host "  Edit $HOME\.claude\projects.json to manage projects." -ForegroundColor DarkGray
            return
        }
        Set-Location $projects[$Project]
    }

    Clear-Host
    $env:LINES   = $Host.UI.RawUI.WindowSize.Height
    $env:COLUMNS = $Host.UI.RawUI.WindowSize.Width
    $timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm"
    $cwd         = (Get-Location).Path
    $tag         = if ($Resume) { " (resumed)" } else { "" }
    Add-Content "$HOME\.claude\session-log.txt" "$timestamp | $cwd$tag"

    $flags = @("--dangerously-skip-permissions")
    if ($Resume) { $flags += "-c" }
    claude @flags @PassArgs

    Clear-Host
}

function cc {
    if ($args[0] -eq "help") {
        $projects = Get-CCProjects
        Write-Host ""
        Write-Host "  Claude Code Launcher" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  COMMANDS" -ForegroundColor Yellow
        Write-Host "  cc              Launch Claude Code in current directory"
        Write-Host "  ccr             Resume last session in current directory"
        Write-Host "  ccw [project]   Navigate to project and launch"
        Write-Host "  ccwr [project]  Navigate to project and resume last session"
        Write-Host "  cce             Edit projects.json in Notepad++"
        Write-Host ""
        Write-Host "  PROJECTS  (edit $HOME\.claude\projects.json to change)" -ForegroundColor Yellow
        if ($projects) {
            $projects.Keys | Sort-Object | ForEach-Object {
                Write-Host ("  {0,-15} {1}" -f $_, $projects[$_])
            }
        }
        Write-Host ""
        Write-Host "  LOGS" -ForegroundColor Yellow
        Write-Host "  Session log     $HOME\.claude\session-log.txt"
        Write-Host "  View log        Get-Content `"`$HOME\.claude\session-log.txt`""
        Write-Host ""
        return
    }
    Invoke-CCLaunch -PassArgs $args
}

function ccr  { Invoke-CCLaunch -Resume -PassArgs $args }

function ccw {
    param([string]$Project)
    if (-not $Project) { $result = Select-Project; if (-not $result) { return }; $Project = $result.Name }
    Invoke-CCLaunch -Project $Project -PassArgs $args
}

function ccwr {
    param([string]$Project)
    if (-not $Project) { $result = Select-Project; if (-not $result) { return }; $Project = $result.Name }
    Invoke-CCLaunch -Project $Project -Resume -PassArgs $args
}

function cce  { notepad++ "$HOME\.claude\projects.json" }
