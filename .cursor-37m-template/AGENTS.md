# AGENTS.md — application project (template)

Replace bracketed placeholders after copying this template into your app repository as `.cursor/AGENTS.md` (alongside `.cursor/rules/` from the 37Metrics template bundle).

## Project

**[PROJECT_NAME]** — [ONE_LINE_DESCRIPTION]

## Stack

- **Runtime:** [Node.js 20 LTS | Python 3.11+ | other]
- **Frontend:** [Vite + React + TypeScript + Tailwind + shadcn/ui | N/A]
- **Backend:** [Express | Fastify | FastAPI | N/A]
- **Database:** [PostgreSQL | SQLite | MongoDB | DynamoDB | N/A]
- **Auth:** [Clerk | Supabase Auth | Auth0 | GitHub OAuth | Entra ID | Cognito | none]
- **Deployment:** [describe hosting / CI]

## Key commands

```bash
[PASTE_FROM_README]
```

## Project structure

```
[PASTE_TOP_LEVEL_TREE]
```

## AI context

- **Cursor rules:** `.cursor/rules/` (from `.cursor-37m-template/`). **Memory bank:** `.memory-bank/` (from `.memory-bank-37m-template/`). Fill stubs after copy.
- **Optional:** If you use a **scripts/** split (e.g. another tool owns `scripts/`), add or enable [`rules/ironclaw.mdc`](rules/ironclaw.mdc) with globs that match your layout.

## New project checklist

1. Scaffold the stack with the official tool (`npm create vite@latest`, `poetry new`, etc.).
2. Copy `.cursor-37m-template/*` → your repo `.cursor/` (merge into existing `.cursor` if any).
3. Copy `.memory-bank-37m-template/*` → `.memory-bank/`.
4. Fill `AGENTS.md`, `README.md`, `.env.example`, and memory-bank stubs.
5. Commit `package-lock.json` / lockfiles per stack policy.

## Do not

- Commit secrets or real `.env` files.
- Weaken `.cursor/rules/` without a deliberate team decision.

## Related docs

- Project `README.md`, `coding-guidelines.md` (if present), specs under `docs/` or `spec-*.md`.
