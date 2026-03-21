# Cursor Extensions — Recommended set

This list is **curated for Marty’s workflows** as reflected in `cursor/settings.json` and this dotfiles repo: Python (Black, Ruff, Django, Jinja), Node/React/TypeScript (Prettier, ESLint, Tailwind, Vite-style nesting), remote development (WSL, SSH, Containers), Terraform, GitHub Actions, NetSuite tooling when needed, and Windows-friendly extras (PowerShell, `win-ca`, PDF/Office viewers).

The canonical ID list is **`cursor/extensions.txt`**. After changing the manifest, install missing extensions with `./scripts/cursor-sync-extensions.sh` or the PowerShell/bash one-liners in that file’s header.

**Note:** Extensions starting with `anysphere.` are Cursor-specific and are skipped when syncing the same manifest to VS Code via `vscode-sync-extensions.sh`.

## Core (aligned with settings)

| Extension ID | Why |
|--------------|-----|
| **EditorConfig.EditorConfig** | Honors `.editorconfig` across repos and teams. |
| **esbenp.prettier-vscode** | Matches `editor.defaultFormatter`. |
| **dbaeumer.vscode-eslint** | Matches `editor.codeActionsOnSave` → `source.fixAll.eslint`. |
| **bradlc.vscode-tailwindcss** | Tailwind IntelliSense; pairs with explorer nesting for `tailwind.config.*`. |
| **ms-python.black-formatter** | Matches `[python].editor.defaultFormatter`. |
| **johnpapa.vscode-peacock** | Workspace colors; `peacock.favoriteColors` is already in settings. |

## Python

| Extension ID | Why |
|--------------|-----|
| **anysphere.cursorpyright** | Cursor’s Pyright integration for Python. |
| **ms-python.python** | Core Python support. |
| **ms-python.vscode-pylance** | Language server / IntelliSense. |
| **ms-python.debugpy** | Debugger. |
| **njpwerner.autodocstring** | Docstring generation. |
| **donjayamanne.python-environment-manager** | Interpreter / venv management. |
| **charliermarsh.ruff** | Fast lint/format; complements Black. |
| **kevinrose.vsc-python-indent** | Better indent inside Python blocks. |
| **batisteo.vscode-django** | Django templates and project affordances. |
| **wholroyd.jinja** | Jinja2 syntax for templates. |

## Remote / WSL

| Extension ID | Why |
|--------------|-----|
| **anysphere.remote-wsl** | Cursor’s WSL integration (Windows ↔ Linux). |
| **ms-vscode-remote.remote-ssh** | Remote folders over SSH. |
| **ms-vscode-remote.remote-ssh-edit** | Edit `~/.ssh/config` in the editor. |
| **ms-vscode-remote.remote-containers** | Dev Containers. |
| **ms-vscode.remote-explorer** | Browse SSH/WSL/remote targets. |
| **ms-vscode.remote-server** | Remote server workflows. |

## Web / React / TS

| Extension ID | Why |
|--------------|-----|
| **usernamehw.errorlens** | Inline diagnostics; fewer trips to the Problems panel. |
| **formulahendry.auto-rename-tag** | Paired JSX/HTML tag rename. |
| **dsznajder.es7-react-js-snippets** | React snippets; matches TSX nesting patterns in settings. |
| **mikestead.dotenv** | Highlights and tooling for `.env`; pairs with `.env` file nesting. |
| **christian-kohler.path-intellisense** | Autocomplete for file paths in imports. |

## Infra & CI

| Extension ID | Why |
|--------------|-----|
| **hashicorp.terraform** | Formatting, navigation, and validation for Terraform. |
| **github.vscode-github-actions** | Workflow syntax and local editing for Actions YAML. |

## NetSuite

| Extension ID | Why |
|--------------|-----|
| **ericbirdsall.SuiteSnippets** | SuiteScript-oriented snippets. |
| **nsupload-org.netsuite-upload** | Upload/deploy helpers for NetSuite projects. |

## Tauri / Rust

| Extension ID | Why |
|--------------|-----|
| **rust-lang.rust-analyzer** | Rust language support. |
| **tauri-apps.tauri-vscode** | Tauri config and tooling. |

## Prisma

| Extension ID | Why |
|--------------|-----|
| **Prisma.prisma** | Schema formatting, syntax, and Prisma Client hints. |

## Optional quality-of-life

| Extension ID | Why |
|--------------|-----|
| **yzhang.markdown-all-in-one** | TOC, lists, and shortcuts for Markdown. |
| **aaron-bond.better-comments** | Highlight TODOs and comment tags. |
| **streetsidesoftware.code-spell-checker** | Catch typos in comments and docs. |
| **rangav.vscode-thunder-client** | REST client in the editor. |
| **ms-playwright.playwright** | Run/debug Playwright tests. |
| **mechatroner.rainbow-csv** | CSV column colors. |
| **ms-vscode.powershell** | Matches integrated default profile **PowerShell** in settings. |
| **cweijan.vscode-office** | Preview common Office formats. |
| **eamodio.gitlens** | Blame, history, and richer Git UX. |
| **ukoloff.win-ca** | Trust Windows enterprise CAs (helpful on locked-down networks). |
| **eriklynd.json-tools** | JSON navigation and utilities. |
| **tomoki1207.pdf** | PDF preview inside the editor. |
| **visualstudioexptteam.vscodeintellicode** | AI-assisted completions. |
| **visualstudioexptteam.intellicode-api-usage-examples** | API usage examples in IntelliSense. |

**Manual edit:** Update `cursor/extensions.txt`, then `chezmoi apply` if you deploy IDE settings from this repo.

**Interactive sync:** `./scripts/cursor-sync-extensions.sh` — add missing manifest entries or install what’s listed.
