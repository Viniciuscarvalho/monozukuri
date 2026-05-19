# AGENTS.md (ui/)

Tailored instructions for the `ui/` Ink TUI subpackage. Read the repo-root `AGENTS.md` first; this file overrides where it conflicts.

## Stack

- Ink 5 + React 18 (functional components only — no class components)
- TypeScript 5, strict mode (`tsconfig.json`)
- TypeScript compiler for ESM output (`npm run build`)
- Jest + ink-testing-library for tests
- ESLint for lint (`npm run lint`)

## Conventions

- **Use `ink-testing-library`** for component tests — never spawn the real terminal. The repo-root `AGENTS.md`'s record-replay pattern (replay-claude, MOCK_CLAUDE_MODE) does **not** apply here; Ink has its own testing model.
- **No new top-level dependencies** without justification. The current set (ink, ink-spinner, ink-testing-library, react, ts-jest, tsup) is intentional, but `npm run build` emits ESM through `tsc`.
- **Functional + hooks only**. Local state via `useReducer` (see `src/reducer.ts`); no Redux/MobX/Zustand.
- **Design tokens** live in `src/tokens.ts` — colors, spacing, symbols. Don't hardcode hex/ANSI in components.
- **No raw ANSI escape sequences**. Use Ink's `<Text color="…">` so `NO_COLOR` is honoured automatically (the repo-root convention).
- **Dist smoke test** (`npm run test:smoke`) must pass — it imports `dist/index.js` and rejects the known Ink `Dynamic require of "assert"` bundling regression.

## Commands

- **Test:** `npm test` (or `make test` from repo root runs the bash + UI suites together)
- **Lint:** `npm run lint`
- **Build:** `npm run build`
- **Dev (watch):** `npm run dev`
- **Smoke-test the compiled dist:** `npm run test:smoke`

## Layout

```
src/
  App.tsx           Root component
  index.tsx         Entry point — wired to bin/monozukuri-ui
  reducer.ts        Single useReducer state machine for the TUI
  runtime.ts        Stream parsing / event-loop bridge to monozukuri's JSONL events
  tokens.ts         Design tokens (colors, spacing, symbols)
  types.ts          Shared types
  components/       Ink components — one file per component
  hooks/            Custom React hooks
  lib/              Pure helpers (no React, no Ink)
__tests__/          Jest specs
stubs/              Test fixtures
```

## When adding a component

1. Place it in `src/components/<Name>.tsx`
2. Add a test in `__tests__/<Name>.test.tsx` using ink-testing-library
3. If it consumes runtime events, type them via `src/types.ts` — don't widen to `any`
4. Use tokens from `src/tokens.ts`; no inline color literals

## What NOT to do

- Don't add a state-management library — `useReducer` is the contract
- Don't import from `monozukuri/lib/**` — the TUI consumes JSONL events from stdin, not bash directly
- Don't bypass `ink-testing-library` to spawn a real terminal in tests
