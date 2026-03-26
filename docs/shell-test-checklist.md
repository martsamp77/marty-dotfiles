# Shell bootstrap verification (zsh + PowerShell)

Use this when changing dotfiles that affect **zsh** or **Windows PowerShell**. Treat every checklist run as **incomplete** until all rows pass.

## For maintainers and AI agents

1. **Validate in both shells** when install scripts or shared behavior changes.
2. **Full cycle per shell**: teardown → install → test.
3. **Open a new terminal** after install (or `exec zsh` / `. $PROFILE`) so you are not testing a stale environment.
4. **Keep this document updated** when you add commands or install steps.

---

## 1. Teardown and install

### zsh (from repo clone)

| Step | Command | Expected |
|------|---------|----------|
| Fresh apply | `chezmoi apply` (or `./install.sh`) | Completes without fatal errors |
| New shell | `exec zsh -l` or new tab | Prompt and `PATH` sane |

### PowerShell (Windows)

| Step | Command | Expected |
|------|---------|----------|
| Teardown | `Remove-Item $PROFILE -ErrorAction SilentlyContinue` | Profile removed (or let install overwrite) |
| Install | `.\windows\install.ps1` from repo root | Both profile paths written; `~/.marty-dotfiles.json` created |
| Reload | `. $PROFILE` (or open a new window) | No errors |
| Verify | `Get-Command dotsync` | Returns alias to `Sync-MartyProfile` |

Repeat in **pwsh** and **Windows PowerShell 5.1** if behavior differs.

---

## 2. PowerShell — profile basics

| Test | Command | Expected |
|------|---------|----------|
| `.local\bin` on PATH | `$env:Path -split ';' \| Where-Object { $_ -match '\.local\\bin' }` | Returns the path if `~\.local\bin` exists |
| `dotsync` alias | `Get-Command dotsync` | `Alias` → `Sync-MartyProfile` |
| `dotsync` runs | `dotsync` | git pull, copies profile to both locations; no errors |

---

## 3. zsh — frequent commands

| Test | Command | Expected |
|------|---------|----------|
| Listing | `ls` | Color output; no errors |
| Long listing | `ls -la` | Lists including hidden |
| cd | `cd` / `cd -` | Expected directories |
| Git | `git status` | Works in repo |
| chezmoi | `chezmoi status` | OK |
| Starship | Prompt renders; `starship explain` if installed | No crash |
| dotdiag | `dotdiag` | Prints warn-level diagnostics |

---

## 4. Cross-cutting

| Test | Expected |
|------|----------|
| `chezmoi apply` after editing templates | Succeeds |
| No secrets in test output | Do not paste tokens |

---

## 5. Completion criteria

- [ ] zsh: install/apply → section 3 pass
- [ ] PowerShell 5.1: teardown → `install.ps1` → sections 1–2 pass
- [ ] pwsh: same as 5.1

**Iterate** until all boxes are checked.
