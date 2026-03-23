# Marty's Dotfiles

Personal configuration managed with [chezmoi](https://www.chezmoi.io/): one Git-backed source directory, applied consistently on every machine. Shell setup covers **zsh** (prompt, plugins, history, auto-sync) and **Windows PowerShell / pwsh** (profiles, Starship and PSReadLine preferences). **Cursor** and **VS Code** editor settings are deployed from this repo when those apps are present.

| | |
|---|---|
| **Current release (SemVer)** | **1.6.2** — see [CHANGELOG.md](CHANGELOG.md) |
| **Runtime check** | After apply: `echo $DOTFILES_VERSION` (exported from [`dot_zshrc.tmpl`](dot_zshrc.tmpl)) |
| **Upstream** | [github.com/martsamp77/marty-dotfiles](https://github.com/martsamp77/marty-dotfiles) |

---

## Table of contents

1. [Quick install](#quick-install)
2. [Documentation map](#documentation-map)
3. [Project overview](#project-overview)
4. [Versioning](#versioning)
5. [Fresh install](#fresh-install)
6. [Updates and daily workflow](#updates-and-daily-workflow)
7. [Maintaining this repository](#maintaining-this-repository)
8. [Change history](#change-history)
9. [How it works (chezmoi)](#how-it-works-chezmoi)
10. [Features](#features)
11. [Cursor and VS Code IDE settings](#cursor-and-vs-code-ide-settings)
12. [Adding a new dotfile](#adding-a-new-dotfile)
13. [Windows PowerShell (native)](#windows-powershell-native)
14. [Auto-apply on SSH login / EC2 user-data](#auto-apply-on-ssh-login--ec2-user-data)
15. [PuTTY setup (Windows)](#putty-setup-windows)
16. [API keys and local secrets](#api-keys-and-local-secrets)
17. [Templates](#templates)
18. [Troubleshooting](#troubleshooting)
19. [Why chezmoi?](#why-chezmoi)

---

## Quick install

**macOS**

```bash
bash <(curl -fsLS https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install.sh)
```

**Linux** (Ubuntu, WSL, etc.)

```bash
bash <(curl -fsLS https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install.sh)
```

**PC** (Windows PowerShell)

```powershell
irm https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install-powershell.ps1 | iex
```

Undo PowerShell dotfiles settings (keeps Starship installed by default):

```powershell
irm https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/undo-powershell.ps1 | iex
```

Requires **Git for Windows** on `PATH`. The script installs **chezmoi** with **`winget install --id twpayne.chezmoi`** (official id — **`Twpayne.Chezmoi` is invalid** and makes winget report “No package found”). If `chezmoi` is still missing afterward, it falls back to **[get.chezmoi.io](https://www.chezmoi.io/install/)** into **`%USERPROFILE%\.local\bin`** and fixes `PATH` for the current session.

Starship behavior is controlled by **`%USERPROFILE%\.config\starship.toml`** and profile initialization. See [Starship Configuration](https://starship.rs/config/) and [Starship Advanced Installation](https://starship.rs/installing/).

Then run `exec zsh` on macOS/Linux/WSL, or open a new terminal on Windows. Full steps and options: [Fresh install](#fresh-install).

---

## Documentation map

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Overview, install, updates, workflows, troubleshooting (this file). |
| [CHANGELOG.md](CHANGELOG.md) | Human-readable release history; must be updated when version-worthy files change. |
| [VERSION](VERSION) | Canonical SemVer string for the repo (must match `DOTFILES_VERSION` and the latest changelog heading). |
| [cursor/EXTENSIONS.md](cursor/EXTENSIONS.md) | Why each recommended Cursor/VS Code extension is listed; pairs with [`cursor/extensions.txt`](cursor/extensions.txt). |
| [cursor/extensions.txt](cursor/extensions.txt) | Extension ID manifest used by sync scripts (not read by Cursor automatically). |
| [cursor/user-rules.md](cursor/user-rules.md) | Exported Cursor user rules for version control; sync via scripts (see IDE section). |
| [install.sh](install.sh) | macOS / Ubuntu / WSL bootstrap. |
| [install-powershell.ps1](install-powershell.ps1) | Windows (native) PowerShell bootstrap. |
| [.gitattributes](.gitattributes) | Line endings (`LF` for hooks and `*.sh` on Windows). |
| [.githooks/pre-commit](.githooks/pre-commit) | Optional guard: stage `CHANGELOG.md` when dotfile sources change. |

---

## Project overview

chezmoi keeps a **source directory** (`~/.local/share/chezmoi/`) that mirrors what should exist in your home directory, then **applies** it with one command. Templates (`{{ if eq .chezmoi.os "darwin" }}`, and so on) let one file render differently per OS or host.

**Managed today:** zsh, PowerShell (Windows only via templates), Cursor/VS Code assets (via `run_after_apply`), Starship config, chezmoi metadata templates, and helper scripts under `scripts/`.

### Supported platforms

| Platform | Notes |
|----------|-------|
| **macOS** | Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`) |
| **Ubuntu WSL** | Windows 10/11 with WSL 2 running Ubuntu |
| **Ubuntu desktop / server** | Ubuntu 20.04+ |
| **AWS EC2** | Ubuntu AMIs; suitable for user-data scripts |
| **Any SSH server** | Hosts running zsh ≥ 5.0 |
| **Windows (native)** | PowerShell 7 + optional Windows PowerShell 5.1 — profiles and `dot*` commands via chezmoi (see [Windows PowerShell](#windows-powershell-native)) |

---

## Versioning

This project uses **[Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html)** (`MAJOR.MINOR.PATCH`):

- **MAJOR** — incompatible structural or bootstrap changes.
- **MINOR** — new features or substantial behavior changes, backwards-compatible for existing installs.
- **PATCH** — bug fixes, documentation releases, small refactors.

**Canonical surfaces** (all must match when you cut a release):

1. [`VERSION`](VERSION) — single line, e.g. `1.6.2` (no `v` prefix).
2. [`dot_zshrc.tmpl`](dot_zshrc.tmpl) — `export DOTFILES_VERSION="…"`.
3. [`CHANGELOG.md`](CHANGELOG.md) — new `## [x.y.z] — YYYY-MM-DD` section with notes.

Optional but useful: create an annotated Git tag for the same number (many teams use a `v` prefix on tags only, e.g. `v1.6.2`), then publish [GitHub Releases](https://github.com/martsamp77/marty-dotfiles/releases) from that tag.

---

## Fresh install

### Unix (macOS, Ubuntu, WSL) — one-liner (recommended)

```bash
bash <(curl -fsLS https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install.sh)
```

The script installs Homebrew (macOS if needed), `zsh`, `git`, `fzf`, `chezmoi`, sets zsh as the login shell, generates `en_US.UTF-8` on Ubuntu where needed, prefers SSH to GitHub with HTTPS fallback, and runs `chezmoi init --apply`. Then reload:

```bash
exec zsh
```

### Unix — manual steps

1. **Install zsh** — macOS: already default on recent releases. Ubuntu / WSL / AWS: `sudo apt install -y zsh` and `chsh -s $(which zsh)` (re-login).
2. **Install chezmoi** — macOS: `brew install chezmoi`. Ubuntu: `sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin` and add `~/.local/bin` to `PATH`.
3. **Initialize** — `chezmoi init --apply git@github.com:martsamp77/marty-dotfiles.git` (or the HTTPS URL).
4. **Reload** — `exec zsh`.

### Windows (native PowerShell)

One-liner (same as [Quick install](#quick-install)):

```powershell
irm https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install-powershell.ps1 | iex
```

From a clone: `.\install-powershell.ps1` in the repo root.

**Prerequisites:** **Git for Windows** must be installed (`git` on `PATH`). **winget** (App Installer) is optional but recommended; without it, chezmoi is installed only via the fallback below.

**What the bootstrap does**

1. Installs **chezmoi** if missing:
   - Prefer **`winget install --id twpayne.chezmoi -e`** — the manifest id is **`twpayne.chezmoi`** (all lowercase). Older docs or copy-paste sometimes use **`Twpayne.Chezmoi`**, which **does not exist** in winget and fails with *No package found* (exit code like **`-1978335212`**).
   - If `chezmoi` is still not available, runs the official PowerShell installer from **`https://get.chezmoi.io/ps1`**, installing the binary into **`%USERPROFILE%\.local\bin`**, refreshes machine+user `PATH`, and prepends `.local\bin` in the current session if needed.
2. Runs **`chezmoi init --apply`** against this repo (SSH to GitHub when your key is recognized for `martsamp77`, otherwise HTTPS), which deploys Windows-only templates (PowerShell profiles, optional **Starship** / **PSReadLine** via **`[data.ps]`** prompts on first init).
3. Ensures **both** PowerShell profile paths exist and re-applies each with **`chezmoi apply`**: **`%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`** (**pwsh**) and **`%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`** (**Windows PowerShell 5.1**). Parent folders are created if needed (so **`. $PROFILE`** works in either host).

**Manual chezmoi only:** `winget install --id twpayne.chezmoi -e --accept-package-agreements --accept-source-agreements` — or follow [chezmoi: Install](https://www.chezmoi.io/install/).

WSL Ubuntu shells still use the Unix flow above; Cursor on Windows uses Windows-side paths — see [Cursor and VS Code](#cursor-and-vs-code-ide-settings).

---

## Updates and daily workflow

### How updates reach your machines

- **zsh:** On each new session, `.zshrc` can run a background check against GitHub and invoke `chezmoi update --force` when `main` has moved (subshell + `disown` so the prompt is not blocked).
- **Manual:** Use the aliases below from any configured machine.

### Command cheat sheet (zsh)

| Task | Command |
|------|---------|
| Edit a managed file in the source tree | `dotedit ~/.zshrc` |
| Preview pending changes | `dotdiff` |
| Apply local source to the home directory | `dotapply` |
| Pull from GitHub and apply | `dotup` |
| Push local changes (IDE settings + full source tree) | `dotupload "…"` — see [dotupload](#dotupload-push-local-changes) |
| Upgrade IDEs and toolchain (separate from `dotup`) | `dottools` |
| Open a shell in the chezmoi source directory | `dots` |
| Commit and push manually | `dots && git add . && git commit -m "…" && git push` |

### chezmoi refreshes (plugins)

Plugins (Pure, zsh-autosuggestions, zsh-syntax-highlighting) are **externals** in [`.chezmoiexternal.toml`](.chezmoiexternal.toml), not vendored in this repo:

| Goal | Command |
|------|---------|
| First-time / normal apply | `chezmoi apply` |
| Force-refresh all externals now | `chezmoi apply --refresh-externals` |
| Pull dotfiles + refresh on schedule | `chezmoi update` (weekly refresh per `refreshPeriod`) |

### dotupload (push local changes)

[`scripts/dotupload.sh`](scripts/dotupload.sh) (zsh / macOS / Linux / WSL / Git Bash) and [`scripts/dotupload.ps1`](scripts/dotupload.ps1) (Windows PowerShell) copy **Cursor** (preferred) or **VS Code** `settings.json` from your live User folder into [`cursor/settings.json`](cursor/settings.json), then run **`git add -A`**, **`git commit`**, and **`git push`** on the **current branch** in the chezmoi source directory.

You must pass a **descriptive commit message** (at least 12 characters; vague one-word messages are rejected):

```bash
dotupload "Sync Cursor tab size, format on save, and Python Ruff defaults"
```

Optional flags (any order **before** the message):

| Flag | Effect |
|------|--------|
| `--rules` | Run [`scripts/cursor-export-rules.sh`](scripts/cursor-export-rules.sh) → `cursor/user-rules.md` (needs `sqlite3`; PowerShell runs it via `bash.exe`, Git Bash is also supported). |
| `--extensions` | Overwrite `cursor/extensions.txt` from `cursor --list-extensions` (comments in the manifest are lost). |
| `--snippets` | Copy `*.code-snippets` from Cursor `User/snippets` into `cursor/snippets/`. |

**Not covered:** `keybindings.json` is still generated by [`run_after_apply-cursor.sh.tmpl`](run_after_apply-cursor.sh.tmpl) on apply. Edits under `~` to **templated** files are not merged into `.tmpl` sources; use `dotedit` / `chezmoi merge` as usual. If `chezmoi diff` shows drift, `dotupload` only prints a reminder.

If [.githooks/pre-commit](.githooks/pre-commit) is enabled, commits that touch paths like `cursor/` or `scripts/` usually need **[CHANGELOG.md](CHANGELOG.md)** staged; `dotupload` reminds you before committing. On Windows, close Cursor briefly if `settings.json` is locked.

---

## Maintaining this repository

### Changelog discipline

Any commit that changes **managed configuration** should also update **[CHANGELOG.md](CHANGELOG.md)**:

- For work in progress, add bullets under `## [Unreleased]` (see the changelog file).
- For a release, add `## [x.y.z] — date`, move items out of Unreleased, and bump **`VERSION`** and **`DOTFILES_VERSION`** together.

### Enforcing changelog updates (optional hook)

This repo includes [`.githooks/pre-commit`](.githooks/pre-commit). After cloning, enable it once:

```bash
git config core.hooksPath .githooks
```

On Windows with **Git for Windows**, hooks run with the bundled Bash; the executable bit is stored in Git (`100755`) for `pre-commit`. [`.gitattributes`](.gitattributes) keeps hook and `*.sh` files as **LF** so POSIX `sh` does not see stray `\r` characters.

The hook **requires `CHANGELOG.md` to be staged** whenever staged paths include things like `dot_zshrc.tmpl`, `.chezmoi/`, `cursor/`, `scripts/`, `install*.sh`, `Documents/`, `run_after_apply*`, `dot_config/`, or `VERSION`. For rare commits where that is inappropriate, use:

```bash
SKIP_CHANGELOG=1 git commit -m "…"
```

### Commit messages

[Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:`) keep `git log` readable and align with the changelog narrative.

---

## Change history

Authoritative release notes: **[CHANGELOG.md](CHANGELOG.md)** (reconciled against the full [commit history on `main`](https://github.com/martsamp77/marty-dotfiles/commits/main/)).

---

## How it works (chezmoi)

### Source file naming

chezmoi maps special prefixes to paths under `$HOME`:

| Source name | Deployed as |
|-------------|-------------|
| `dot_zshrc.tmpl` | `~/.zshrc` |
| `Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl` | `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1` (Windows, **pwsh** only) |
| `Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1.tmpl` | `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1` (Windows, **5.1** only) |

The `~/.zsh/` plugin directories come from **externals** (see [Updates](#updates-and-daily-workflow)), not from committed plugin trees.

### External plugins (excerpt)

Defined in [`.chezmoiexternal.toml`](.chezmoiexternal.toml):

```toml
[".zsh/pure"]
    type          = "git-repo"
    url           = "https://github.com/sindresorhus/pure.git"
    refreshPeriod = "168h"

[".zsh/zsh-autosuggestions"]
    type          = "git-repo"
    url           = "https://github.com/zsh-users/zsh-autosuggestions.git"
    refreshPeriod = "168h"

[".zsh/zsh-syntax-highlighting"]
    type          = "git-repo"
    url           = "https://github.com/zsh-users/zsh-syntax-highlighting.git"
    refreshPeriod = "168h"
```

On a **new** machine, `chezmoi init --apply git@github.com:martsamp77/marty-dotfiles.git` fetches this config, clones plugins into `~/.zsh/`, and deploys `.zshrc` — no separate plugin install step.

### Why chezmoi (short)

- **Templates** — one source, many targets (OS / host aware).
- **Git-native** — push/pull like any repo.
- **No symlinks** — copies avoid accidental corruption of the source.
- **Single binary** — easy to install everywhere.
- **Idempotent** — `chezmoi apply` is safe to repeat.

More: [chezmoi.io](https://www.chezmoi.io/).

---

## Features

### History

- 1,000,000-line history file (`~/.zsh_history`)
- Shared across terminals (`SHARE_HISTORY`), timestamps (`EXTENDED_HISTORY`), no exact duplicates (`HIST_IGNORE_ALL_DUPS`)
- Commands prefixed with a space omitted (`HIST_IGNORE_SPACE`)
- **API key masking** — `zshaddhistory` redacts common secret patterns before write (`sk-…`, `Bearer …`, `*_KEY=…`, and similar); the command still runs

### Completion

- Menu-driven tab completion, case-insensitive / partial match
- Kill completion shows formatted `ps` output
- Colorized listings with `LS_COLORS` on Linux/WSL
- `.zcompdump` rebuilt at most once per 24 hours

### Prompt (Pure)

[Pure](https://github.com/sindresorhus/pure) — minimal, no Nerd Fonts, consistent over SSH. Managed as a chezmoi external under `~/.zsh/pure/`.

```
~/dev/myproject master*
❯
```

Color overrides (dark backgrounds) use `zstyle` — cyan path, bright git context, yellow dirty, magenta success prompt, red error prompt, green user@host on SSH.

### zsh-autosuggestions

[History-first, then completion](https://github.com/zsh-users/zsh-autosuggestions); short buffers ignore completion noise; large pastes capped; ghost text styled distinct from comments.

### zsh-syntax-highlighting

[Real-time highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) — load **last** so it wraps all ZLE widgets correctly.

### fzf

If `fzf` is installed, `~/.fzf.zsh` is sourced — **Ctrl+R** history, **Ctrl+T** files, colors tuned for dark backgrounds.

### OS-aware aliases

| Alias | macOS | Linux / WSL / AWS |
|-------|-------|-------------------|
| `update` | `brew update && brew upgrade` | `sudo apt update && sudo apt upgrade -y` |
| `ls` | `ls -G` | `ls --color=auto` |

### PuTTY / SSH compatibility

Emacs keymap (`bindkey -e`), multiple Home/End escape sequences, and WSL **Ctrl+V** paste via the Windows clipboard when applicable. See [PuTTY setup](#putty-setup-windows).

---

## Cursor and VS Code IDE settings

After every `chezmoi apply`, [`run_after_apply-cursor.sh.tmpl`](run_after_apply-cursor.sh.tmpl) copies repo settings into each editor **if** its user config directory exists. Extensions are **not** installed on apply (keeps `dotup` fast); use the sync scripts when you need them.

### Documentation links

- **Extension rationale:** [cursor/EXTENSIONS.md](cursor/EXTENSIONS.md)
- **Extension IDs:** [cursor/extensions.txt](cursor/extensions.txt)
- **Changelog** (when IDE files change): [CHANGELOG.md](CHANGELOG.md)

### What is synced

| File | Role |
|------|------|
| `cursor/settings.json` | Editor preferences, theme, Peacock colors |
| `keybindings.json` | Generated inline in the run script (OS-aware workspace path) |
| `cursor/extensions.txt` | Manifest for sync scripts |
| `cursor/snippets/*.code-snippets` | Custom snippets |
| `cursor/mcp.json` | Global MCP config when present |
| `cursor/user-rules.md` | Version-controlled rules; use import/export scripts (not auto-deployed to DB) |

### Settings paths by OS

| IDE | Windows | macOS | Linux |
|-----|---------|-------|-------|
| Cursor | `%APPDATA%\Cursor\User\` | `~/Library/Application Support/Cursor/User/` | `~/.config/Cursor/User/` |
| VS Code | `%APPDATA%\Code\User\` | `~/Library/Application Support/Code/User/` | `~/.config/Code/User/` |

### Extension directories (Cursor)

| OS | Location |
|----|----------|
| Windows | `%USERPROFILE%\.cursor\extensions\` |
| macOS | `~/Library/Application Support/Cursor/extensions/` |
| Linux | `~/.cursor/extensions/` |
| WSL (Cursor on Windows) | Windows path above |

### Updating `cursor/extensions.txt`

1. Edit the manifest, or dump from the CLI: `cursor --list-extensions > cursor/extensions.txt` (comments in the file may be lost if you overwrite blindly).
2. Install missing extensions: `./scripts/cursor-sync-extensions.sh` or the PowerShell one-liner in the manifest header.

**Windows PowerShell** (from repo root):

```powershell
Get-Content cursor\extensions.txt | Where-Object { $_ -notmatch '^#' -and $_ -match '\S' } | ForEach-Object { cursor --install-extension $_ }
```

**macOS / Linux / WSL:**

```bash
grep -v '^#' cursor/extensions.txt | grep -v '^[[:space:]]*$' | while read -r ext; do
  cursor --install-extension "$ext"
done
```

VS Code (same list, skips `anysphere.*`): `./scripts/vscode-sync-extensions.sh`

### User rules (SQLite)

```bash
./scripts/cursor-export-rules.sh   # → cursor/user-rules.md
./scripts/cursor-import-rules.sh   # import on a new machine (close Cursor first)
```

Requires `sqlite3` and `xxd` where noted in the scripts.

### Tool upgrades

`dottools` upgrades Cursor, VS Code, git, chezmoi, zsh, and fzf when installed — intentionally separate from `dotup`.

---

## Adding a new dotfile

```bash
chezmoi add ~/.gitconfig
dotedit ~/.gitconfig
dotdiff
dotapply
dots && git add . && git commit -m "Add .gitconfig" && git push
```

Remember to update [CHANGELOG.md](CHANGELOG.md) for meaningful changes (and enable the [git hook](#maintaining-this-repository) if you use it).

---

## Windows PowerShell (native)

PowerShell profiles are managed by chezmoi **only on Windows** (`chezmoi.os == "windows"`). Preferences live in **`%USERPROFILE%\.config\chezmoi\chezmoi.toml`** under `[data.ps]` (`starship`, `prediction`, `predictionview`). First `chezmoi init` on Windows runs prompts from `.chezmoi.toml.tmpl`.

| Task | Command |
|------|---------|
| Bootstrap a new PC | [`install-powershell.ps1`](install-powershell.ps1) one-liner in script header |
| Pull + apply | `dotup` |
| Push local IDE + repo changes | `dotupload "…"` — see [dotupload](#dotupload-push-local-changes) |
| Inspect `[data.ps]` | `dotps show` |
| Re-run prompts | `dotps wizard` |
| Disable Starship + prediction | `undotps` or `dotps off` |
| Reset `[data.ps]` | `dotps reset` |
| Upgrade pwsh, chezmoi, Starship, Cursor, VS Code | `dottools` |

The profile mirrors zsh-style navigation: **`cd`** prints a **directories-first** listing of the folder you landed in (like `cd … && ls`). **`ls`** and **`dir`** use the same layout; **`Get-ChildItem`** / **`gci`** are unchanged if you want the stock table. Tab completion uses **PSReadLine** menu mode plus tinted command/completion colors when your terminal supports ANSI.

`dottools` uses **`winget upgrade --id twpayne.chezmoi`** for chezmoi (same id as the bootstrap — not `Twpayne.Chezmoi`).

If you merge `.chezmoi.toml.tmpl` into an existing `chezmoi.toml`, back up first. [`install-starship.ps1`](install-starship.ps1) remains available for Starship-only installs.

**Starship config** is managed as [`dot_config/starship.toml`](dot_config/starship.toml) (deploys to **`%USERPROFILE%\.config\starship.toml`**). It uses a rich **`format = "$all"`**, **`right_format`** for duration + clock, and **transient prompt** in PowerShell when Starship is on. Edit via **`chezmoi edit ~/.config/starship.toml`** then **`dotapply`**, or open the live file after apply. Tune with **`starship explain`**; override the file path with **`STARSHIP_CONFIG`** ([Starship: Configuration](https://starship.rs/config/)).

---

## Auto-apply on SSH login / EC2 user-data

```bash
bash <(curl -fsLS https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install.sh)
```

After the first apply, background auto-sync in `.zshrc` can pull future updates when you open a shell.

---

## PuTTY setup (Windows)

Pure uses `❯` (U+276F). PuTTY needs a font that includes it — **Cascadia Code** from [microsoft/cascadia-code/releases](https://github.com/microsoft/cascadia-code/releases) (install from `ttf/` for all users).

### Suggested settings

**Window → size:** Columns `120`, Rows `40`.

**Appearance:** Underline cursor, blink on, **Cascadia Code Light** 11, ClearType, 3 px text gap, hide pointer when typing.

**Translation:** Remote character set **UTF-8**; Unicode line drawing.

**Connection:** Seconds between keepalives `30`.

**Scrollback:** `20000` lines.

**Session → Logging (optional):** e.g. `C:\PuTTYLogs\&H_&Y&M&D.log`

---

## API keys and local secrets

Never commit secrets. Use **`~/.zshrc.local`** per machine (not managed by chezmoi):

```bash
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

Create after apply as needed:

```bash
cat >> ~/.zshrc.local << 'EOF'
export MEM0_API_KEY="sk-…"
export OPENAI_API_KEY="sk-…"
EOF
```

---

## Templates

chezmoi evaluates Go templates in `.tmpl` sources:

```
{{ if eq .chezmoi.os "darwin" }}
# macOS-only
{{ else if eq .chezmoi.os "linux" }}
# Linux-only
{{ end }}

{{ if eq .chezmoi.hostname "work-laptop" }}
export WORK_PROXY=http://proxy.corp:3128
{{ end }}
```

---

## Troubleshooting

**`chezmoi update` fails with merge conflict / stuck rebase**

```bash
chezmoi cd
git status
git rebase --abort
chezmoi update
exec zsh
```

**Prompt / aliases not updated**

```bash
chezmoi apply
exec zsh
```

**Plugins missing under `~/.zsh/`**

```bash
chezmoi apply --refresh-externals
```

**Auto-sync never runs**

Ensure chezmoi was initialized with apply and `~/.local/share/chezmoi/.git` exists.

**`chezmoi` not in PATH (Linux)**

```bash
export PATH="$HOME/.local/bin:$PATH"
```

**Windows: winget “No package found” when installing chezmoi**

The winget package id is **`twpayne.chezmoi`**. **`Twpayne.Chezmoi`** is wrong and triggers that error. Install with:

```powershell
winget install --id twpayne.chezmoi -e --accept-package-agreements --accept-source-agreements
```

Or re-run [`install-powershell.ps1`](install-powershell.ps1) (it uses the correct id and can fall back to **get.chezmoi.io**).

**Windows: `chezmoi` not on PATH after bootstrap**

Open a **new** terminal so `PATH` picks up winget’s install, or add **`%USERPROFILE%\.local\bin`** if you used the **get.chezmoi.io** fallback.

**Windows: `. $PROFILE` says the profile path is not recognized**

Usually the file is missing or you’re in the **wrong host** (`$PROFILE` differs for **pwsh** vs **powershell.exe**). Re-run [`install-powershell.ps1`](install-powershell.ps1), or apply both targets explicitly:

```powershell
chezmoi apply "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
chezmoi apply "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
```

Then reload with **`. "$PROFILE"`** in the same host you use day to day.

**Diagnostics**

```bash
chezmoi doctor
chezmoi diff
chezmoi apply --dry-run
```

**SSH to GitHub**

```bash
ssh -T git@github.com
```

**Prompt colors wrong on light themes / PuTTY**

Pure and legacy colors target **dark** backgrounds. PuTTY: Connection → Data → Terminal-type string `xterm-256color`.

**`dircolors` on macOS**

Expected: the config guards with `command -v dircolors`.

---

## Why chezmoi?

- No symlink fragility
- OS- and host-aware templates
- Git workflow and history
- Optional encryption for secrets (age/GPG)
- Single static binary
- Repeatable, idempotent applies

---

*Fork, steal, adapt — happy terminal-ing.*  
*— Marty (Birmingham, AL)*
