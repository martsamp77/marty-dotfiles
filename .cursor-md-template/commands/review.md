# Review (Molecular Designs)

Run a structured review pass on the current change set before opening or updating a PR.

1. Read `git diff` (staged and unstaged) and list files touched.
2. Check adherence to `.cursor/rules/` and `coding-guidelines.md` (if present in the repo).
3. Flag: use of `any`, missing error handling, secrets, broad CORS, missing validation on API inputs, logging of PII.
4. Summarize **blockers** vs **nits** and suggest concrete fixes.
