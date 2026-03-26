# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles split into two independent systems:

- **Linux/Mac** — managed by [chezmoi](https://www.chezmoi.io/). Source files at the repo root deploy to `$HOME` via `chezmoi apply`.
- **Windows/PowerShell** — simple copy-based sync. `windows/profile.ps1` is copied to both PowerShell profile locations by `windows/install.ps1`. No chezmoi on Windows.

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
  profile.ps1   # Source of truth — edit here
  install.ps1   # First-time setup: copies profile, saves repo path
  tools.ps1     # winget upgrades (PowerShell, Git)
```

### First-time setup
```powershell
.\windows\install.ps1
```
Copies `windows/profile.ps1` to both profile locations and saves repo path to `~/.marty-dotfiles.json`.

### Day-to-day sync
```powershell
dotsync    # git pull in repo, then re-copies profile to both locations
```

---

## Versioning

Three surfaces must stay in sync:
1. **`VERSION`** file
2. **`dot_zshrc.tmpl`**: `export DOTFILES_VERSION="x.y.z"`
3. **`CHANGELOG.md`**: matching `## [x.y.z] — YYYY-MM-DD` entry
