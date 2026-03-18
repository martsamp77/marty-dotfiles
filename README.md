# Marty's Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/) — one config repo, every machine, always in sync.

Manages: **zsh** (shell, prompt, plugins, history) and **Cursor IDE** (settings, keybindings, extensions, snippets, MCP config).

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
| `dot_zshrc.tmpl` | `~/.zshrc` |

The `~/.zsh/` plugin directories (pure, zsh-autosuggestions, zsh-syntax-highlighting) are managed by externals — see below. They are not source files in the repo.

### Plugin management — `.chezmoiexternal.toml`

Plugins are **not** committed into this repository. Instead, they are declared as external git repositories in [`.chezmoiexternal.toml`](.chezmoiexternal.toml) at the repo root:

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

When you run `chezmoi apply`, chezmoi clones each repo to the target path (`~/.zsh/<name>/`) if it is not already present. When you run `chezmoi update`, chezmoi re-pulls any that are older than `refreshPeriod` (168 h = weekly). Plugins are never stored in the dotfiles repo — the repo stays small and plugins stay current.

**Key commands:**

| Goal | Command |
|---|---|
| Install all plugins on a new machine | `chezmoi apply` |
| Force-refresh all plugins right now | `chezmoi apply --refresh-externals` |
| Auto-update plugins + dotfiles | `chezmoi update` (runs weekly refresh automatically) |

**What happens on a brand-new machine:**

1. `chezmoi init --apply git@github.com:martsamp77/marty-dotfiles.git`
2. chezmoi fetches `.chezmoiexternal.toml`, clones all three plugin repos to `~/.zsh/`
3. `.zshrc` is deployed and sources the plugins from `~/.zsh/`
4. Everything works — no separate install step needed

---

## Features

### History

- 1,000,000-line history file (`~/.zsh_history`)
- Shared across all open terminal windows in real time (`SHARE_HISTORY`)
- Timestamps recorded for every entry (`EXTENDED_HISTORY`)
- Exact duplicates never stored (`HIST_IGNORE_ALL_DUPS`)
- Commands prefixed with a space are never saved (`HIST_IGNORE_SPACE`) — useful for passwords
- **API key masking** — a `zshaddhistory` hook intercepts every command before it is written to disk, redacts known secret patterns (`sk-...`, `sk_live_...`, `Bearer ...`, `*_KEY=...`, `*_TOKEN=...`, `*_SECRET=...`), and stores the sanitised version instead. The command still runs normally; only the history entry is redacted.

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

### Pure Prompt

[Pure](https://github.com/sindresorhus/pure) — 14k stars, minimal, no Nerd Fonts required, works identically over SSH/PuTTY/WSL/macOS. Managed as a chezmoi external — cloned to `~/.zsh/pure/` on `chezmoi apply`, never committed to the repo.

```
~/dev/myproject master*
❯
```

- Two-line layout — path + git status on line 1, `❯` on line 2
- `❯` turns **red** on a non-zero exit, **magenta** on success
- User@host only shown during SSH sessions (hidden locally)
- Git status fetched **asynchronously** — never delays the prompt

Color overrides for dark backgrounds are applied via `zstyle`:

| Element | Color |
|---|---|
| Path | Cyan |
| Git branch | Bright cyan (#00ffff) |
| Dirty indicator | Yellow |
| Prompt success | Magenta |
| Prompt error | Red |
| User / host (SSH) | Green |

**How it's managed:** Declared as an external in `.chezmoiexternal.toml`. chezmoi clones it to `~/.zsh/pure/` on `chezmoi apply` and refreshes it weekly on `chezmoi update`.

### zsh-autosuggestions

[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) shows ghost-text command suggestions as you type, drawn from your command history — identical to the Fish shell experience.

- As you type, a greyed-out suggestion appears to the right of your cursor
- Press **→** (right arrow) or **End** to accept the full suggestion
- Press **Ctrl+→** to accept one word at a time
- Completely non-intrusive — keep typing to ignore it

**How it's managed:** Declared as an external in `.chezmoiexternal.toml`. chezmoi clones it to `~/.zsh/zsh-autosuggestions/` on `chezmoi apply` and refreshes it weekly on `chezmoi update`.

### zsh-syntax-highlighting

[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) colors your command line in real time as you type — before you hit Enter.

- **Green** — valid, recognized command
- **Red** — unknown command or typo (catch errors before running)
- **Yellow** — command arguments and flags
- **Cyan** — shell built-ins and keywords
- Strings, paths, variables, and redirections are all distinctly colored

**Why load it last:** Syntax highlighting works by wrapping zsh line editor (ZLE) widgets. It must be sourced _after_ all other plugins and key bindings so it can wrap them all correctly. Loading it earlier breaks other widget bindings.

**How it's managed:** Declared as an external in `.chezmoiexternal.toml`. chezmoi clones it to `~/.zsh/zsh-syntax-highlighting/` on `chezmoi apply` and refreshes it weekly on `chezmoi update`.

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

Key bindings are set with `bindkey -e` (Emacs mode) for maximum compatibility across PuTTY, MobaXterm, Windows Terminal + WSL, macOS Terminal, and any standard SSH session. Home and End are bound to multiple escape sequences so they work correctly regardless of PuTTY's terminal type setting. See [PuTTY Setup](#putty-setup-windows) below for the full recommended configuration.

### OS-aware aliases (via chezmoi templates)

| Alias | macOS | Linux / WSL / AWS |
|---|---|---|
| `update` | `brew update && brew upgrade` | `sudo apt update && sudo apt upgrade -y` |
| `ls` | `ls -G` (BSD color) | `ls --color=auto` (GNU color) |

---

## Quick Start

### One-liner (recommended)

Paste this into any terminal on a new machine — it handles everything automatically:

```bash
bash <(curl -fsLS https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install.sh)
```

The script detects macOS / Ubuntu / WSL and:
1. Installs Homebrew (macOS only, if missing)
2. Installs `zsh`, `git`, `fzf`, `chezmoi` via the right package manager
3. Sets zsh as the default shell
4. Generates `en_US.UTF-8` locale (Ubuntu — fixes prompt symbol rendering)
5. Tries SSH auth to GitHub; falls back to HTTPS automatically
6. Runs `chezmoi init --apply` to pull the repo and deploy everything

Then reload the shell:
```bash
exec zsh
```

---

### Manual step-by-step (if you prefer)

#### 1. Install zsh

**macOS** — already the default since Catalina.

**Ubuntu / WSL / AWS:**
```bash
sudo apt install -y zsh
chsh -s $(which zsh)
# Log out and back in (or reconnect via SSH)
```

#### 2. Install chezmoi

**macOS:**
```bash
brew install chezmoi
```

**Ubuntu / WSL / AWS:**
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"
```

#### 3. Initialize and apply dotfiles

```bash
# SSH (recommended — passwordless if your key is added to GitHub):
chezmoi init --apply git@github.com:martsamp77/marty-dotfiles.git

# HTTPS (no SSH key needed):
chezmoi init --apply https://github.com/martsamp77/marty-dotfiles.git
```

#### 4. Reload the shell

```bash
exec zsh
```

Your shell now has the Pure prompt, syntax highlighting, autosuggestions, and auto-sync on every future session.

---

## Auto-apply on SSH Login / EC2 User-Data

For a fresh server, run the install script directly or embed it in a user-data script:

```bash
bash <(curl -fsLS https://raw.githubusercontent.com/martsamp77/marty-dotfiles/main/install.sh)
```

After the first apply, the auto-sync block in `.zshrc` handles all future updates automatically — every new SSH session quietly checks for changes in the background.

---

## PuTTY Setup (Windows)

These settings make PuTTY work well with this config — correct Unicode rendering, comfortable window size, readable fonts, and stable SSH sessions. Apply them to your saved session, then hit **Save** before closing.

### Installing Cascadia Code

The Pure prompt uses `❯` (U+276F). PuTTY does not fall back to a secondary font for missing glyphs, so the font you choose must contain that character. Cascadia Code covers it.

1. Download the latest release from [github.com/microsoft/cascadia-code/releases](https://github.com/microsoft/cascadia-code/releases)
2. Extract the zip, open the `ttf/` folder
3. Select all `.ttf` files → right-click → **Install for all users** (puts them in `C:\Windows\Fonts` where PuTTY can always see them)

### Recommended PuTTY settings

#### Window → set the size of the window

| Setting | Value | Why |
|---|---|---|
| Columns | `120` | Wider default; avoids wrapping on most commands |
| Rows | `40` | Taller default; more context without scrolling |

Changes take effect at launch. You can still drag-resize during a session.

#### Window → Appearance

| Setting | Value | Why |
|---|---|---|
| Cursor appearance | Underline | Cleaner look |
| Cursor blinks | Enabled | Easier to locate the cursor |
| Font | Cascadia Code Light, size 11 | Supports `❯` and all Unicode glyphs used by Pure |
| Font quality | ClearType | Smooth anti-aliasing; improves readability without blur |
| Gap between text and window edge | 3 px | Subtle border; less cramped feel |
| Hide mouse pointer when typing | Enabled | Keeps the interface clean |

#### Window → Translation

| Setting | Value | Why |
|---|---|---|
| Remote character set | **UTF-8** | **Required** — fixes missing/square characters; handles all Unicode (emoji, line-drawing, `❯`) |
| Handling of line drawing characters | Use Unicode line drawing code points | Boxes and arrows render correctly in tools like Midnight Commander |

#### Window → Behaviour

| Setting | Value |
|---|---|
| System menu appears on ALT-Space | Enabled |

#### Connection

| Setting | Value | Why |
|---|---|---|
| Seconds between keepalives | `30` | Prevents idle timeout on servers and AWS instances |

#### Window → scrollback

| Setting | Value | Why |
|---|---|---|
| Scrollback lines | `20000` | Enough history to review long build outputs without loss |

#### Session → Logging *(optional)*

Enable **All session output** and set a path like:

```
C:\PuTTYLogs\&H_&Y&M&D.log
```

`&H` expands to the hostname, `&Y&M&D` to the date — each session gets its own timestamped log file automatically.

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

## Cursor IDE Settings

Cursor settings are synced across machines by the `run_after_apply-cursor.sh.tmpl` script, which runs automatically after every `chezmoi apply`. It detects the OS and deploys files to the correct path.

### What's synced

| File | Description |
|---|---|
| `cursor/settings.json` | Editor preferences, theme, Peacock colors |
| `keybindings.json` | Generated inline with OS-aware workspace path |
| `cursor/extensions.txt` | Extension manifest — installed on missing machines |
| `cursor/snippets/*.code-snippets` | Custom snippets (if any) |
| `cursor/mcp.json` | Global MCP server config (if present) |
| `cursor/user-rules.md` | In repo for version control; use import/export scripts to sync with state.vscdb (not auto-deployed) |

### Settings paths by OS

| OS | Cursor settings path |
|---|---|
| Windows (via WSL) | `%APPDATA%\Cursor\User\` |
| macOS | `~/Library/Application Support/Cursor/User/` |
| Linux | `~/.config/Cursor/User/` |

### Cursor Extensions

#### Where extensions are stored

Cursor installs extensions to an OS-specific directory. Cursor tracks what's installed in an `extensions.json` file inside that directory (do not edit it).

| OS | Extensions directory |
|---|---|
| **Windows** | `%USERPROFILE%\.cursor\extensions\` (e.g. `C:\Users\You\.cursor\extensions\`) |
| **macOS** | `~/Library/Application Support/Cursor/extensions/` |
| **Linux** | `~/.cursor/extensions/` |
| **WSL** (Cursor on Windows) | `%USERPROFILE%\.cursor\extensions\` (Windows path; Cursor runs on the Windows side) |

Each extension lives in its own folder: `{publisher}.{name}-{version}-{platform}` (e.g. `eamodio.gitlens-17.11.1-universal`).

#### What `cursor/extensions.txt` is

`cursor/extensions.txt` is a **manifest file** you maintain in this repo. Cursor does not read it automatically. It is used to:

1. Document which extensions you want installed
2. Install them on new machines or after a reset (via `chezmoi apply` or manual commands)

Lines starting with `#` are comments and are ignored when installing.

#### Updating the manifest manually

1. Open `cursor/extensions.txt` in an editor.
2. Add or remove extension IDs, one per line (e.g. `esbenp.prettier-vscode`).
3. To see what's currently installed on your machine:
   ```powershell
   # Windows PowerShell
   cursor --list-extensions
   ```
   ```bash
   # macOS / Linux / WSL
   cursor --list-extensions
   # On WSL, use cursor.exe if cursor is not in PATH
   cursor.exe --list-extensions
   ```
4. To overwrite the manifest with your current install (backs up any custom comments/structure):
   ```powershell
   # Windows PowerShell (from repo root)
   cursor --list-extensions > cursor\extensions.txt
   ```
   ```bash
   # macOS / Linux / WSL (from repo root)
   cursor --list-extensions > cursor/extensions.txt
   # On WSL: cursor.exe --list-extensions > cursor/extensions.txt
   ```

#### Installing extensions from the manifest

**Option A: Let chezmoi do it** — Run `chezmoi apply` (or `dotapply`). The `run_after_apply-cursor.sh.tmpl` script installs any extensions from `cursor/extensions.txt` that are not already installed.

**Option B: Manual install** — Use these commands when you want to sync extensions without running a full chezmoi apply.

**Windows PowerShell** (from repo root):

```powershell
cd c:\Workspace\marty-dotfiles
Get-Content cursor\extensions.txt | Where-Object { $_ -notmatch '^#' -and $_ -match '\S' } | ForEach-Object { cursor --install-extension $_ }
```

**macOS / Linux / WSL** (from repo root):

```bash
cd ~/path/to/marty-dotfiles
grep -v '^#' cursor/extensions.txt | grep -v '^[[:space:]]*$' | while read -r ext; do
  cursor --install-extension "$ext"
done
# On WSL, use cursor.exe instead of cursor if needed
```

Extensions that are already installed are left unchanged; only missing ones are installed.

### User Rules (manual sync)

Cursor stores User Rules in a SQLite database (`state.vscdb`), not a plain text file. Two helper scripts handle export and import:

```bash
# Export rules from the current machine to cursor/user-rules.md
./scripts/cursor-export-rules.sh

# Import rules on a new machine (close Cursor first!)
./scripts/cursor-import-rules.sh
```

Run from the chezmoi source dir (e.g. `dots` then `./scripts/cursor-export-rules.sh`) or ensure `chezmoi` is in PATH so the scripts can resolve the source path.

The import script backs up `state.vscdb` before writing. User Rules are not deployed automatically by `chezmoi apply` because modifying the SQLite database while Cursor is running can corrupt it. Requires `sqlite3` and `xxd` (Ubuntu: `sudo apt install sqlite3 xxd`).

### Adding a new Cursor setting

1. Edit `cursor/settings.json` in the repo (or change it in Cursor and copy it back)
2. For keybindings, edit the heredoc in `run_after_apply-cursor.sh.tmpl`
3. Push to GitHub — other machines pick it up on next `chezmoi update`

---

## API Keys and Local Secrets

API keys and other secrets are stored in `~/.zshrc.local` on each machine — a file that is **never tracked by chezmoi and never pushed to GitHub**.

`.zshrc` sources it automatically if it exists:

```bash
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

On any new machine, create the file manually after running `chezmoi apply`:

```bash
cat >> ~/.zshrc.local << 'EOF'
export MEM0_API_KEY="sk-..."
export OPENAI_API_KEY="sk-..."
EOF
```

Each machine can have different keys or none at all — on machines without the file the shell starts cleanly with no errors. Never run `chezmoi add ~/.zshrc.local`; keep it local only.

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

**`chezmoi update` fails with merge conflict / prompt hasn't changed after an update**

This happens when a previous `chezmoi update` was interrupted by a rebase conflict and left the source repo in a paused state. Every subsequent `chezmoi update` will fail with "Pulling is not possible because you have unmerged files." Fix:
```bash
chezmoi cd              # cd into ~/.local/share/chezmoi
git status              # confirm you are mid-rebase
git rebase --abort      # discard the stuck rebase
chezmoi update          # clean pull + apply from GitHub
exec zsh                # reload the shell with the new config
```

**Prompt still showing old style / aliases like `dotup` not found**

The new `~/.zshrc` has not been applied yet. Either a merge conflict (see above) or `chezmoi apply` has not been run since initialization. Run:
```bash
chezmoi apply
exec zsh
```

**Plugins not loading**

Plugins are managed by chezmoi externals (`.chezmoiexternal.toml`). If `~/.zsh/` is empty, run:
```bash
chezmoi apply --refresh-externals
```
This forces chezmoi to re-clone all three plugin repos (`pure`, `zsh-autosuggestions`, `zsh-syntax-highlighting`) into `~/.zsh/`.

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
