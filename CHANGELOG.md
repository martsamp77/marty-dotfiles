# Changelog

All notable changes to [Marty's dotfiles](https://github.com/martsamp77/marty-dotfiles) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Version numbers follow [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html) (SemVer): **MAJOR.MINOR.PATCH** with no leading `v` in `VERSION` / `DOTFILES_VERSION` (Git tags may use a `v` prefix).

| Level | When to bump |
|-------|----------------|
| **MAJOR** | Incompatible structural or bootstrap changes (e.g. new required tool, breaking chezmoi layout). |
| **MINOR** | New features or substantial behavior changes that remain backwards-compatible for existing installs. |
| **PATCH** | Bug fixes, docs-only releases, small refactors, cosmetic or comment-only updates. |

**Canonical version surfaces** (must agree for every release): root [`VERSION`](VERSION), `export DOTFILES_VERSION` in [`dot_zshrc.tmpl`](dot_zshrc.tmpl), and the newest `## [x.y.z]` section below.

For every commit that changes managed configuration, update this file (see [README.md](README.md) → *Maintaining this repository*). The full Git history is available on GitHub: [commits on `main`](https://github.com/martsamp77/marty-dotfiles/commits/main/).

---

## [Unreleased]

### Changed
- **Shell startup logging (zsh + PowerShell)** — Default is **minimal**: one **`dotfiles: ok`** line (or **errors** if something critical like **`chezmoi`** is missing). **`MARTY_DOTFILES_LOG=warn`** adds a compact tool/config block; **`=debug`** prints the full paste-friendly dump. Legacy **`MARTY_DOTFILES_DIAG_QUIET=1`** still forces minimal. **zsh**: **`dotdiag warn`** / **`dotdiag debug`**. **PowerShell**: **`Show-MartyDotfilesDiag warn`** / **`debug`** (positional or **`-Tier`**); with no arguments it prints the **warn** tier. Starship-missing **`Write-Warning`** only when log level is **warn** or higher. Self-test: [`scripts/test-marty-powershell-profile.ps1`](scripts/test-marty-powershell-profile.ps1) sets **`MARTY_DOTFILES_LOG` inside each child process** so the on-demand check is not skewed by a leftover **`=debug`** in the parent.
- **PowerShell startup diagnostics** — In **debug** level only, **`PATH`** is printed in full with **`PathLen`**.
- **[`docs/shell-test-checklist.md`](docs/shell-test-checklist.md)** — Checklist for **zsh** and **PowerShell** (undo/install cycles, **`ls`/`dir`/`cd`**, **`starshipon`/`off`**, chezmoi helpers); [README.md](README.md) links it under *Maintaining this repository*.
- **PowerShell** — **`starshipon`** / **`starshipoff`** / **`starshipupdate`** profile functions: **`Get-MartyDotfilesScriptsDir`** finds **`scripts`** via **`chezmoi source-path`** or **`%USERPROFILE%\.local\share\chezmoi\scripts`** so **`dotps`** works when source-path is unset. **`starshipupdate`** falls back to **`Invoke-MartyStarshipUpdateInstall`** (winget + **`starship.rs/install.ps1`**) if **`dotstarship.ps1`** is missing. **`starshipon`** / **`starshipoff`** toggle **`[data.ps]`** via [`scripts/dotps.ps1`](scripts/dotps.ps1) `starship-on` / `starship-off`, **`chezmoi apply`**, then **`. $PROFILE`**. [`install-powershell.ps1`](install-powershell.ps1) lists these in “Available commands” after bootstrap.
- **[README.md](README.md)** — Quick install (Windows PowerShell) now includes both one-liners: setup (`install-powershell.ps1`) and settings-only undo (`undo-powershell.ps1`).
- **[`undo-powershell.ps1`](undo-powershell.ps1)** — Header/docs now explicitly state default behavior is settings rollback (no Starship uninstall unless `-UninstallPackages` is passed).
- **[`dot_config/starship.toml`](dot_config/starship.toml)** — Richer Starship: `format = "$all"`, `add_newline = true`, **`right_format`** for **`cmd_duration`** + **`time`**, tuned **`[cmd_duration]`** / **`[time]`** / **`[character]`**; keeps directory/git styling. See [Starship configuration](https://starship.rs/config/); run **`starship explain`** to inspect modules. If **`git_status`** is slow on Windows, disable that module or trim **`format`**.
- **[`.chezmoitemplates/marty-powershell.ps1.tmpl`](.chezmoitemplates/marty-powershell.ps1.tmpl)** / **[`.chezmoi/templates/marty-powershell.ps1.tmpl`](.chezmoi/templates/marty-powershell.ps1.tmpl)** — **`ls`** / **`dir`**: single list sorted by name via **`Show-MartyColoredChildListing`** (**Cyan** folder names, **Gray** file names, **DarkGray** Mode/Time/Length). **`cd`**: after navigation, **subfolders only** via **`Format-Wide`**. When Starship is enabled: **transient prompt** per [advanced config](https://starship.rs/advanced-config/). **`gci`** / **`Get-ChildItem`** unchanged for default output. PSReadLine **syntax + completion menu** colors when supported.
- **[README.md](README.md)** — Windows PowerShell: **Starship** section notes rich **`dot_config/starship.toml`**, **`chezmoi edit`**, **`starship explain`**, **`STARSHIP_CONFIG`**. Quick install + Fresh install (Windows): **`twpayne.chezmoi`** vs invalid **`Twpayne.Chezmoi`**, **get.chezmoi.io** fallback to **`%USERPROFILE%\.local\bin`**, prerequisites, and troubleshooting for winget / PATH.

### Fixed
- **PowerShell profile** — **`Set-Alias dir ls`** now uses **`-Option AllScope`** so replacing the built-in **AllScope** `dir` alias does not error with *The AllScope option cannot be removed from the alias 'dir'* (seen when dot-sourcing **`$PROFILE`** after install).
- **PowerShell profile** — **`dotps`** now takes a single **`$Cmd`** argument and calls **`dotps.ps1`** with a **positional** string (no **`@args`** splat). Windows PowerShell 5.1 was treating **`starship-off`** as a **parameter name**, causing *Parameter set cannot be resolved*. Profile uses **`dotps starshipon`** / **`dotps starshipoff`**; [`scripts/dotps.ps1`](scripts/dotps.ps1) accepts **`starshipon`** / **`starshipoff`** as well as hyphen forms for direct script invocation.
- **`ls`** / **`dir`** — **`dir -h`** and **`-Hidden`** map to **`Get-ChildItem -Force`** so hidden items list without *parameter not found*.
- **`install-powershell.ps1`** — **`irm … | iex`** leaves **`$PSCommandPath`** empty; avoid **`Split-Path`** on it so bootstrap no longer fails with *Cannot bind argument to parameter 'Path' because it is an empty string* (local **`.chezmoi`** detection only applies when the script is run from disk, e.g. **`.\install-powershell.ps1`**).
- **`install-powershell.ps1`** — after **`chezmoi init` / `apply`**, **`Ensure-MartyPowerShellProfiles`** creates **`Documents\PowerShell`** and **`Documents\WindowsPowerShell`** if needed and runs **`chezmoi apply`** on **both** **`Microsoft.PowerShell_profile.ps1`** paths so **pwsh** and **Windows PowerShell 5.1** each get a real profile file (fixes **`. $PROFILE`** when the path did not exist). Uses **`[IO.Path]::GetDirectoryName`** for parent dirs (avoids **PS 5.1** **`Split-Path -LiteralPath -Parent`** parameter-set errors). End-of-script hints show both dot-source paths.
- **`install-powershell.ps1`** — use winget id **`twpayne.chezmoi`** (the old **`Twpayne.Chezmoi`** id returns “No package found” / exit `-1978335212`). If winget still leaves `chezmoi` missing, fall back to **`get.chezmoi.io`** into **`%USERPROFILE%\.local\bin`** and prepend that dir to the session `PATH`.
- **`scripts/dottools.ps1`** — same **`twpayne.chezmoi`** id for `winget upgrade`.

### Added
- **PowerShell profile** — [`.chezmoi/templates/marty-powershell.ps1.tmpl`](.chezmoi/templates/marty-powershell.ps1.tmpl): PSReadLine **Tab → MenuComplete** (ZSH-like menu completion) and **ShowToolTips**; interactive **`cd`** wraps `Set-Location` and runs **`Get-ChildItem`** on success (bare `cd` goes to `$HOME`); **`dots`** uses that `cd` so the chezmoi source lists after jumping in.
- **Cursor / VS Code** — [`cursor/settings.json`](cursor/settings.json): set `terminal.integrated.suggest.enabled` to `false` so Tab reaches **PSReadLine** in the integrated terminal (avoids shell-integration suggestions competing with Tab vs. cmd); default Windows profile **PowerShell 7 (dotfiles)** runs `C:\Program Files\PowerShell\7\pwsh.exe` with `-WorkingDirectory ~`.
- **`dotupload`** — [`scripts/dotupload.sh`](scripts/dotupload.sh) and [`scripts/dotupload.ps1`](scripts/dotupload.ps1) copy live Cursor/VS Code `settings.json` into `cursor/settings.json`, optionally export user rules, refresh extensions/snippet manifests, then `git add -A`, commit with a required descriptive message, and push; wired from [`dot_zshrc.tmpl`](dot_zshrc.tmpl) and the [PowerShell profile template](.chezmoi/templates/marty-powershell.ps1.tmpl). Documented in [README.md](README.md).
- **`cursor-export-rules.sh`** — Git Bash (`MINGW` / `MSYS`) can resolve `state.vscdb` via `$APPDATA`, so `dotupload --rules` works from bash on Windows as well as PowerShell.

### Planned
- Use Git tags `vX.Y.Z` at release time if you want GitHub compare URLs in release notes (`v1.6.1...v1.6.2`).

---

## [1.6.2] — 2026-03-21

### Added
- **`VERSION`** — one-line SemVer at the repository root; keep in sync with `DOTFILES_VERSION` and this changelog.
- **`.githooks/pre-commit`** — if you `git config core.hooksPath .githooks`, commits that touch managed dotfiles must also stage `CHANGELOG.md` (override with `SKIP_CHANGELOG=1` when appropriate).
- **`.gitattributes`** — forces LF for `.githooks/**` and `*.sh` so hooks run under Git Bash on Windows without `CRLF` / `$'\r': command not found` errors.

### Changed
- **Documentation** — revised [`cursor/EXTENSIONS.md`](cursor/EXTENSIONS.md) and [`cursor/extensions.txt`](cursor/extensions.txt); updated [`cursor/settings.json`](cursor/settings.json) for editor behavior and preferences.
- **`dot_zshrc.tmpl`** — refactored OS-aware `update` / `ls` alias definitions for clarity.
- **`.chezmoiignore.tmpl`** — also excludes `VERSION`, `.gitattributes`, and `.githooks` from ever being deployed to `$HOME`.
- **`DOTFILES_VERSION`** — `1.6.2`.

---

## [1.6.1] — 2026-03-20

### Changed
- **zsh-autosuggestions** — Strategy is now `(history completion)` instead of completion-first (avoids short-buffer completion noise). Added `ZSH_AUTOSUGGEST_COMPLETION_IGNORE` for 0–2 character buffers, `ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20` for large pastes, and `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=241,italic'` so ghost text is distinct from syntax-highlighted comments (`fg=8`) and default foreground.
- **`DOTFILES_VERSION`** — `1.6.1` in `dot_zshrc.tmpl`.
- **README** — zsh-autosuggestions section updated to match the new strategy and highlight style.

---

## [1.6.0] — 2026-03-20

### Added
- **Windows PowerShell via chezmoi** — Managed profiles for **pwsh** and **Windows PowerShell 5.1** (`Documents/PowerShell/…` and `Documents/WindowsPowerShell/…`), shared body in [`.chezmoi/templates/marty-powershell.ps1.tmpl`](.chezmoi/templates/marty-powershell.ps1.tmpl).
- **`.chezmoi.toml.tmpl`** — `[data.ps]` with one-time prompts on Windows (Starship, PSReadLine prediction + view); non-Windows machines get safe defaults only.
- **`.chezmoiignore.tmpl`** — Skips deploying PowerShell profiles on macOS/Linux.
- **`dotup` / `dotapply` / `dotdiff` / `dotedit` / `dots` / `dottools` / `dotps` / `undotps`** in PowerShell, mirroring the zsh chezmoi shortcuts.
- **`scripts/dotps.ps1`** — `show`, `wizard`, `off`, `reset` for `[data.ps]` preferences.
- **`scripts/dottools.ps1`** — winget upgrades for pwsh, chezmoi, Starship, Cursor, VS Code.
- **`install-powershell.ps1`** — Windows bootstrap (chezmoi init/apply, optional Starship when enabled in data).

### Changed
- **`DOTFILES_VERSION`** — `1.6.0` in `dot_zshrc.tmpl`.
- **README** — Windows PowerShell workflow, source-path table entries, platform row.

---

## [1.5.1] — 2026-03-18

### Added
- **Cursor IDE sync** — [`run_after_apply-cursor.sh.tmpl`](run_after_apply-cursor.sh.tmpl) deploys Cursor settings, keybindings, snippets, and related files after `chezmoi apply` when the Cursor user directory exists.
- **VS Code parity** — Same manifest workflow for VS Code; [`scripts/vscode-sync-extensions.sh`](scripts/vscode-sync-extensions.sh) installs from `cursor/extensions.txt` (skips `anysphere.*` IDs).
- **Extension tooling** — [`scripts/cursor-sync-extensions.sh`](scripts/cursor-sync-extensions.sh) for interactive orphan/missing handling; WSL fallbacks when resolving the `cursor` / `cursor.exe` CLI.
- **`scripts/dottools.sh`** — Upgrade Cursor, VS Code, git, chezmoi, zsh, and fzf (Homebrew / apt / winget paths); separated from **`dotup`** so routine pulls stay fast.
- **`install-starship.ps1`** — Standalone Starship-focused installer for Windows PowerShell (chezmoi path supersedes day-to-day ad-hoc profile edits).
- **Cursor Extensions documentation** — README and [`cursor/EXTENSIONS.md`](cursor/EXTENSIONS.md): where extensions live by OS, what `cursor/extensions.txt` is, manual manifest updates, and install one-liners.
- **`cursor/extensions.txt` header** — Install commands for PowerShell and bash plus pointers to README / EXTENSIONS.md.

### Changed
- **README** — Expanded Cursor/VS Code sections; clarified extension sync vs `chezmoi apply`; documented `dottools` vs `dotup`.
- **Winget** — Clearer separation of Cursor vs Visual Studio Code upgrade commands in tooling scripts.

---

## [1.5.0] — 2026-03-17

### Added
- **Local secrets file** — `.zshrc` sources `~/.zshrc.local` at startup if the file exists. API keys and tokens live there per machine; the file is never tracked by chezmoi. README documents the pattern.
- **History API key masking** — `zshaddhistory` hook intercepts commands before `~/.zsh_history`. Known secret patterns are redacted; the command still runs. Patterns include `sk_live_*`, `pk_live_*`, `sk-*`, `pk-*`, `sm-*`, `Bearer …`, `Authorization: Bearer …`, and `*_KEY` / `*_TOKEN` / `*_SECRET` assignments.
- **Docker convenience (non-macOS)** — If `docker` is installed and the service reports not running, attempt `sudo service docker start` (guarded; see `dot_zshrc.tmpl`).

### Changed
- **Shell defaults** — `EDITOR` / `VISUAL` default to `nano`.
- **Prompt / terminal** — Iterative Pure and zsh color adjustments for dark backgrounds; `TERM` defaults toward `xterm-256color` on Linux/WSL; git branch color fix for contrast.

---

## [1.4.2] — 2026-03-16

### Added
- **README: PuTTY** — Font (Cascadia Code), UTF-8 translation, window/scrollback, keepalives, optional session logging.

### Fixed
- **Ctrl+V paste (WSL)** — `_wsl_paste` tries `powershell.exe` by short name first, then the full Windows path. Shows an error if interop or clipboard fails instead of failing silently.
- **UTF-8 locale (Linux/WSL)** — `LANG` / `LC_ALL` default to `en_US.UTF-8` when unset so Unicode (e.g. Pure `❯`) does not render as boxes on minimal Ubuntu/WSL images.

---

## [1.4.1] — 2026-03-16

### Fixed
- **Home / End (WSL / Windows Terminal)** — Extra `beginning-of-line` / `end-of-line` bindings for `^[OH`, `^[[1~`, `^[OF`, `^[[4~`.
- **Keypad Enter** — `^[OM` bound to `accept-line`.
- **Ctrl+V (WSL)** — WSL-only `_wsl_paste` via `Get-Clipboard`; other platforms keep `quoted-insert`.

---

## [1.4.0] — 2026-03-16

### Added
- **`install.sh`** — One-command bootstrap for macOS, Ubuntu, and WSL (Homebrew, zsh, git, fzf, chezmoi, default shell, locale generation, SSH→HTTPS fallback, `chezmoi init --apply`).
- **`install.sh` in `.chezmoiignore`** — Script stays in the repo only, not deployed to `$HOME`.

---

## [1.3.2] — 2026-03-16

### Fixed
- Renamed `dot_zshrc` → `dot_zshrc.tmpl` so chezmoi evaluates `{{ if eq .chezmoi.os }}` at apply time (avoids zsh parse errors from raw template text).

---

## [1.3.1] — 2026-03-16

### Fixed
- **`.chezmoiignore`** — `README.md` and `CHANGELOG.md` are not deployed into `$HOME`.

### Changed
- **README** — Troubleshooting for stuck `chezmoi update` rebase conflicts and missed `chezmoi apply`.

---

## [1.3.0] — 2026-03-16

### Added
- **`.chezmoiexternal.toml`** — Pure, zsh-autosuggestions, and zsh-syntax-highlighting as chezmoi externals with `refreshPeriod = 168h`.

### Changed
- **Plugin loading** — Plain guarded `source` lines; chezmoi externals own clone/update.

### Removed
- **Vendored `dot_zsh/` plugin trees** — Third-party plugin source removed from the repo in favor of externals.
- **`_zsh_plugin_load` / `_zsh_fpath_load`** — No longer used.

---

## [1.2.0] — 2026-03-16

### Added
- **Pure prompt** — Replaces hand-rolled `vcs_info` prompt; two-line layout, async git, SSH/PuTTY-friendly.
- **`ZSH_HIGHLIGHT_STYLES`** — Explicit dark-background-friendly colors for syntax highlighting.
- **Pure `zstyle` overrides** — Path, git, dirty, prompt success/error, SSH user/host colors.

### Changed
- **Prompt implementation** — `promptinit` + `prompt pure` instead of custom `PROMPT=` / `precmd` block.
- **README** — Pure documentation and plugin story.

---

## [1.1.0] — 2026-03-16

### Added
- **`compinit` caching** — `.zcompdump` rebuilt at most once per 24 hours.
- **macOS Homebrew PATH** — `brew shellenv` for Apple Silicon and Intel.
- **Dotfile aliases** — `dotedit`, `dotdiff`, `dotapply`, `dotup`, `dots`.
- **`_zsh_plugin_load`** — Clone fallback for missing plugin dirs (superseded by externals in 1.3.0).
- **`AUTO_CD`**, **`NO_BEEP`**, **`dircolors` guard**.

### Fixed
- Replaced invalid `chezmoi apply --refresh` with `chezmoi update --force`.
- Removed invalid `bindkey '^V' put-clipboard`.
- Startup blank lines from nonexistent `$ZSH_REVISION`-style variables.
- macOS `dircolors` errors.

### Changed
- **Auto-sync** — `disown` to suppress stray job-control messages.
- **README** — Platform table, features, workflow, troubleshooting.

---

## [1.0.0] — 2026-03-15

### Added
- Initial chezmoi-managed repository: `dot_zshrc`, vendored autosuggestions and syntax-highlighting, history/completion/prompt/fzf/auto-sync, OS-aware templates, and first README.

---

*Repository: [github.com/martsamp77/marty-dotfiles](https://github.com/martsamp77/marty-dotfiles)*
