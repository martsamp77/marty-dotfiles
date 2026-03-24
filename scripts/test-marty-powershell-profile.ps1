# Self-test rendered profile logging (run: powershell -NoProfile -File scripts\test-marty-powershell-profile.ps1)
# Requires chezmoi on PATH; uses repo as --source for execute-template.
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$tmpl = Join-Path $repo '.chezmoitemplates\marty-powershell.ps1.tmpl'
$out = Join-Path $env:TEMP ('marty-profile-rendered-{0}.ps1' -f [Guid]::NewGuid().ToString('n'))
& chezmoi execute-template -f $tmpl -S $repo -o $out
if (-not (Test-Path -LiteralPath $out)) { throw "render failed: $out" }

function Run-Case {
    param([string]$Name, [hashtable]$Env = @{})
    Write-Host "`n=== $Name ===" -ForegroundColor Cyan
    # Set env inside the child only so the parent session is not left at MARTY_DOTFILES_LOG=debug (that broke the on-demand case).
    $op = $out.Replace("'", "''")
    $prefix = 'Remove-Item env:MARTY_DOTFILES_LOG -ErrorAction SilentlyContinue; Remove-Item env:MARTY_DOTFILES_DIAG_QUIET -ErrorAction SilentlyContinue; '
    foreach ($k in $Env.Keys) {
        $v = ([string]$Env[$k]).Replace("'", "''")
        $prefix += "`$env:$k='$v'; "
    }
    $ps = $prefix + "`$global:PROFILE = '$op'; . '$op'"
    $arg = @('-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command', $ps)
    $p = Start-Process -FilePath 'powershell.exe' -ArgumentList $arg -Wait -NoNewWindow -PassThru -RedirectStandardOutput (Join-Path $env:TEMP 'mpt-out.txt') -RedirectStandardError (Join-Path $env:TEMP 'mpt-err.txt')
    Get-Content (Join-Path $env:TEMP 'mpt-out.txt') -ErrorAction SilentlyContinue
    $e = Get-Content (Join-Path $env:TEMP 'mpt-err.txt') -Raw -ErrorAction SilentlyContinue
    if ($e) { Write-Host $e -ForegroundColor Yellow }
    if ($p.ExitCode -ne 0) { Write-Host "exit $($p.ExitCode)" -ForegroundColor Red }
}

Remove-Item env:MARTY_DOTFILES_LOG -ErrorAction SilentlyContinue
Remove-Item env:MARTY_DOTFILES_DIAG_QUIET -ErrorAction SilentlyContinue
Run-Case 'minimal (default)' @{}
Run-Case 'warn' @{ MARTY_DOTFILES_LOG = 'warn' }
Run-Case 'debug' @{ MARTY_DOTFILES_LOG = 'debug' }

$op = $out.Replace("'", "''")
$ps2 = 'Remove-Item env:MARTY_DOTFILES_LOG -ErrorAction SilentlyContinue; Remove-Item env:MARTY_DOTFILES_DIAG_QUIET -ErrorAction SilentlyContinue; ' +
    "`$global:PROFILE = '$op'; . '$op'; Show-MartyDotfilesDiag warn"
Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command', $ps2) -Wait -NoNewWindow -RedirectStandardOutput (Join-Path $env:TEMP 'mpt-diag.txt')
Write-Host "`n=== Show-MartyDotfilesDiag warn (after minimal load) ===" -ForegroundColor Cyan
$diag = Get-Content (Join-Path $env:TEMP 'mpt-diag.txt') -ErrorAction SilentlyContinue
$diag | Select-Object -First 25
if ($diag -match 'dotfiles \| warn') {
    Write-Host '[ok] on-demand warn banner found' -ForegroundColor Green
} else {
    Write-Host '[fail] expected dotfiles | warn in child output' -ForegroundColor Red
}

Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue
Write-Host "`nDone." -ForegroundColor Green
