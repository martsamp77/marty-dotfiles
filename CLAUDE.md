# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles split into two independent systems:

- **Linux/Mac** — managed by [chezmoi](https://www.chezmoi.io/). Source files at the repo root deploy to `$HOME` via `chezmoi apply`.
- **Windows/PowerShell** — simple copy-based sync. `windows/profile.ps1` is copied to both PowerShell profile locations by `windows/install.ps1`; it loads `windows/marty-profile.ps1` from the repo clone. No chezmoi on Windows.

## Linux / Mac

### Commands

```bash
chezmoi apply          # Deploy dotfiles to $HOME
chezmoi diff           # Preview what would change
chezmoi apply --dry-run

# Shell aliases (after dotfiles are applied)
dotapply    # chezmoi apply -v
dotdiff     # chezmoi diff
dotedit     # chezmoi edit
dots        # cd to chezmoi source dir
dottools    # upgrade tools (scripts/dottools.sh)
dotdiag     # startup diagnostics
```

### Bootstrap (first install)
```bash
bash install.sh
# or:
bash <(curl -fsLS https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install.sh)
```

### Architecture

**chezmoi naming conventions:**
- `dot_*` → `.` prefix in `$HOME` (e.g. `dot_zshrc.tmpl` → `~/.zshrc`)
- `*.tmpl` → processed as Go templates before deployment
- `dot_config/` → `~/.config/`

**Key source files:**
| Source | Deployed to |
|---|---|
| `dot_zshrc.tmpl` | `~/.zshrc` |
| `dot_config/starship.toml` | `~/.config/starship.toml` |

**External plugins** (`.chezmoiexternal.toml`): Pure, zsh-autosuggestions, zsh-syntax-highlighting — fetched as git repos, refreshed every 168h.

**`.chezmoiignore.tmpl`**: Excludes `windows/`, `scripts/`, `docs/`, `CLAUDE.md`, and repo metadata from `$HOME` deployment.

**Platform conditionals in templates:**
```
{{- if eq .chezmoi.os "darwin" -}} ... macOS ... {{- end }}
{{- if eq .chezmoi.os "linux" -}} ... Linux/WSL ... {{- end }}
```

---

## Windows / PowerShell

No chezmoi, no Starship, no templates.

### File layout
```
windows/
  marty-profile.ps1   # Edit here — custom functions, PATH, aliases
  profile.ps1         # Bootstrap: dot-sources marty-profile.ps1, defines dotsync
  install.ps1         # First-time setup: copies profile.ps1, saves repo path
  tools.ps1           # winget upgrades (PowerShell, Git)
```

### First-time setup
```powershell
.\windows\install.ps1
```
Copies `windows/profile.ps1` to both profile locations and saves repo path to `~/.marty-dotfiles.json`. The deployed profile loads `marty-profile.ps1` from the repo at runtime.

### Day-to-day sync
```powershell
dotsync    # git pull in repo, then re-copies profile.ps1 to both locations
```
After editing `marty-profile.ps1`, `dotsync` pulls changes; reload with `. $PROFILE` (or open a new shell).

---

## Cursor and memory templates (for other projects)

This repository also holds **copy-out templates** at the repo root (not used as Cursor’s active `.cursor` in app repos until copied):

| Folder | Use |
|--------|-----|
| `.cursor-37m-template/` | Copy contents into a new **37Metrics / personal** app repo as `.cursor/`. |
| `.memory-bank-37m-template/` | Copy into the app repo as `.memory-bank/`. |
| `.cursor-md-template/` | Copy into a **Molecular Designs / work** app repo as `.cursor/`. |
| `.memory-bank-md-template/` | Copy into the app repo as `.memory-bank/`. |

**This repo’s active AI context** while you edit dotfiles here lives in [`.cursor/`](.cursor/) and [`.memory-bank/`](.memory-bank/) (minimal, repo-specific). Do not confuse with the templates.

**New app checklist:** run your stack’s official scaffold (`npm create vite@latest`, `poetry new`, etc.) → copy the chosen template pair → rename/merge into `.cursor` and `.memory-bank` → fill `AGENTS.md` and memory-bank stubs.

---

## Versioning

Three surfaces must stay in sync:
1. **`VERSION`** file
2. **`dot_zshrc.tmpl`**: `export DOTFILES_VERSION="x.y.z"`
3. **`CHANGELOG.md`**: matching `## [x.y.z] — YYYY-MM-DD` entry
