# Changelog

All notable changes to Marty's dotfiles are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

- **MAJOR** — incompatible structural changes (e.g. new dependency, bootstrap change)
- **MINOR** — new features or significant improvements (backwards-compatible)
- **PATCH** — bug fixes, comment corrections, cosmetic tweaks

---

## [1.5.1] — 2026-03-18

### Added
- **Cursor Extensions documentation** — README now includes: where extensions are stored (by OS), what `cursor/extensions.txt` is, how to update the manifest manually, and how to install extensions from the manifest (via chezmoi apply or manual PowerShell/bash commands).
- **extensions.txt header** — Updated with correct install commands for both PowerShell and bash, and a pointer to README for full documentation.

### Changed
- **README** — Replaced brief "Populating the extension manifest" section with comprehensive "Cursor Extensions" documentation.

---

## [1.5.0] — 2026-03-17

### Added
- **Local secrets file** — `.zshrc` sources `~/.zshrc.local` at startup if the file exists.
  API keys and tokens go in that file on each machine; it is never tracked by chezmoi and
  never reaches GitHub. Each machine can carry different keys or none at all.
  README documents the pattern and a one-liner for creating the file on a new machine.
- **History API key masking** — `zshaddhistory` hook intercepts every command before it is
  written to `~/.zsh_history`. Known secret patterns are redacted and the sanitised version
  is stored instead; the command itself still executes normally. Patterns covered:
  `sk_live_*`, `pk_live_*`, `sk-*`, `pk-*` (OpenAI, Anthropic, Stripe, many SaaS tools),
  `Bearer <token>`, `Authorization: Bearer <token>`, and any environment variable assignment
  ending in `_KEY`, `_TOKEN`, or `_SECRET`.

---

## [1.4.2] — 2026-03-16

### Fixed
- **Ctrl+V paste (WSL) — improved reliability**: `_wsl_paste` widget now tries
  `powershell.exe` by short name first, then falls back to the full Windows path
  (`/mnt/c/Windows/System32/.../powershell.exe`). Displays a visible error message
  if interop is unavailable or the clipboard is empty instead of silently doing nothing.
- **UTF-8 locale enforcement on Linux/WSL**: Added `export LANG/LC_ALL=en_US.UTF-8`
  (using `${VAR:-default}` so an explicitly-set locale is never overridden). Fixes
  `❯` and other Unicode glyphs appearing as squares on fresh Ubuntu/WSL installs
  where `/etc/default/locale` has not been generated.
  To generate the locale if missing: `sudo locale-gen en_US.UTF-8 && sudo update-locale LANG=en_US.UTF-8`

---

## [1.4.1] — 2026-03-16

### Fixed
- **Home key on WSL / Windows Terminal**: Added `^[OH` (VT100 application-cursor) and
  `^[[1~` (rxvt / older xterm) as additional `beginning-of-line` bindings so Home works
  across all terminal variants, not just PuTTY/xterm.
- **End key on WSL / Windows Terminal**: Same treatment — added `^[OF` and `^[[4~`.
- **Keypad Enter**: Bound `^[OM` (application-keypad-mode Enter) to `accept-line` so the
  numeric-keypad Enter key behaves identically to the main keyboard Enter.
- **Ctrl+V paste on WSL**: Added a WSL-only `_wsl_paste` widget that reads from the
  Windows clipboard via `powershell.exe -Command Get-Clipboard` and inserts the text at
  the cursor. Bound to `^V` only when running inside WSL; all other platforms keep the
  default emacs `quoted-insert` binding.

---

## [1.4.0] — 2026-03-16

### Added
- `install.sh` — one-command bootstrap script for new machines.
  Detects macOS / Ubuntu / WSL, installs Homebrew (macOS), zsh, git, fzf,
  chezmoi, sets zsh as the default shell, generates the `en_US.UTF-8` locale
  (fixes `❯` rendering as a square on Ubuntu), and runs `chezmoi init --apply`.
  Tries SSH first, falls back to HTTPS automatically.
  One-liner: `bash <(curl -fsLS https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install.sh)`
- Added `install.sh` to `.chezmoiignore` so it stays in the repo but is not
  deployed to `$HOME`.

---

## [1.3.2] — 2026-03-16

### Fixed
- Renamed `dot_zshrc` → `dot_zshrc.tmpl` so chezmoi processes `{{ if eq .chezmoi.os }}`
  template blocks at apply time.  Without the `.tmpl` suffix, chezmoi copies the file
  verbatim and zsh fails to start with "command not found: eq" and "parse error near end".

---

## [1.3.1] — 2026-03-16

### Fixed
- Added `.chezmoiignore` to prevent `README.md` and `CHANGELOG.md` from being
  deployed to `$HOME` by chezmoi (they belong in the repo, not in `~/`).

### Changed
- README Troubleshooting section updated with instructions for resolving a stuck
  `chezmoi update` rebase conflict and for recovering from a missed `chezmoi apply`.

---

## [1.3.0] — 2026-03-16

### Added
- `.chezmoiexternal.toml` — declares all three plugins (Pure, zsh-autosuggestions,
  zsh-syntax-highlighting) as chezmoi-managed external git repos with a 168 h weekly
  auto-refresh period.  `chezmoi apply --refresh-externals` forces an immediate update.

### Changed
- Plugin loading in `dot_zshrc` simplified from helper functions with inline `git clone`
  fallbacks to plain guarded `source` statements — chezmoi externals guarantee the
  files exist after any `chezmoi apply`.
- README updated with full documentation of the externals model, including a command
  reference table for first-time setup, force-refresh, and auto-update workflows.

### Removed
- `dot_zsh/` directory and all vendored plugin source trees (`pure/`,
  `zsh-autosuggestions/`, `zsh-syntax-highlighting/`) — hundreds of third-party files
  are no longer committed into the repository.
- `_zsh_plugin_load` and `_zsh_fpath_load` helper functions (no longer needed now that
  chezmoi manages the plugin directories).

---

## [1.2.0] — 2026-03-16

### Added
- **Pure prompt** (sindresorhus/pure) — replaces the hand-rolled `vcs_info` prompt.
  Two-line layout, async git status, no Nerd Fonts required, SSH/PuTTY-safe.
  Vendored into `dot_zsh/pure/` (later removed in v1.3.0 in favour of externals).
- `_zsh_fpath_load` helper — mirrors `_zsh_plugin_load` for `$fpath`-based plugins,
  with silent `git clone` fallback.
- **`ZSH_HIGHLIGHT_STYLES` color scheme** — 13 token types explicitly colored for dark
  terminal backgrounds: commands (green bold), unknown tokens (red bold), flags
  (magenta), strings (yellow), paths (white underline), comments (dark grey), etc.
- Pure `zstyle` color overrides: cyan path, bright-blue git branch, yellow dirty flag,
  magenta prompt success, red prompt error, green user/host (SSH sessions only).

### Changed
- Removed `vcs_info` / `precmd_functions` / `PROMPT=` block — entirely replaced by
  `autoload -U promptinit; promptinit; prompt pure`.
- README updated with Pure documentation, color override table, and plugin management
  explanation.

---

## [1.1.0] — 2026-03-16

### Added
- `compinit` `.zcompdump` caching — dump rebuilt at most once per 24 hours via
  extended glob timestamp check; `compinit -C` used on subsequent starts for speed.
- **macOS Homebrew PATH** — `brew shellenv` evaluated for Apple Silicon
  (`/opt/homebrew`) with Intel fallback (`/usr/local`), inside chezmoi `darwin` block.
- **Dotfile management aliases** — `dotedit`, `dotdiff`, `dotapply`, `dotup`, `dots`
  (were documented in README but missing from the file itself).
- `_zsh_plugin_load` helper function with silent `git clone` fallback if a plugin
  directory is missing after a partial `chezmoi apply`.
- `setopt AUTO_CD` — type a bare directory name to cd into it.
- `setopt NO_BEEP` — silence all terminal bell characters.
- `dircolors` guard — `command -v dircolors &>/dev/null` prevents crash on macOS where
  `dircolors` is not installed by default.

### Fixed
- `chezmoi apply --refresh --force` — `--refresh` is not a valid chezmoi flag; replaced
  with the correct `chezmoi update --force`.
- `bindkey '^V' put-clipboard` — `put-clipboard` is not a built-in zsh widget; binding
  failed silently on every session startup.  Removed.
- Startup printed 8 blank lines — `$ZSH_REVISION`, `$ZSH_BUILD_DATE`, `$ZSH_BUILD_HOST`
  etc. are not standard zsh variables and expand to empty strings.  Replaced with a
  single `print -P "%F{8}  zsh ${ZSH_VERSION} · %m%f"` greeting.
- `eval "$(dircolors -b)"` ran unconditionally on macOS where the binary does not exist,
  causing a silent error on every shell start.

### Changed
- `compinit` now uses a 24-hour cache check instead of running full init every session.
- `chezmoi update` background auto-sync now uses `disown` to suppress stray "Done"
  job-completion messages.
- README completely rewritten — fixed broken code block formatting, added platform
  support table, complete feature documentation, daily workflow table, and
  troubleshooting section.

---

## [1.0.0] — 2026-03-15

### Added
- Initial chezmoi-managed dotfiles repository.
- `dot_zshrc` with:
  - 1,000,000-line shared, deduplicated, timestamped history.
  - Smart menu-driven tab completion with `zstyle`.
  - `vcs_info`-based prompt (bright green user@host, cyan path, red git branch) tuned
    for dark PuTTY/SSH terminal backgrounds.
  - Emacs key bindings with PuTTY Home/End fallback sequences.
  - Common aliases (`ll`, `grep`, `..`, `history-stats`, `cd`+auto-ls).
  - OS-aware `update` and `ls` aliases via chezmoi `{{ if eq .chezmoi.os "darwin" }}`
    templates.
  - `fzf` integration with dark-background color palette.
  - Background auto-sync: git fetch + chezmoi apply on every shell session.
- `dot_zsh/zsh-autosuggestions/` — fish-style ghost-text history suggestions, vendored.
- `dot_zsh/zsh-syntax-highlighting/` — real-time command colorization, vendored.
- Initial README.md.
