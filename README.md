# Marty's Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/) — one config file, every machine, always in sync.

Supports:

| Platform | Notes |
|---|---|
| **macOS** | Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`) |
| **Ubuntu WSL** | Windows 10/11 with WSL 2 running Ubuntu |
| **Ubuntu desktop / server** | Any Ubuntu 20.04+ machine |
| **AWS EC2** | Ubuntu AMIs; works in user-data scripts |
| **Any SSH server** | Any host running zsh ≥ 5.0 |

---

## How It Works

### chezmoi

[chezmoi](https://www.chezmoi.io/) is the engine. It manages dotfiles by keeping a **source directory** (`~/.local/share/chezmoi/`) that mirrors what should end up in your home directory, then applying it with a single command. Key benefits over manual symlinks or a bare git repo:

- **Templates** — the same source file can render differently per OS, hostname, or any machine-specific variable. The `{{ if eq .chezmoi.os "darwin" }}` blocks in `.zshrc` are evaluated at apply time, so macOS gets `brew upgrade` while Linux gets `apt upgrade -y` — from one source file.
- **Git-native** — the source directory is just a git repo. Push to GitHub, pull on any machine, apply in seconds.
- **No symlinks** — chezmoi copies files, so accidental edits to `~/.zshrc` don't corrupt the source.
- **Single binary** — one static binary, no runtime dependencies.

### Source file naming

chezmoi uses special prefixes to map source filenames to home-directory paths:

| Source name | Deployed as |
|---|---|
| `dot_zshrc` | `~/.zshrc` |
| `dot_zsh/` | `~/.zsh/` (entire directory tree) |
| `dot_zsh/zsh-autosuggestions/` | `~/.zsh/zsh-autosuggestions/` |

### The `dot_zsh/` directory — vendored plugins

The `dot_zsh/` directory maps to `~/.zsh/` on every machine. It contains the **full source trees** for both Zsh plugins, committed directly into this repository:

```
dot_zsh/
├── zsh-autosuggestions/      →  ~/.zsh/zsh-autosuggestions/
└── zsh-syntax-highlighting/  →  ~/.zsh/zsh-syntax-highlighting/
```

This is called **vendoring**. Instead of having a setup script clone the plugin repos over the internet at install time, the plugin files are already in the chezmoi repo. Running `chezmoi apply` copies them to the right place — no network access needed at setup or at shell startup.

**Why vendor instead of using `.chezmoiexternal.toml`?**

chezmoi also supports pulling plugins from URLs at apply time via `.chezmoiexternal.toml`. Vendoring was chosen here because:

- Works on air-gapped servers and restricted EC2 instances with no outbound git/HTTPS
- Plugins are at a known, tested version — no surprise breakage from upstream changes
- `chezmoi apply` completes in one step with zero extra network calls
- The plugins work immediately after SSH login on a freshly initialized machine

The trade-off is a larger repository. To update a plugin, `cd` into its subdirectory, `git pull`, then commit the change to `marty-dotfiles`.

---

## Features

### History

- 1,000,000-line history file (`~/.zsh_history`)
- Shared across all open terminal windows in real time (`SHARE_HISTORY`)
- Timestamps recorded for every entry (`EXTENDED_HISTORY`)
- Exact duplicates never stored (`HIST_IGNORE_ALL_DUPS`)
- Commands prefixed with a space are never saved (`HIST_IGNORE_SPACE`) — useful for passwords

### Completion

- Menu-driven tab completion with arrow-key navigation
- Case-insensitive and partial-match support
- Kill-process completion shows a formatted `ps` output
- Colorized with `LS_COLORS` on Linux/WSL
- `.zcompdump` rebuilt at most once per 24 hours for fast startup

### Prompt

```
marty@myserver ~/projects/foo (main) $
```

- `%F{10}` bright green — `user@host`
- `%F{14}` bright cyan — current directory
- `%F{9}` bright red — git branch (via `vcs_info`, built into zsh)
- Chosen specifically for readability on **dark backgrounds**: PuTTY default black, SSH sessions, Windows Terminal dark themes, tmux

### zsh-autosuggestions

[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) shows ghost-text command suggestions as you type, drawn from your command history — identical to the Fish shell experience.

- As you type, a greyed-out suggestion appears to the right of your cursor
- Press **→** (right arrow) or **End** to accept the full suggestion
- Press **Ctrl+→** to accept one word at a time
- Completely non-intrusive — keep typing to ignore it

**Why it's vendored in `dot_zsh/`:** The plugin is sourced from `~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh`. chezmoi deploys that file by copying `dot_zsh/zsh-autosuggestions/` to `~/.zsh/zsh-autosuggestions/` at apply time.

### zsh-syntax-highlighting

[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) colors your command line in real time as you type — before you hit Enter.

- **Green** — valid, recognized command
- **Red** — unknown command or typo (catch errors before running)
- **Yellow** — command arguments and flags
- **Cyan** — shell built-ins and keywords
- Strings, paths, variables, and redirections are all distinctly colored

**Why load it last:** Syntax highlighting works by wrapping zsh line editor (ZLE) widgets. It must be sourced _after_ all other plugins and key bindings so it can wrap them all correctly. Loading it earlier breaks other widget bindings.

**Why it's vendored in `dot_zsh/`:** Same pattern as autosuggestions — deployed to `~/.zsh/zsh-syntax-highlighting/` by chezmoi.

### fzf (fuzzy finder)

If `fzf` is installed, `.zshrc` sources `~/.fzf.zsh` automatically.

- **Ctrl+R** — interactive fuzzy history search (replaces the default history search)
- **Ctrl+T** — fuzzy file picker, inserts the selected path at the cursor
- Colors tuned for dark terminal backgrounds

### Auto-sync on every shell session

Every time you open a terminal or SSH into a machine, `.zshrc` silently checks GitHub for dotfile updates in the background:

1. `git fetch origin main` — check for new commits (no download yet)
2. Compare `HEAD` vs `origin/main` — if equal, done
3. If different: run `chezmoi update --force` — pull + apply
4. Print a one-line status message

The entire process runs in a background subshell (`&` + `disown`) so it **never delays your prompt**. You'll only see a message when an actual update occurs.

### PuTTY / SSH terminal compatibility

Key bindings are set with `bindkey -e` (Emacs mode) for maximum compatibility across:

- PuTTY (Windows SSH client)
- MobaXterm
- Windows Terminal + WSL
- macOS Terminal / iTerm2
- Any standard SSH session

Home and End key sequences are bound both via `terminfo` (standard) and raw escape sequences (`^[[H` / `^[[F`) as a fallback for PuTTY, which often sends the wrong sequences.

### OS-aware aliases (via chezmoi templates)

| Alias | macOS | Linux / WSL / AWS |
|---|---|---|
| `update` | `brew update && brew upgrade` | `sudo apt update && sudo apt upgrade -y` |
| `ls` | `ls -G` (BSD color) | `ls --color=auto` (GNU color) |

---

## Quick Start

### 1. Install zsh (if not already the default)

**macOS** — zsh is default since macOS Catalina.

**Ubuntu / WSL / AWS:**
```bash
sudo apt install -y zsh
chsh -s $(which zsh)
# Log out and back in (or reconnect via SSH)
```

### 2. Install chezmoi

**macOS:**
```bash
brew install chezmoi
```

**Ubuntu / WSL / AWS (no Homebrew):**
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"
```

### 3. Initialize and apply dotfiles

```bash
# SSH (recommended — passwordless if your key is added to GitHub):
chezmoi init --apply git@github.com:martsamp77/marty-dotfiles.git

# HTTPS (no SSH key needed):
chezmoi init --apply https://github.com/martsamp77/marty-dotfiles.git
```

This single command:
- Clones the repo to `~/.local/share/chezmoi/`
- Renders all templates for your OS
- Copies `dot_zsh/` → `~/.zsh/` (plugins land on disk, no separate clone)
- Copies `dot_zshrc` → `~/.zshrc`

### 4. Reload the shell

```bash
source ~/.zshrc
# or open a new terminal / reconnect via SSH
```

Your shell now has full history, syntax highlighting, autosuggestions, the prompt, and auto-sync on every future session.

---

## Auto-apply on SSH Login (One-liner Bootstrap)

For a fresh server where you want dotfiles applied the moment you log in for the first time, add this to the server's `~/.profile` or run it in a user-data script:

```bash
# Install chezmoi and apply dotfiles in one shot
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply \
    git@github.com:martsamp77/marty-dotfiles.git
```

After that, the auto-sync block in `.zshrc` handles all future updates automatically.

---

## Daily Workflow

| Task | Command |
|---|---|
| Edit a dotfile | `dotedit ~/.zshrc` |
| Preview pending changes | `dotdiff` |
| Apply locally | `dotapply` |
| Pull from GitHub + apply | `dotup` |
| cd to source directory | `dots` |
| Commit and push a change | `dots && git add . && git commit -m "..." && git push` |

---

## Adding a New Dotfile

```bash
# Tell chezmoi to track it
chezmoi add ~/.gitconfig

# Edit via chezmoi (so edits go to the source, not the live file)
dotedit ~/.gitconfig

# Preview
dotdiff

# Apply locally
dotapply

# Push to GitHub so all other machines get it on next shell open
dots && git add . && git commit -m "Add .gitconfig" && git push
```

---

## Templates

chezmoi evaluates Go template syntax inside any source file. Use this for per-machine or per-OS differences:

```
# OS branch
{{ if eq .chezmoi.os "darwin" }}
# macOS-only config
{{ else if eq .chezmoi.os "linux" }}
# Linux-only config
{{ end }}

# Hostname branch
{{ if eq .chezmoi.hostname "work-laptop" }}
export WORK_PROXY=http://proxy.corp:3128
{{ end }}
```

---

## Troubleshooting

**Plugins not loading**

The `.zshrc` will attempt a silent `git clone` fallback if `~/.zsh/zsh-autosuggestions/` or `~/.zsh/zsh-syntax-highlighting/` is missing. If that also fails, check that `git` is installed and GitHub is reachable:
```bash
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
```
Then re-run `chezmoi apply` to restore the vendored versions.

**Auto-sync not running**

The sync block checks for `~/.local/share/chezmoi/.git`. If chezmoi wasn't initialized with `--apply`, that directory may not exist:
```bash
chezmoi init git@github.com:martsamp77/marty-dotfiles.git
chezmoi apply
```

**chezmoi command not found**

chezmoi is installed to `~/.local/bin`. Make sure it's in your PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
which chezmoi
```

**Diagnostics**
```bash
chezmoi doctor          # Check for common issues
chezmoi diff            # See what would change
chezmoi apply --dry-run # Apply without writing anything
```

**SSH key not accepted by GitHub**
```bash
ssh -T git@github.com   # Should print: Hi martsamp77! ...
```

**Prompt colors look wrong**

The prompt uses bright ANSI colors (`%F{10}` = bright green, `%F{14}` = bright cyan). These look best on dark/black backgrounds. In PuTTY: Connection → Data → Terminal-type string should be `xterm-256color`.

**`dircolors` not found (macOS)**

This is expected and handled — the `dircolors` call is guarded with `command -v dircolors`. On macOS, `ls` uses its own `-G` flag for color instead.

---

## Why chezmoi?

- **No symlinks** — copies files; no accidental source corruption
- **Templates** — one file, multiple machines, OS-aware output
- **Git-native** — history, branches, remotes all work as expected
- **Encrypted secrets** — supports age/GPG for sensitive values
- **Single binary** — `curl | sh` install, no runtime deps
- **Idempotent** — running `chezmoi apply` twice is always safe

---

*Fork, steal, adapt — happy terminal-ing.*
*— Marty (Birmingham, AL)*
