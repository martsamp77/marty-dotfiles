# AGENTS.md — application project (template)

Replace bracketed placeholders after copying this template into your app repository as `.cursor/AGENTS.md` (alongside `.cursor/rules/` from the Molecular Designs template bundle).

## Project

**[PROJECT_NAME]** — [ONE_LINE_DESCRIPTION]

## Stack

- **Runtime:** [Node.js 20 LTS | Python 3.11+ | other]
- **Frontend:** [Vite + React + TypeScript + Tailwind + shadcn/ui | N/A]
- **Backend:** [Express | Fastify | FastAPI | N/A]
- **Database:** [PostgreSQL | MongoDB | DynamoDB | SQLite | N/A]
- **Auth:** [Active Directory | Entra ID | AWS Cognito | Auth0 | N/A]
- **Deployment:** [Internal server | AWS (ECS / Lambda / S3+CloudFront) | other]

## Key commands

```bash
[PASTE_FROM_README]
```

## Project structure

```
[PASTE_TOP_LEVEL_TREE]
```

## AI context

- **Cursor rules:** `.cursor/rules/` (from `.cursor-md-template/`). **Memory bank:** `.memory-bank/` (from `.memory-bank-md-template/`). Fill stubs after copy.

## New project checklist

1. Scaffold the stack with the official tool (`npm create vite@latest`, `poetry new`, etc.).
2. Copy `.cursor-md-template/*` → your repo `.cursor/` (merge if needed).
3. Copy `.memory-bank-md-template/*` → `.memory-bank/`.
4. Fill `AGENTS.md`, `README.md`, `.env.example`, and memory-bank stubs.
5. Commit `package-lock.json` / lockfiles per organization policy.

## Do not

- Commit secrets or real `.env` files.
- Push directly to `main` or `develop` without team policy.
- Weaken `.cursor/rules/` without formal approval.

## Related docs

- Enterprise coding standards: `coding-guidelines.md` (when maintained for the project)
- NetSuite specifics: `netsuite-development.md` (when applicable)
- Project spec: `spec-[project-name].md` (when applicable)
