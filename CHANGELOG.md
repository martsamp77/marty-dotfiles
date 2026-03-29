# Changelog

All notable changes to [Marty's dotfiles](https://github.com/martsamp77/marty-dotfiles) are documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versioning: [SemVer 2.0.0](https://semver.org/) — `MAJOR.MINOR.PATCH`.

**Canonical version surfaces** (must agree on every release): [`VERSION`](VERSION), `export DOTFILES_VERSION` in [`dot_zshrc.tmpl`](dot_zshrc.tmpl), newest `## [x.y.z]` section below.

---

## [Unreleased]

---

## [2.0.1] — 2026-03-29

### Changed
- **zsh** — Autosuggestions use history only (`ZSH_AUTOSUGGEST_STRATEGY=(history)`); dropped completion-driven ghost text and `ZSH_AUTOSUGGEST_COMPLETION_IGNORE`.
- **zsh** — Completion completer chain is `_expand _complete` only (removed `_correct` / `_approximate` to avoid near-duplicate correction matches).
- **`DOTFILES_VERSION`** — `2.0.1`.

---

## [2.0.0] — 2026-03-26

### Changed
- **Windows PowerShell** — Removed chezmoi-managed profiles and all Starship/PSReadLine integration. PowerShell is now a simple copy-based system: [`windows/profile.ps1`](windows/profile.ps1) is the source of truth; [`windows/install.ps1`](windows/install.ps1) deploys it to both profile locations; `dotsync` alias syncs future changes.
- **Repository layout** — All Windows files consolidated under `windows/`. The chezmoi source (repo root) now covers Linux/Mac only.
- **zsh** — Removed background GitHub auto-sync on shell startup; removed `dotup` and `dotupload` aliases.
- **`dottools`** — Removed Cursor and VS Code upgrade steps; now upgrades git, chezmoi, zsh, fzf only (Linux/Mac).
- **`DOTFILES_VERSION`** — `2.0.0`.

### Added
- [`windows/profile.ps1`](windows/profile.ps1) — Minimal PowerShell profile: prepends `~\.local\bin` to `PATH`; defines `dotsync` alias.
- [`windows/install.ps1`](windows/install.ps1) — First-time bootstrap: copies profile to both PS locations, saves repo path to `~/.marty-dotfiles.json`.
- [`windows/tools.ps1`](windows/tools.ps1) — winget upgrades for PowerShell and Git.

### Removed
- All Cursor and VS Code settings sync (`cursor/`, `run_after_apply-cursor.sh.tmpl`, `scripts/cursor-*.sh`, `scripts/vscode-sync-extensions.sh`, `scripts/dotupload.sh`, `scripts/dotupload.ps1`)
- All chezmoi-managed PowerShell files (`Documents/PowerShell/`, `Documents/WindowsPowerShell/`, `.chezmoitemplates/marty-powershell.ps1.tmpl`, `.chezmoi.toml.tmpl`)
- Starship integration for PowerShell (`install-starship.ps1`, `scripts/dotstarship.ps1`, `scripts/dotps.ps1`)
- Bootstrap/undo scripts (`install-powershell.ps1`, `undo-powershell.ps1`)
- Dev workflow files (`.githooks/pre-commit`, `.gitattributes`, `scripts/test-marty-powershell-profile.ps1`)
- `scripts/dottools.ps1` (superseded by `windows/tools.ps1`)

---

## [1.6.2] — 2026-03-21

### Added
- **`VERSION`** — canonical SemVer file at repo root.
- **`.githooks/pre-commit`** — optional guard requiring `CHANGELOG.md` to be staged when dotfile sources change.
- **`.gitattributes`** — forces LF for `.githooks/**` and `*.sh` on Windows.
- **`dotupload`** — `scripts/dotupload.sh` and `scripts/dotupload.ps1` sync live Cursor/VS Code `settings.json` into `cursor/settings.json`, commit, and push; `dotupload --rules`, `--extensions`, `--snippets` flags available.
- **`cursor/settings.json`** — terminal suggestion disabled so Tab reaches PSReadLine; default Windows terminal profile set to pwsh 7.
- **Tartarus Keymap Editor** — `tartarus/tartarus-keymap.html` added.

### Changed
- **Windows PowerShell profile** — `starshipon` / `starshipoff` / `starshipupdate` commands added; `ls`/`dir` replaced with color-formatted wrapper; `cd` shows subfolder listing on navigation; PSReadLine Tab → MenuComplete with tooltips.
- **`install-powershell.ps1`** — fixed empty `$PSCommandPath` when run via `irm | iex`; corrected winget id to `twpayne.chezmoi`; ensures both profile directories exist and applies both profile paths.
- **`undo-powershell.ps1`** — added, performs settings rollback without removing Starship.
- **`cursor/extensions.txt`** and **`cursor/EXTENSIONS.md`** — revised and expanded.
- **`dot_config/starship.toml`** — richer format with `right_format` for duration + clock; `add_newline = true`.
- **Startup logging** — three-tier system (`minimal`/`warn`/`debug`) for both zsh and PowerShell; `dotdiag` function and `MARTY_DOTFILES_LOG` env var.
- **`docs/shell-test-checklist.md`** — added.

---

## [1.6.1] — 2026-03-20

### Changed
- **zsh-autosuggestions** — strategy changed to `(history completion)`; `ZSH_AUTOSUGGEST_COMPLETION_IGNORE` added for 0–2 character buffers; `ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20`; highlight style `fg=241,italic`.
- **`dot_zshrc.tmpl`** — OS-aware `update`/`ls` alias definitions refactored for clarity.

---

## [1.6.0] — 2026-03-20

### Added
- **Windows PowerShell via chezmoi** — managed profiles for pwsh 7 and Windows PowerShell 5.1; shared body in `.chezmoitemplates/marty-powershell.ps1.tmpl`.
- **`.chezmoi.toml.tmpl`** — `[data.ps]` one-time prompts on Windows (Starship, PSReadLine prediction).
- **`dotup`/`dotapply`/`dotdiff`/`dotedit`/`dots`/`dottools`/`dotps`/`undotps`** in PowerShell profile.
- **`scripts/dotps.ps1`** — `show`, `wizard`, `off`, `reset` for `[data.ps]` preferences.
- **`scripts/dottools.ps1`** — winget upgrades for pwsh, chezmoi, Starship, Cursor, VS Code.
- **`install-powershell.ps1`** — Windows bootstrap.

---

## [1.5.1] — 2026-03-18

### Added
- **Cursor IDE settings** — `run_after_apply-cursor.sh.tmpl` deploys `cursor/settings.json`, keybindings, snippets, and MCP config after `chezmoi apply` when Cursor is present.
- **VS Code parity** — `scripts/vscode-sync-extensions.sh` installs from `cursor/extensions.txt` (skips `anysphere.*`).
- **Extension tooling** — `scripts/cursor-sync-extensions.sh` for interactive extension sync; `scripts/cursor-export-rules.sh` / `scripts/cursor-import-rules.sh` for SQLite-backed user rules.
- **`scripts/dottools.sh`** — upgrades Cursor, VS Code, git, chezmoi, zsh, fzf.
- **`dottools`** alias in zsh — runs `scripts/dottools.sh`; kept separate from `dotup` for speed.
- **`install-starship.ps1`** — standalone Starship installer for Windows PowerShell.
- **`cursor/extensions.txt`** and **`cursor/EXTENSIONS.md`** — canonical extension manifest with rationale.

---

## [1.5.0] — 2026-03-17

### Added
- **Local secrets file** — `.zshrc` sources `~/.zshrc.local` at startup if present; API keys live there, never tracked.
- **History API key masking** — `zshaddhistory` hook redacts `sk_live_*`, `Bearer …`, `*_KEY=…`, and similar patterns before writing to history.
- **Docker convenience** — on non-macOS, if Docker is installed but not running, attempt `sudo service docker start`.
- **PuTTY setup** — documented font (Cascadia Code), UTF-8, window/scrollback, keepalives.

### Changed
- **zsh colors** — Pure prompt and syntax highlighting tuned for 256-color dark backgrounds; git branch color improved.
- **`EDITOR`/`VISUAL`** — default to `nano`.
- **zsh-autosuggestions** — strategy and highlight style updated.

---

## [1.4.2] — 2026-03-16

### Fixed
- **UTF-8 locale (Linux/WSL)** — `LANG`/`LC_ALL` default to `en_US.UTF-8` when unset so Pure `❯` renders correctly on minimal Ubuntu images.
- **Ctrl+V paste (WSL)** — `_wsl_paste` tries `powershell.exe` by short name first, then full path; shows error on failure.

---

## [1.4.1] — 2026-03-16

### Fixed
- **Home/End (WSL/Windows Terminal)** — extra `beginning-of-line`/`end-of-line` bindings for `^[OH`, `^[[1~`, `^[OF`, `^[[4~`.
- **Keypad Enter** — `^[OM` bound to `accept-line`.
- **Ctrl+V (WSL)** — WSL-only `_wsl_paste` via `Get-Clipboard`.

---

## [1.4.0] — 2026-03-16

### Added
- **`install.sh`** — one-command bootstrap for macOS, Ubuntu, and WSL: Homebrew, zsh, git, fzf, chezmoi, default shell, locale, SSH→HTTPS fallback, `chezmoi init --apply`.

---

## [1.3.2] — 2026-03-16

### Fixed
- Renamed `dot_zshrc` → `dot_zshrc.tmpl` so chezmoi evaluates `{{ if eq .chezmoi.os }}` at apply time.

---

## [1.3.1] — 2026-03-16

### Added
- **`.chezmoiignore`** — prevents `README.md` and `CHANGELOG.md` from deploying to `$HOME`.

### Fixed
- README troubleshooting for stuck `chezmoi update` rebase conflicts.

---

## [1.3.0] — 2026-03-16

### Added
- **`.chezmoiexternal.toml`** — Pure, zsh-autosuggestions, zsh-syntax-highlighting as chezmoi externals with `refreshPeriod = "168h"`.

### Removed
- Vendored `dot_zsh/` plugin trees — replaced by externals.

---

## [1.2.0] — 2026-03-16

### Added
- **Pure prompt** — replaces hand-rolled `vcs_info` prompt; two-line, async git, SSH-friendly.
- **`ZSH_HIGHLIGHT_STYLES`** — dark-background-friendly colors for syntax highlighting.
- **Pure `zstyle` overrides** — path, git, dirty, prompt success/error, SSH host colors.

---

## [1.1.0] — 2026-03-15

### Added
- **`compinit` caching** — `.zcompdump` rebuilt at most once per 24 hours.
- **macOS Homebrew PATH** — `brew shellenv` for Apple Silicon and Intel.
- **Dotfile aliases** — `dotedit`, `dotdiff`, `dotapply`, `dotup`, `dots`.
- **Background auto-update** — new shell quietly checks GitHub and applies updates via `chezmoi update --force`.
- **`AUTO_CD`**, **`NO_BEEP`**, **`dircolors` guard**.

---

## [1.0.0] — 2026-03-15

### Added
- Initial import from AURORA: zsh config, plugins (zsh-autosuggestions, zsh-syntax-highlighting), history, completion, prompt, fzf, OS-aware aliases, background dotfile auto-sync, and first README.

---

*Repository: [github.com/martsamp77/marty-dotfiles](https://github.com/martsamp77/marty-dotfiles)*
