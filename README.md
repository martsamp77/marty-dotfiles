# Marty's Dotfiles

Personal configuration managed with [chezmoi](https://www.chezmoi.io/) for **zsh** (macOS/Linux/WSL) and a simple copy-based script for **Windows PowerShell**. The two systems are independent — chezmoi handles Linux/Mac, a lightweight install script handles Windows.

| | |
|---|---|
| **Current version** | **2.0.0** — see [CHANGELOG.md](CHANGELOG.md) |
| **Runtime check** | `echo $DOTFILES_VERSION` (zsh, after apply) |

---

## Table of contents

1. [Quick install](#quick-install)
2. [Project overview](#project-overview)
3. [Fresh install](#fresh-install)
4. [Daily workflow](#daily-workflow)
5. [How it works (chezmoi)](#how-it-works-chezmoi)
6. [Features](#features)
7. [Adding a new dotfile](#adding-a-new-dotfile)
8. [Windows PowerShell](#windows-powershell)
9. [Auto-apply on SSH login / EC2 user-data](#auto-apply-on-ssh-login--ec2-user-data)
10. [PuTTY setup (Windows)](#putty-setup-windows)
11. [API keys and local secrets](#api-keys-and-local-secrets)
12. [Templates](#templates)
13. [Troubleshooting](#troubleshooting)
14. [Why chezmoi?](#why-chezmoi)

---

## Quick install

**macOS / Linux / WSL**

```bash
bash <(curl -fsLS https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install.sh)
```

**Windows PowerShell** — clone the repo, then:

```powershell
.\windows\install.ps1
```

Requires **Git for Windows** on `PATH`. Full steps: [Fresh install](#fresh-install).

---

## Project overview

chezmoi keeps a **source directory** (`~/.local/share/chezmoi/`) that mirrors what should exist in your home directory, then **applies** it with one command. Templates let one file render differently per OS or host.

**Managed by chezmoi:** zsh config, Starship prompt config, zsh plugins (via externals), chezmoi metadata, and helper scripts.

**Managed independently (Windows):** PowerShell profile — copy-based via [`windows/`](windows/). No chezmoi required on Windows.

### Supported platforms

| Platform | Notes |
|----------|-------|
| **macOS** | Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`) |
| **Ubuntu WSL** | Windows 10/11 with WSL 2 running Ubuntu |
| **Ubuntu desktop / server** | Ubuntu 20.04+ |
| **AWS EC2** | Ubuntu AMIs; suitable for user-data scripts |
| **Any SSH server** | Hosts running zsh ≥ 5.0 |
| **Windows (native)** | PowerShell 7 + Windows PowerShell 5.1 — see [Windows PowerShell](#windows-powershell) |

---

## Fresh install

### Unix (macOS, Ubuntu, WSL) — one-liner

```bash
bash <(curl -fsLS https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install.sh)
```

Installs Homebrew (macOS if needed), `zsh`, `git`, `fzf`, `chezmoi`, sets zsh as login shell, generates `en_US.UTF-8` on Ubuntu, prefers SSH to GitHub with HTTPS fallback, and runs `chezmoi init --apply`. Then reload:

```bash
exec zsh
```

### Unix — manual steps

1. **Install zsh** — macOS: already default. Ubuntu/WSL/EC2: `sudo apt install -y zsh && chsh -s $(which zsh)` (re-login).
2. **Install chezmoi** — macOS: `brew install chezmoi`. Ubuntu: `sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin` and add `~/.local/bin` to `PATH`.
3. **Initialize** — `chezmoi init --apply git@github.com:martsamp77/marty-dotfiles.git`
4. **Reload** — `exec zsh`

### Windows (native PowerShell)

**Prerequisites:** Git for Windows on `PATH`.

```powershell
git clone git@github.com:martsamp77/marty-dotfiles.git    # or HTTPS
.\windows\install.ps1
```

Open a new PowerShell window. Run `dotsync` for future updates.

---

## Daily workflow

### zsh command cheat sheet

| Task | Command |
|------|---------|
| Edit a managed file | `dotedit ~/.zshrc` |
| Preview pending changes | `dotdiff` |
| Apply source to home | `dotapply` |
| Open chezmoi source dir | `dots` |
| Upgrade tools | `dottools` |

### Applying changes manually

Edit source files in the chezmoi source dir (`dots` to navigate there), then:

```bash
dotapply        # apply to $HOME
exec zsh        # reload shell
```

### chezmoi plugin refreshes

Plugins (Pure, zsh-autosuggestions, zsh-syntax-highlighting) are externals in [`.chezmoiexternal.toml`](.chezmoiexternal.toml) and refresh weekly:

```bash
chezmoi apply --refresh-externals    # force refresh now
```

---

## How it works (chezmoi)

### Source file naming

chezmoi maps special prefixes to paths under `$HOME`:

| Source name | Deployed as |
|-------------|-------------|
| `dot_zshrc.tmpl` | `~/.zshrc` |
| `dot_config/starship.toml` | `~/.config/starship.toml` |

The `~/.zsh/` plugin directories come from **externals**, not committed trees.

Windows PowerShell profiles are **not** managed by chezmoi — see [`windows/`](windows/).

### External plugins

Defined in [`.chezmoiexternal.toml`](.chezmoiexternal.toml):

```toml
[".zsh/pure"]
    type          = "git-repo"
    url           = "https://github.com/sindresorhus/pure.git"
    refreshPeriod = "168h"
```

On a new machine, `chezmoi init --apply` fetches this config, clones plugins into `~/.zsh/`, and deploys `.zshrc` — no separate plugin install step.

---

## Features

### History

- 1,000,000-line history file (`~/.zsh_history`)
- Shared across terminals, timestamped, no exact duplicates
- Commands prefixed with a space omitted
- **API key masking** — `zshaddhistory` redacts common secret patterns (`sk-…`, `Bearer …`, `*_KEY=…`) before write; command still runs

### Completion

- Menu-driven tab completion, case-insensitive / partial match
- Kill completion shows formatted `ps` output
- Colorized listings with `LS_COLORS` on Linux/WSL
- `.zcompdump` rebuilt at most once per 24 hours

### Prompt (Pure)

[Pure](https://github.com/sindresorhus/pure) — minimal, async git, no Nerd Fonts required. Consistent over SSH.

```
~/dev/myproject master*
❯
```

Color overrides (dark backgrounds): cyan path, bright git context, yellow dirty, magenta success, red error, green user@host on SSH.

### zsh-autosuggestions

History-first suggestions; short buffers ignore completion noise; large pastes capped; ghost text styled distinct from comments.

### zsh-syntax-highlighting

Real-time highlighting — loaded last so it wraps all ZLE widgets correctly.

### fzf

If `fzf` is installed, `~/.fzf.zsh` is sourced — **Ctrl+R** history search, **Ctrl+T** file picker.

### OS-aware aliases

| Alias | macOS | Linux / WSL |
|-------|-------|-------------|
| `update` | `brew update && brew upgrade` | `sudo apt update && sudo apt upgrade -y` |
| `ls` | `ls -G` | `ls --color=auto` |

### PuTTY / SSH compatibility

Emacs keymap, multiple Home/End escape sequences, WSL Ctrl+V paste. See [PuTTY setup](#putty-setup-windows).

---

## Adding a new dotfile

```bash
chezmoi add ~/.gitconfig
dotedit ~/.gitconfig
dotdiff
dotapply
dots && git add . && git commit -m "Add .gitconfig" && git push
```

---

## Windows PowerShell

No chezmoi, no Starship. Source of truth: [`windows/profile.ps1`](windows/profile.ps1).

### How it works

- **[`windows/install.ps1`](windows/install.ps1)** copies `windows/profile.ps1` to both profile locations and saves the repo path to `~/.marty-dotfiles.json`.
- **`dotsync`** (alias in the profile) runs `git pull` then re-copies the profile.

| Task | Command |
|------|---------|
| First-time setup | `.\windows\install.ps1` from repo root |
| Sync profile after repo changes | `dotsync` |
| Upgrade PowerShell and Git | `.\windows\tools.ps1` |

### Profile locations

`windows/install.ps1` writes to both:
- `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` (pwsh 7)
- `%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` (Windows PowerShell 5.1)

---

## Auto-apply on SSH login / EC2 user-data

```bash
bash <(curl -fsLS https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install.sh)
```

---

## PuTTY setup (Windows)

Pure uses `❯` (U+276F). PuTTY needs a font that includes it — **Cascadia Code** from [microsoft/cascadia-code/releases](https://github.com/microsoft/cascadia-code/releases) (install from `ttf/` for all users).

**Window → size:** Columns `120`, Rows `40`.

**Appearance:** Underline cursor, blink on, **Cascadia Code Light** 11, ClearType, 3 px text gap, hide pointer when typing.

**Translation:** Remote character set **UTF-8**; Unicode line drawing.

**Connection:** Seconds between keepalives `30`.

**Scrollback:** `20000` lines.

---

## API keys and local secrets

Never commit secrets. Use **`~/.zshrc.local`** per machine (not managed by chezmoi):

```bash
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

Create after apply:

```bash
cat >> ~/.zshrc.local << 'EOF'
export OPENAI_API_KEY="sk-…"
export MY_TOKEN="…"
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

**`chezmoi` not in PATH (Linux)**

```bash
export PATH="$HOME/.local/bin:$PATH"
```

**Windows: `dotsync` says repo not found**

Re-run install with the explicit path:

```powershell
.\windows\install.ps1 -RepoPath "C:\path\to\marty-dotfiles"
```

**Windows: profile not loading after install**

Re-run `.\windows\install.ps1` — it overwrites both profile locations and prints what it wrote.

**Diagnostics (zsh)**

```bash
chezmoi doctor
chezmoi diff
chezmoi apply --dry-run
dotdiag          # startup diagnostics (warn level)
dotdiag debug    # full dump
```

**SSH to GitHub**

```bash
ssh -T git@github.com
```

**Prompt colors wrong on light themes / PuTTY**

Pure targets dark backgrounds. PuTTY: Connection → Data → Terminal-type string `xterm-256color`.

---

## Why chezmoi?

- No symlink fragility
- OS- and host-aware templates
- Git workflow and history
- Single static binary
- Repeatable, idempotent applies

---

*Fork, steal, adapt — happy terminal-ing.*
*— Marty (Birmingham, AL)*
