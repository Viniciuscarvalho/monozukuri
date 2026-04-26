# AGENTS.md — Full Example

## Build

```
npm run build
```

Output goes to `dist/`. Never import from `dist/` in source files.
TypeScript strict mode is enabled. Fix all type errors before committing.

## Test

```
npm test -- --watchAll=false --coverage
```

Coverage threshold: 80%. Tests live in `src/__tests__/` mirroring the source tree.
Use `jest.fn()` for mocks, not manual implementations.

## Conventions

- Exports are named, never default.
- Files are kebab-case. Types/interfaces are PascalCase.
- No `any` type. Use `unknown` and narrow.

## Style

- 2-space indent, single quotes, semicolons.
- Max line length: 100 chars.

## Constraints

- No lodash. Use native Array methods.
- No moment.js. Use `date-fns`.
- Node 20+ only. No CommonJS in new files.

## See also

- docs/adr/001-kysely.md
- docs/adr/002-no-orm.md
