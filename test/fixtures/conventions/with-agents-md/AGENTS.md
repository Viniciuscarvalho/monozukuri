# AGENTS.md

## Build

Run `npm run build` before committing. Never commit with build errors.

## Test

Run `npm test -- --watchAll=false`. All tests must pass before pushing.

## Database

Use kysely for all queries. No raw SQL. All queries must go through `src/db/query.ts`.
