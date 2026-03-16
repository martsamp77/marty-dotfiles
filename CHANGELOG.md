# Changelog

All notable changes to Marty's dotfiles are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

- **MAJOR** — incompatible structural changes (e.g. new dependency, bootstrap change)
- **MINOR** — new features or significant improvements (backwards-compatible)
- **PATCH** — bug fixes, comment corrections, cosmetic tweaks

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
