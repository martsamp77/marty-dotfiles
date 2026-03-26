# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/) for zsh (macOS/Linux/WSL) and Windows PowerShell. Changes here are deployed to `$HOME` via `chezmoi apply`.

## Common commands

### Apply changes to the local machine
```bash
chezmoi apply                     # Deploy all dotfiles to $HOME
chezmoi diff                      # Preview what would change
chezmoi apply --dry-run           # Simulate without writing
```

### Edit via chezmoi (preferred over editing source directly)
```bash
chezmoi edit ~/.zshrc             # Opens dot_zshrc.tmpl in $EDITOR
chezmoi edit-config               # Edit .chezmoi.toml
```

### Shell aliases (available after dotfiles are applied)
```bash
dotup        # chezmoi update (pull + apply from remote)
dotapply     # chezmoi apply
dotdiff      # chezmoi diff
dotedit      # chezmoi edit
dots         # cd to chezmoi source dir
dotupload    # push IDE + dotfile changes (scripts/dotupload.sh or .ps1)
dottools     # upgrade toolchain (scripts/dottools.sh or .ps1)
dotps        # manage PowerShell [data.ps] config (scripts/dotps.ps1)
```

### Bootstrap (first install)
```bash
# macOS/Ubuntu/WSL:
bash install.sh

# Windows PowerShell:
.\install-powershell.ps1
```

### IDE sync (Cursor/VS Code)
```bash
scripts/cursor-sync-extensions.sh   # Interactive extension sync
scripts/cursor-export-rules.sh      # Export rules to cursor/user-rules.md
scripts/cursor-import-rules.sh      # Import rules from SQLite DB
scripts/vscode-sync-extensions.sh   # VS Code extension parity
```

### Undo Windows settings
```powershell
.\undo-powershell.ps1               # Reverts PowerShell profile (keeps Starship by default)
```

## Architecture

### chezmoi source layout
chezmoi maps source files to `$HOME` using naming conventions:
- `dot_*` → `.` prefix (e.g., `dot_zshrc.tmpl` → `~/.zshrc`)
- `*.tmpl` → processed as Go templates before deployment
- `run_after_*.sh.tmpl` → scripts run after `chezmoi apply`
- `dot_config/` → `~/.config/`
- `Documents/` → `~/Documents/` (Windows PowerShell profiles)

### Template data
- **`.chezmoi.toml.tmpl`** — Windows-only interactive prompts for `[data.ps]`: Starship toggle, PSReadLine prediction source/view. Non-Windows gets hardcoded defaults.
- **`.chezmoiexternal.toml`** — Three zsh plugins (Pure, zsh-autosuggestions, zsh-syntax-highlighting) fetched as git repos and refreshed every 168h.
- **`.chezmoiignore.tmpl`** — Excludes repo-only files (README, scripts/, cursor/) from `$HOME` deployment; platform-conditional (PowerShell profiles skip on non-Windows, zsh apply hook skips on Windows).

### Key source files
| Source file | Deployed to |
|---|---|
| `dot_zshrc.tmpl` | `~/.zshrc` |
| `dot_config/starship.toml` | `~/.config/starship.toml` |
| `Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl` | `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1` |
| `Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1.tmpl` | `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1` |
| `.chezmoitemplates/marty-powershell.ps1.tmpl` | Shared body imported by both PS profiles |
| `cursor/settings.json` | `~/.config/Cursor/User/settings.json` (and VS Code path) via post-apply hook |

### PowerShell profile architecture
Both `Documents/PowerShell/` (pwsh 7) and `Documents/WindowsPowerShell/` (PowerShell 5.1) profiles are thin wrappers that source a shared body from `.chezmoitemplates/marty-powershell.ps1.tmpl`. The shared template is the main logic file (21K). Chezmoi `[data.ps]` values control Starship activation and PSReadLine behavior at template render time.

### IDE settings sync (post-apply hook)
`run_after_apply-cursor.sh.tmpl` runs after every `chezmoi apply`. It copies `cursor/settings.json`, `cursor/snippets/`, and `cursor/keybindings.json` to the OS-specific Cursor and VS Code user directories. Extension lists in `cursor/extensions.txt` are the canonical source; sync scripts reconcile the installed state.

## Versioning discipline

Three surfaces must stay in sync on every release:
1. **`VERSION`** file (root)
2. **`dot_zshrc.tmpl`**: `export DOTFILES_VERSION="x.y.z"`
3. **`CHANGELOG.md`**: matching `## [x.y.z] — YYYY-MM-DD` entry

CHANGELOG categories: **Added**, **Changed**, **Fixed**, **Planned**.

## Git hooks

`.githooks/pre-commit` requires CHANGELOG.md to be staged when commits touch config files (`dot_zshrc.tmpl`, `scripts/`, `cursor/`, `Documents/`, etc.).

Enable with: `git config core.hooksPath .githooks`
Skip with: `SKIP_CHANGELOG=1 git commit -m "…"`

## Platform conditionals in templates

Use chezmoi's Go template syntax for OS/host branching:
```
{{- if eq .chezmoi.os "windows" -}}
  ... Windows-only content ...
{{- else -}}
  ... Unix content ...
{{- end }}
```

`promptBoolOnce` / `promptChoiceOnce` in `.chezmoi.toml.tmpl` persist answers in `~/.config/chezmoi/chezmoi.toml` so users aren't re-prompted on subsequent applies.
