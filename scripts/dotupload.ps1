#Requires -Version 5.1
<#
.SYNOPSIS
    Copy Cursor/VS Code User settings (and optional rules, extensions, snippets) into the chezmoi source tree, then git commit and push.

.DESCRIPTION
    Reverse of run_after_apply-cursor: pulls IDE files into cursor/ under chezmoi source, stages all changes,
    commits with your message, and pushes. Requires a descriptive commit message (12+ characters; vague one-word
    messages are rejected). Keybindings are not uploaded (they are regenerated on chezmoi apply).

    Optional --rules runs scripts/cursor-export-rules.sh via bash when available (Git for Windows).
    Pre-commit may require CHANGELOG.md when cursor/ or scripts/ change; see README.

.PARAMETER Rules
    Run cursor-export-rules.sh after syncing settings.

.PARAMETER Extensions
    Overwrite cursor/extensions.txt using: cursor --list-extensions

.PARAMETER Snippets
    Copy *.code-snippets from Cursor User/snippets to cursor/snippets/

.EXAMPLE
    dotupload "Sync Cursor editor font, minimap, and Python formatter settings"

.EXAMPLE
    dotupload --rules "Export Cursor user rules and sync workspace trust defaults"
#>
[CmdletBinding()]
param(
    [switch]$Rules,
    [switch]$Extensions,
    [switch]$Snippets,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-MartyChezmoiSourcePath {
    try {
        $out = & chezmoi source-path 2>$null
        if ($out) { return $out.Trim() }
    } catch {}
    return $null
}

function Show-DotuploadUsage {
    Write-Host @'

dotupload.ps1 - sync Cursor/VS Code to chezmoi source, git commit, push

  dotupload "Descriptive commit message (12+ characters)"
  dotupload -Rules "Export rules and sync editor settings"
  dotupload -Extensions "Refresh extension list from Cursor"
  dotupload -Snippets "Copy snippet files into the repo"

Flags: -Rules -Extensions -Snippets (combine as needed)

'@
}

$argList = [System.Collections.Generic.List[string]]::new()
if ($null -ne $RemainingArgs) {
    foreach ($a in $RemainingArgs) { $argList.Add([string]$a) | Out-Null }
}

if ($argList.Count -eq 0 -or ($argList.Count -eq 1 -and $argList[0] -in @('-h', '--help', '/?'))) {
    Show-DotuploadUsage
    if ($argList.Count -eq 0) { exit 1 }
    exit 0
}

$doRules = $Rules.IsPresent
$doExtensions = $Extensions.IsPresent
$doSnippets = $Snippets.IsPresent
$msgParts = [System.Collections.Generic.List[string]]::new()

$i = 0
while ($i -lt $argList.Count) {
    $t = $argList[$i]
    if ($t -eq '--rules') { $doRules = $true; $i++; continue }
    if ($t -eq '--extensions') { $doExtensions = $true; $i++; continue }
    if ($t -eq '--snippets') { $doSnippets = $true; $i++; continue }
    if ($t -eq '-h' -or $t -eq '--help') { Show-DotuploadUsage; exit 0 }
    while ($i -lt $argList.Count) {
        $msgParts.Add($argList[$i]) | Out-Null
        $i++
    }
    break
}

$commitMsg = ($msgParts -join ' ').Trim()

if ([string]::IsNullOrWhiteSpace($commitMsg)) {
    Write-Error 'dotupload: missing commit message. Example: dotupload "Sync Cursor theme and tab settings"'
    exit 1
}
if ($commitMsg.Length -lt 12) {
    Write-Error 'dotupload: commit message must be at least 12 characters — describe what changed.'
    exit 1
}
$lower = $commitMsg.ToLowerInvariant()
$vague = @('wip', 'update', 'changes', 'fix', 'test', 'sync', 'stuff', 'asdf', 'commit', 'msg')
if ($vague -contains $lower) {
    Write-Error 'dotupload: commit message is too vague; use a specific sentence.'
    exit 1
}

$sourceDir = Get-MartyChezmoiSourcePath
if (-not $sourceDir -or -not (Test-Path -LiteralPath $sourceDir -PathType Container)) {
    Write-Error 'dotupload: chezmoi source-path failed — is chezmoi installed and initialized?'
    exit 1
}

$cursorDir = Join-Path $env:APPDATA 'Cursor\User'
$codeDir = Join-Path $env:APPDATA 'Code\User'
$settingsDest = Join-Path $sourceDir 'cursor\settings.json'
$null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $settingsDest)

$copied = $false
$cursorSettings = Join-Path $cursorDir 'settings.json'
$codeSettings = Join-Path $codeDir 'settings.json'

if (Test-Path -LiteralPath $cursorSettings) {
    Copy-Item -LiteralPath $cursorSettings -Destination $settingsDest -Force
    Write-Host 'dotupload: copied Cursor → cursor/settings.json'
    $copied = $true
}
elseif (Test-Path -LiteralPath $codeSettings) {
    Copy-Item -LiteralPath $codeSettings -Destination $settingsDest -Force
    Write-Host 'dotupload: copied VS Code → cursor/settings.json (Cursor settings not found)'
    $copied = $true
}
else {
    Write-Warning 'dotupload: no settings.json under Cursor or VS Code User — skipped'
}

if ($doSnippets) {
    $snipSrc = Join-Path $cursorDir 'snippets'
    $snipDest = Join-Path $sourceDir 'cursor\snippets'
    if (-not (Test-Path -LiteralPath $snipSrc -PathType Container)) {
        Write-Warning 'dotupload: --snippets: Cursor snippets folder missing'
    }
    else {
        $files = Get-ChildItem -LiteralPath $snipSrc -Filter '*.code-snippets' -File -ErrorAction SilentlyContinue
        if (-not $files) {
            Write-Host 'dotupload: --snippets: no *.code-snippets found'
        }
        else {
            $null = New-Item -ItemType Directory -Force -Path $snipDest
            $files | Copy-Item -Destination $snipDest -Force
            Write-Host "dotupload: copied $($files.Count) snippet file(s) → cursor/snippets/"
        }
    }
}

if ($doRules) {
    $exportScript = Join-Path $sourceDir 'scripts\cursor-export-rules.sh'
    if (-not (Test-Path -LiteralPath $exportScript)) {
        Write-Error "dotupload: not found: $exportScript"
        exit 1
    }
    $bash = Get-Command bash -ErrorAction SilentlyContinue
    if (-not $bash) {
        Write-Error 'dotupload: --rules requires Git Bash (bash.exe) to run cursor-export-rules.sh'
        exit 1
    }
    Push-Location $sourceDir
    try {
        & bash.exe './scripts/cursor-export-rules.sh'
        if ($LASTEXITCODE -ne 0) {
            Write-Error 'dotupload: cursor-export-rules.sh failed'
            exit $LASTEXITCODE
        }
    }
    finally {
        Pop-Location
    }
}

if ($doExtensions) {
    $cursorCli = Get-Command cursor -ErrorAction SilentlyContinue
    if (-not $cursorCli) {
        Write-Error 'dotupload: --extensions requires cursor CLI on PATH'
        exit 1
    }
    $extPath = Join-Path $sourceDir 'cursor\extensions.txt'
    & cursor --list-extensions | Set-Content -LiteralPath $extPath -Encoding utf8
    Write-Host 'dotupload: wrote cursor/extensions.txt from cursor --list-extensions'
}

$diffOut = & chezmoi diff 2>$null
if ($diffOut) {
    Write-Host ''
    Write-Host 'dotupload: note — chezmoi diff shows source vs home differences (not merged by this script).'
    Write-Host ''
}

Set-Location -LiteralPath $sourceDir
$inGit = git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "dotupload: not a git repository: $sourceDir"
    exit 1
}

git add -A
$staged = @(git diff --cached --name-only | ForEach-Object { $_.TrimEnd("`r") } | Where-Object { $_ })
if ($staged.Count -eq 0) {
    Write-Host 'dotupload: nothing to commit (working tree clean after sync).'
    exit 0
}

$needsChangelog = $false
foreach ($line in $staged) {
    if ($line -match '^(cursor/|scripts/|\.chezmoi/|dot_|run_after_apply|Documents/|install|VERSION)(/|$)') {
        $needsChangelog = $true
        break
    }
}
$hasChangelog = $staged -contains 'CHANGELOG.md'
if ($needsChangelog -and -not $hasChangelog) {
    Write-Host 'dotupload: reminder — pre-commit may require CHANGELOG.md staged for these paths.'
    Write-Host '          Add [Unreleased] notes or use SKIP_CHANGELOG=1 when appropriate.'
    Write-Host ''
}

git commit -m $commitMsg
if ($LASTEXITCODE -ne 0) {
    Write-Error 'dotupload: git commit failed (see hook output above).'
    exit $LASTEXITCODE
}

git push
if ($LASTEXITCODE -ne 0) {
    Write-Error 'dotupload: git push failed.'
    exit $LASTEXITCODE
}
Write-Host 'dotupload: pushed to remote.'
