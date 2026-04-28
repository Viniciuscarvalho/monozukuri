# TechSpec — feat-qa-001: Add health endpoint

**Feature:** feat-qa-001

---

## Technical Approach

Add a `/health` route handler to the existing Express router. The handler
calls `db.ping()` (already available on the singleton connection) with a
100 ms timeout. A successful ping returns 200; a timeout or error returns 503. No new dependencies required.

## Files Likely Touched

- src/routes/health.ts
- src/app.ts
- src/db/client.ts
- test/routes/health.test.ts
