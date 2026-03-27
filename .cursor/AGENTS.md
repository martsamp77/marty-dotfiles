# AGENTS.md

<!-- Edit this file before committing. Replace every [BRACKETED] placeholder. Delete this comment. -->

## Project
**[md-project-name]** — [One sentence: what this does and who uses it.]

## Stack
- **Runtime:** [Node.js 20 LTS | Python 3.11+]
- **Frontend:** [Vite + React + TypeScript + Tailwind CSS + shadcn/ui | N/A]
- **Backend:** [Express | Fastify | FastAPI | N/A]
- **Database:** [PostgreSQL | MongoDB | DynamoDB | SQLite | N/A]
- **Auth:** [Active Directory | Entra ID | AWS Cognito | N/A]
- **Deployment:** [Internal MD server | AWS (ECS / Lambda / S3+CloudFront) | Datto RMM]

## Key Commands
```bash
npm install        # install dependencies
npm run dev        # start dev server
npm run build      # production build
npm run test       # run tests
npm run lint       # eslint check
```

## Project Structure
```
[Paste top-level folder structure here]
src/
  components/
  features/
  pages/
  lib/
  types/
```

## Coding Standards
All rules are in `.cursor/rules/` and auto-apply based on file type. Key conventions:

- Repository name: `md-[project-name]` (kebab-case with md- prefix)
- Branching: `main` → `develop` → `feature/fix/hotfix` branches
- Commits: Conventional Commits format (`feat`, `fix`, `docs`, `chore`, etc.)
- All merges to `main` require **Marty Sampson** approval
- Never commit secrets, `.env` with real values, or `node_modules/`

## Do Not
- Push directly to `main` or `develop`
- Use `any` in TypeScript — no exceptions
- Suppress ESLint or TypeScript errors without a documented reason
- Add new dependencies without approval
- Hardcode credentials, connection strings, or API keys
- Use Next.js, Angular, Yarn, pnpm, or Bun
- [NetSuite only: Deploy to production directly — all deployments go through Marty]

## Open Questions / Known Issues
- [List anything uncertain or in progress]

## Related Docs
- Enterprise coding standards: `coding-guidelines.md`
- [NetSuite specifics: `netsuite-development.md`]
- [Project spec: `spec-[project-name].md`]
