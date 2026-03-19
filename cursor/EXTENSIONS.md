# Cursor Extensions — Approved List

This document describes every extension in `cursor/extensions.txt`, why it's included, and when you might remove it.

---

## Required (guidelines + settings)


| Extension                     | Purpose                                                                                                                                                                                   |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **EditorConfig.EditorConfig** | Enforces consistent editor settings (indent, line endings, charset) across projects via `.editorconfig`. Ensures everyone uses the same style regardless of their personal Cursor config. |
| **esbenp.prettier-vscode**    | Code formatter for JavaScript, TypeScript, HTML, CSS, JSON, Markdown. Industry standard; formats on save when configured.                                                                 |
| **dbaeumer.vscode-eslint**    | Lints and auto-fixes JavaScript/TypeScript. Catches bugs, enforces style, integrates with Prettier.                                                                                       |
| **bradlc.vscode-tailwindcss** | IntelliSense, syntax highlighting, and class-name completion for Tailwind CSS. Essential for Tailwind projects.                                                                           |
| **ms-python.black-formatter** | Python formatter. Opinionated, no-config. Keeps Python code consistent.                                                                                                                   |


---

## Python


| Extension                                   | Purpose                                                                                                                   |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **anysphere.cursorpyright**                 | Cursor's Pyright integration. Type checking for Python. Required for Cursor's Python AI features and static analysis.     |
| **ms-python.python**                        | Official Microsoft Python extension. Base support: run/debug, environments, testing.                                      |
| **ms-python.vscode-pylance**                | Fast Python language server. IntelliSense, go-to-definition, type hints, import resolution.                               |
| **ms-python.debugpy**                       | Python debugger. Breakpoints, step-through, variable inspection. Usually installed with the Python extension.             |
| **njpwerner.autodocstring**                 | Auto-generates docstrings (Google, NumPy, Sphinx styles) for functions and classes. Saves time and keeps docs consistent. |
| **donjayamanne.python-environment-manager** | Manages venv, conda, pyenv from the UI. Switch interpreters easily. Remove if you only use one environment.               |


---

## Remote / WSL


| Extension                              | Purpose                                                                                                            |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| **anysphere.remote-wsl**               | Cursor's WSL integration. Open folders in WSL from Windows Cursor. Essential for WSL workflows.                    |
| **ms-vscode-remote.remote-ssh**        | Connect to remote machines via SSH. Edit files on servers, VMs, or other computers.                                |
| **ms-vscode-remote.remote-ssh-edit**   | Edit SSH config (`~/.ssh/config`) from within Cursor. Convenience for managing hosts.                              |
| **ms-vscode-remote.remote-containers** | Dev Containers — develop inside a Docker container. Reproducible environments. Remove if you don't use containers. |
| **ms-vscode.remote-explorer**          | UI for viewing and managing remote connections (SSH, WSL, containers).                                             |
| **ms-vscode.remote-server**            | Remote server management. Part of the remote development workflow.                                                 |


---

## Recommended for MD stack


| Extension                              | Purpose                                                                                          |
| -------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **usernamehw.errorlens**               | Inline display of errors and warnings at the cursor. No need to open the Problems panel.         |
| **formulahendry.auto-rename-tag**      | Renames paired HTML/JSX tags when you edit one. Prevents broken markup.                          |
| **dsznajder.es7-react-js-snippets**    | Snippets for React, Redux, ES6+. Speeds up component creation.                                   |
| **charliermarsh.ruff**                 | Fast Python linter (replaces Flake8, isort, etc.). Linting without the slowdown.                 |
| **hashicorp.terraform**                | Syntax, validation, and formatting for Terraform (`.tf`). Remove if you don't use infra-as-code. |
| **mikestead.dotenv**                   | Syntax highlighting and validation for `.env` files.                                             |
| **christian-kohler.path-intellisense** | Path autocomplete for imports and file references.                                               |
| **github.vscode-github-actions**       | Edit and validate GitHub Actions workflows (`.yml`).                                             |


---

## NetSuite (if you do SuiteScript)


| Extension                        | Purpose                                                                        |
| -------------------------------- | ------------------------------------------------------------------------------ |
| **ericbirdsall.SuiteSnippets**   | Snippets for NetSuite SuiteScript 1.0 and 2.0.                                 |
| **nsupload-org.netsuite-upload** | Upload/deploy SuiteScript files to NetSuite. Remove if you don't use NetSuite. |


---

## Tauri (if you do desktop apps)


| Extension                   | Purpose                                                                                     |
| --------------------------- | ------------------------------------------------------------------------------------------- |
| **rust-lang.rust-analyzer** | Rust language server. Required for Tauri (Rust backend).                                    |
| **tauri-apps.tauri-vscode** | Tauri project support: scaffolding, commands, config. Remove if you don't build Tauri apps. |


---

## Prisma (if you use Prisma for PostgreSQL)


| Extension         | Purpose                                                                                            |
| ----------------- | -------------------------------------------------------------------------------------------------- |
| **Prisma.prisma** | Syntax highlighting, formatting, and validation for Prisma schema. Remove if you don't use Prisma. |


---

## Optional


| Extension                                 | Purpose                                                                                     |
| ----------------------------------------- | ------------------------------------------------------------------------------------------- |
| **yzhang.markdown-all-in-one**            | Keyboard shortcuts, TOC, preview for Markdown.                                              |
| **aaron-bond.better-comments**            | Colorizes TODO, FIXME, etc. in comments.                                                    |
| **streetsidesoftware.code-spell-checker** | Spell-check in code and comments. Catches typos.                                            |
| **rangav.vscode-thunder-client**          | REST API client inside Cursor (like Postman).                                               |
| **ms-playwright.playwright**              | Run and debug Playwright tests. Remove if you don't use Playwright.                         |
| **mechatroner.rainbow-csv**               | Colorizes CSV columns for readability. Nice for data work.                                  |
| **wholroyd.jinja**                        | Jinja2 template support. Remove if you don't use Jinja2.                                    |
| **ms-vscode.powershell**                  | PowerShell support. Keep if you use PowerShell.                                             |
| **cweijan.vscode-office**                 | View Word, Excel, PowerPoint in Cursor.                                                     |
| **eamodio.gitlens**                       | Git blame, history, and diffs inline.                                                       |
| **johnpapa.vscode-peacock**               | Color workspace folders. Distinguish projects at a glance.                                  |
| **ukoloff.win-ca**                        | Uses Windows CA store for Node.js SSL. Fixes cert issues on Windows. Remove on macOS/Linux. |
| **batisteo.vscode-django**                | Django support. Remove if you don't use Django.                                             |
| **tomoki1207.pdf**                        | View PDFs in Cursor. Remove if you rarely need it.                                          |


---

## Adding or removing extensions

1. Edit `cursor/extensions.txt` — add or delete the extension ID.
2. Run `chezmoi apply` (or `dotapply`) to sync.
3. Update this document when adding a new extension so future-you knows why it's there.

