# AGENTS.md — marty-dotfiles (this repository)

Personal **dotfiles** and **Cursor / memory-bank templates** for other projects. See [CLAUDE.md](../CLAUDE.md) for chezmoi, Windows sync, and the six-folder template layout.

## AI context here

- **Always-on:** [`rules/dotfiles-repo.mdc`](rules/dotfiles-repo.mdc).
- **Scoped:** [`rules/chezmoi-dotfiles.mdc`](rules/chezmoi-dotfiles.mdc) for `*.tmpl`, `dot_*`, shell bootstrap.
- **Templates (not auto-loaded as app rules):** `.cursor-37m-template/`, `.cursor-md-template/`, `.memory-bank-*-template/` — copy into application repos as `.cursor/` and `.memory-bank/`.
- **Persistent notes for this repo:** [`.memory-bank/`](../.memory-bank/) if present.

## Commands

No application dev server. Typical work: `chezmoi diff`, `git status`, editing `windows/*.ps1` or templates.

## Security

Do not commit secrets or real `.env` files.
