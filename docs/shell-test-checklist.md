# Shell bootstrap verification (zsh + PowerShell)

Use this when changing dotfiles that affect **zsh** or **Windows PowerShell**. Treat every checklist run as **incomplete** until all rows pass; fix regressions and re-run from a clean state where practical.

## For maintainers and AI agents

1. **Always validate in both shells** when shared behavior or install scripts change: **zsh** (macOS/Linux/WSL) and **PowerShell** (Windows: **pwsh** and, when relevant, **Windows PowerShell 5.1**).
2. **Full cycle per shell**: run the **undo/teardown** path, then the **install/bootstrap** path, then the **tests** below.
3. **Record actual vs expected** when something fails; patch code or docs, then **re-run the full checklist** until green.
4. **Instantiate shells**: open a **new** terminal session after install (or `exec zsh` / `. $PROFILE`) so you are not testing a stale environment.
5. **Keep this document updated** when you add commands, switches, or install steps.

---

## 1. Teardown and install

### zsh (from repo clone)

| Step | Command | Expected |
|------|---------|----------|
| Undo / reset (if repo provides it) | Follow [README.md](../README.md) or project `install.sh` / manual removal of managed files | Shell starts without dotfile side effects |
| Fresh apply | `chezmoi apply` (or `./install.sh` as documented) | Completes without fatal errors |
| New shell | `exec zsh -l` or new tab | Prompt and `PATH` sane |

### PowerShell (Windows)

| Step | Command | Expected |
|------|---------|----------|
| Undo | `irm https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/undo-powershell.ps1 \| iex` (or local `.\undo-powershell.ps1`) | Completes; profiles reset per script output |
| Install | `irm https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install-powershell.ps1 \| iex` | No empty-`Path` / `Split-Path` errors; chezmoi init/apply completes |
| Reload | `chezmoi apply` then `. $PROFILE` | Helpers exist: `Get-Command starshipon, starshipoff, starshipupdate, dotps` |

Repeat in **pwsh** and **Windows PowerShell 5.1** if behavior differs (especially **parameter parsing** and **PSReadLine**).

---

## 2. PowerShell — `ls` / `dir` (custom wrapper)

The profile replaces **`ls`/`dir`** with a function that forwards to **`Get-ChildItem`** then color listing. **`gci` / `Get-ChildItem`** remain native.

| Test | Command | Expected |
|------|---------|----------|
| Basic listing | `ls` in a folder with files + dirs | Single column listing; **cyan** names for directories, **gray** for files; **DarkGray** metadata |
| Hidden short switch | `dir -h` and `ls -Hidden` | No “parameter not found”; hidden items included (via **`-Force`** internally) |
| Force | `ls -Force` | Same idea as native **Get-ChildItem -Force** |
| Name only | `ls -Name` | Native string names (no color table) |
| Recurse smoke | `ls -Recurse -Depth 1` (small tree) | Completes; output usable |
| Literal path | `ls -LiteralPath $env:USERPROFILE` | Lists user profile |
| Stock cmdlet | `gci` | Default PowerShell formatting (not the custom colors) |

---

## 3. PowerShell — `cd` and helpers

| Test | Command | Expected |
|------|---------|----------|
| cd + listing | `cd $env:USERPROFILE` then observe output | **Format-Wide** folder names under cwd |
| cd home | `cd` (no args) | Goes to `$HOME` and lists |
| dotps | `dotps show` | Prints `[data.ps]` / chezmoi data or clear error |
| Starship off | `starshipoff` | Updates config, apply, reload; **no** “parameter set” error (uses **`dotps starshipon`** / **`starshipoff`** without splatting hyphen tokens into script) |
| Starship on | `starshipon` | Starship enabled after reload |
| dotps subcommand | `dotps starshipoff` | Same as above |
| chezmoi scripts | `dots` (if SSH/path ok) | Lands in source tree |

---

## 4. zsh — frequent commands (adjust to your `dot_zshrc`)

| Test | Command | Expected |
|------|---------|----------|
| Listing | `ls` | Your configured aliases/functions behave; no errors |
| Long listing | `ls -la` | Lists incl. hidden |
| cd | `cd` / `cd -` | Expected dirs |
| Git | `git status` | Works in repo |
| Chezmoi | `chezmoi status` or documented alias | OK |
| Starship | Prompt reflects config; `starship explain` if installed | No crash |

---

## 5. Cross-cutting

| Test | Expected |
|------|----------|
| **chezmoi apply** after editing templates | Succeeds |
| **No secrets** in test output | Do not paste tokens |
| **README** Quick install one-liners | Still valid URLs |

---

## 6. Completion criteria

- [ ] zsh: undo (or clean) → install/apply → section 4 pass  
- [ ] PowerShell 5.1: undo → install → sections 2–3 pass  
- [ ] pwsh: same as 5.1 if you rely on pwsh daily  
- [ ] `dir -h` and `starshipoff` / `starshipon` verified after changes to profile or `dotps.ps1`  

**Iterate** until all boxes are checked.
