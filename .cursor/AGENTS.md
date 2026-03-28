# AGENTS.md — marty-dotfiles

This file is **Cursor Agent** context for the **marty-dotfiles** repository. It is **not** an application repo: there is no `npm run dev` here. For shipping software in another repo, you may replace or extend this file with stack-specific commands and structure.

## What this repo is

Personal **dotfiles** ([CLAUDE.md](../CLAUDE.md)):

- **Linux / Mac:** chezmoi — `dot_*.tmpl` and related templates deploy to `$HOME`.
- **Windows:** PowerShell under `windows/` — `install.ps1`, `profile.ps1`, `marty-profile.ps1`, `dotsync`, etc.

The **`.cursor/`** tree holds rules you reuse in this workspace (and can copy into other personal projects).

## AI context

- **Cursor** uses this file plus `.cursor/rules/`.
- **Always-on rules:** [`37m-core.mdc`](rules/37m-core.mdc) and [`coding-standards.mdc`](rules/coding-standards.mdc).
- **Scoped rules:** TypeScript, React, Python, API, database, NetSuite, PowerShell, chezmoi/dotfiles ([`chezmoi-dotfiles.mdc`](rules/chezmoi-dotfiles.mdc)) — see `.cursor/rules/*.mdc` frontmatter for `globs`.

## Standards and specs

These `.cursor` rules are the **default source of truth** for personal work. If a repo includes `coding-guidelines.md` or a project spec, follow those for that repo.

For greenfield apps, add a short spec or README section when it helps; no external guidelines repository is required.

## Security

- Do not paste secrets, production tokens, or private keys into chat.
- Use `.env.example` only in commits; keep real values local or in a secrets manager.

## Key commands (this repo)

There is no application dev server. Typical maintenance:

```bash
git status
git diff
git checkout -b chore/update-cursor-rules
# edit .cursor/rules/ or AGENTS.md
git add . && git commit -m "docs(cursor): describe rule change"
```

On Windows after profile changes: `. $PROFILE` or open a new shell.

## Do not

- Assume every workspace is a Vite/React monorepo — this repo is mostly shell, chezmoi, and PowerShell.
- Weaken 37Metrics / personal standards when editing rules without a deliberate reason.
- Commit secrets, real `.env` files, or credentials.
- Force a corporate PR policy on solo repos; use whatever git flow you prefer.

## Approvals

You own merges for personal repositories. Use PRs and reviews when collaborating.

## Related docs

- Root [README.md](../README.md) and [CLAUDE.md](../CLAUDE.md) — how dotfiles are laid out and synced.
