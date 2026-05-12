# Technical Specification

**Project Name:** Monozukuri
**Feature:** Ink TUI Visual Polish — pre-launch UX pass
**Version:** 1.0
**Date:** 2026-05-12
**Status:** Approved
**PRD Reference:** `./prd.md`

---

## Overview

### Problem Statement

The Ink TUI has accumulated visual drift between `tokens.ts` (the declared single source of truth) and actual component implementations: inline hex/color literals in 4 components, manual sharp-corner border drawing in all main components, an unused braille spinner, non-reactive terminal width, and magic layout numbers. This produces an unpolished appearance blocking public v1.0 launch.

### Proposed Solution

Three coordinated changes: (1) enforce the token contract by replacing all inline colors with `tokens.*` imports; (2) restructure the main layout to use a single outer `borderStyle="round"` Box in `App.tsx`, with section separators as `── label ──` text rows — eliminating per-component border drawing; (3) wire `tokens.spinner.frames` to `FeatureCard` and activate `useTerminalWidth()` (already written) in `App.tsx`.

### Goals

- Zero inline color literals in `ui/src/components/`
- Single outer `borderStyle="round"` border with properly aligned right edge at any terminal width
- Braille spinner animating at 80ms in active phases
- Terminal resize reactive (SIGWINCH handled by existing `useStdoutDimensions` in `layout.ts`)
- All layout constants named and co-located in `tokens.ts` or `layout.ts`

### PRD Requirements Coverage

| PRD Requirement                | Covered In                         | Implementation Approach                                                     |
| ------------------------------ | ---------------------------------- | --------------------------------------------------------------------------- |
| FR-001 Token enforcement       | All 4 violating components         | Replace inline colors with `tokens.*` imports                               |
| FR-002 Unified rounded borders | `App.tsx` layout restructure       | Single outer Box with `borderStyle="round"`; components render content only |
| FR-003 Braille spinner         | `FeatureCard.tsx` + `useTicker.ts` | Local 80ms `setInterval` in `FeatureCard`; consumes `tokens.spinner.frames` |
| FR-004 Resize reactivity       | `App.tsx`                          | Replace `stdout?.columns` with `useTerminalWidth()` from `layout.ts`        |
| FR-005 Magic numbers           | `layout.ts` + `tokens.ts`          | Named layout constants; `sep()` utility in `layout.ts`                      |

---

## Scope

### In Scope

- Token enforcement in `FeatureList`, `CostMeter`, `LogPane`, `SetupPanel` _(FR-001)_
- Single outer border restructure — `App.tsx` + all main components _(FR-002)_
- Section separator `── label ──` pattern via `sep()` utility _(FR-002)_
- Braille spinner wire-up in `FeatureCard` _(FR-003)_
- `useTerminalWidth()` adoption in `App.tsx` _(FR-004)_
- Layout constants extraction _(FR-005)_
- Snapshot regeneration _(NFR-002)_
- Deletion of `ui/src/__prototype__/` _(NFR-004)_

### Out of Scope

- Shell-side output (`lib/cli/output.sh`) corner style — different renderer, separate decision
- Stub views (`learnings`, `filter`, `search`) — not implementing, just keeping stubs
- New color tokens in palette — palette frozen for v1.0
- New bats smoke tests for TUI render — nice-to-have post-launch

---

## Existing Codebase Analysis

### Project Structure (Relevant Paths)

```
ui/
├── src/
│   ├── App.tsx                  # Root: layout, view routing, width, done-frame
│   ├── tokens.ts                # Design system: colors, symbols, spinner, glyphs
│   ├── types.ts                 # Shared TypeScript types (AppState, Feature, Phase...)
│   ├── runtime.ts               # cleanup() — do not touch
│   ├── hooks/
│   │   ├── useTicker.ts         # 1Hz clock for elapsed time
│   │   ├── useEventStream.ts    # IPC — do not touch
│   │   └── useKeybindings.ts    # Keybinding handler — do not touch
│   ├── lib/
│   │   └── layout.ts            # useTerminalWidth() + clamp() — extend with sep()
│   └── components/
│       ├── Panel.tsx            # Existing borderStyle="round" component — becomes canonical
│       ├── Header.tsx           # Remove border drawing, render content only
│       ├── FeatureCard.tsx      # Remove border drawing, wire spinner
│       ├── FeatureList.tsx      # Remove border drawing, fix 6 hex violations
│       ├── LogPane.tsx          # Remove border drawing, fix Ink color-name violations
│       ├── Footer.tsx           # Remove border drawing, render as content row
│       ├── CostMeter.tsx        # Fix color="red"/"green" violations
│       ├── SetupPanel.tsx       # Fix 'green'/'yellow' agent status colors
│       └── PhaseTimeline.tsx    # Read-only reference; no changes needed
├── __tests__/
│   ├── snapshots.test.tsx       # Will need --updateSnapshot
│   ├── composite-screenshot.test.tsx  # Will need --updateSnapshot
│   ├── Header.test.tsx          # May need --updateSnapshot
│   ├── FeatureCard.test.tsx     # Will need --updateSnapshot
│   └── tokens.test.ts           # Must pass unchanged (palette not modified)
```

### Existing Patterns to Follow

**Code Organization:**

- One component per file in `ui/src/components/`, exported as named function
- All colors/symbols through `tokens.ts` — comment on line 6 explicitly forbids inline colors
- Hooks in `ui/src/hooks/`, utilities in `ui/src/lib/`

**Naming Conventions:**

- Files: `PascalCase.tsx` for components, `camelCase.ts` for hooks/utils
- Functions: `PascalCase` for React components, `camelCase` for hooks/utilities
- Constants: `SCREAMING_SNAKE_CASE` for module-level layout constants, `camelCase` for token references

**Test Pattern:**

```tsx
import { render } from "ink-testing-library";
import { Header } from "../src/components/Header.js";
// snapshot test — toMatchSnapshot() is the key assertion
```

### Existing Dependencies (Relevant)

| Package             | Version      | Used For                | Important Notes                              |
| ------------------- | ------------ | ----------------------- | -------------------------------------------- |
| ink                 | ^5.0.0       | TUI framework           | `borderStyle="round"` is a built-in Box prop |
| react               | ^18.2.0      | Component model         | Hooks: useState, useEffect, useRef           |
| ink-testing-library | ^3.0.0       | Snapshot testing        | `render()` → `.lastFrame()`                  |
| useStdoutDimensions | ink built-in | Reactive terminal width | Already imported in `layout.ts`              |

### Existing Interfaces / Contracts to Respect

```typescript
// ui/src/types.ts — do not modify
interface AppState {
  current: string | null;
  features: Record<string, Feature>;
  order: string[];
  log: LogEntry[];
  spinner: string; // currently a raw string label — will become unused after FR-003
  setupMode: boolean;
  totals: {
    succeeded: number;
    failed: number;
    skipped: number;
    costUsd: number;
  };
  runId?: string;
  autonomy?: string;
  model?: string;
  agent?: string;
  source?: string;
  featureCount?: number;
  budget?: number;
}

// layout.ts — existing exports to keep
export function useTerminalWidth(maxWidth?: number): number;
export function clamp(value: number, min: number, max: number): number;
```

---

## Technical Approach

### Architecture Overview

The key structural change is **moving border ownership from individual components to `App.tsx`**. Currently each component draws its own outer border (`┌─┐`, manual `│`). After this change:

- `App.tsx` renders one outer `Box` with `borderStyle="round" borderColor={tokens.dim}` at `terminalWidth`
- Section separators are `<Text>` rows calling `sep(label, innerWidth)` — placed between content sections directly inside the outer box (no padding → they touch the `│` borders on both sides, creating a `├──┤` visual)
- Each component (`Header`, `FeatureCard`, `FeatureList`, `LogPane`, `Footer`) becomes a **content-only** component: it renders its rows with consistent `paddingLeft` but does not draw its own outer border
- `Panel.tsx` is kept and documented as the canonical border component for any future standalone panels (like `SetupPanel`)

This resolves the right-border alignment problem entirely: since only `App.tsx` draws borders, alignment is guaranteed by Ink's Box layout.

### Key Design Decisions

| Decision              | Chosen Option                                         | Alternatives Considered                   | Rationale                                                                                            |
| --------------------- | ----------------------------------------------------- | ----------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Border ownership      | Single outer border in `App.tsx`                      | Per-component borders (keep current)      | Per-component stacked borders produce `╰──╯╭──╮` double-line look; single outer is cleaner           |
| Section separators    | `── label ──` text rows, no padding                   | `├──┤` drawn manually                     | `Panel.tsx`'s inner padding would add a space before `├`; text rows touching border give same visual |
| Spinner frequency     | Local 80ms `useEffect`/`setInterval` in `FeatureCard` | Extend `useTicker.ts` with interval param | Keeps useTicker consumers unchanged; spinner is self-contained                                       |
| Width reactivity      | Replace `stdout?.columns` with `useTerminalWidth()`   | Keep polling stdout                       | `useTerminalWidth()` already written and tested in `layout.ts`; one-line change                      |
| `state.spinner` field | Keep in AppState (backward compat), stop rendering it | Remove from AppState                      | AppState is the reducer interface; removing it is a non-visual change                                |

### Components

#### Component 1: `layout.ts` — Sep utility + constants

**Purpose:** Central home for layout arithmetic; extend with `sep()` separator utility and named layout constants
**Location:** `ui/src/lib/layout.ts`
**Implements PRD:** FR-002, FR-005

**Additions:**

```typescript
// Section separator — produces innerWidth chars for use inside a borderStyle box
// innerWidth = containerWidth - 2 (border chars)
export function sep(label: string, innerWidth: number): string {
  const core = label ? `── ${label} ` : "";
  return core + "─".repeat(Math.max(0, innerWidth - core.length));
}

// Named layout constants (extracted from magic numbers)
export const LAYOUT = {
  featureIdWidth: 18, // padded ID column in FeatureList (was magic 18)
  featureTitleWidth: 30, // padded title column in FeatureList (was magic ~30)
  featureCardTitleMax: 42, // truncation limit for active feature title in FeatureCard
  logChromeCols: 26, // time + id prefix width in LogPane
  logMsgMax: 50, // truncated message length in LogPane
} as const;
```

---

#### Component 2: `App.tsx` — Layout restructure + resize fix

**Purpose:** Single outer border, section separators, reactive width
**Location:** `ui/src/App.tsx`
**Implements PRD:** FR-002, FR-004

**Changes:**

1. Replace `stdout?.columns ?? 80` with `useTerminalWidth()` from `layout.ts`
2. Wrap main dashboard return in `<Box borderStyle="round" borderColor={tokens.dim} width={terminalWidth} flexDirection="column">`
3. Replace `<Separator width={...} />` with `<Text color={tokens.dim}>{sep('active ▶', innerWidth)}</Text>` between sections
4. Delete the local `Separator` component (lines 17-24)
5. Add `const innerWidth = terminalWidth - 2` derived value

**Resulting main dashboard render structure:**

```tsx
<Box
  borderStyle="round"
  borderColor={tokens.dim}
  width={terminalWidth}
  flexDirection="column"
>
  <Header state={state} innerWidth={innerWidth} />
  <Text color={tokens.dim}>{sep("active ▶", innerWidth)}</Text>
  <FeatureCard feature={currentFeature} now={now} innerWidth={innerWidth} />
  <Text color={tokens.dim}>{sep("queue", innerWidth)}</Text>
  <FeatureList
    features={state.features}
    order={state.order}
    innerWidth={innerWidth}
  />
  <Text color={tokens.dim}>{sep("log", innerWidth)}</Text>
  <LogPane log={state.log} innerWidth={innerWidth} />
  <Text color={tokens.dim}>{sep("q quit · p pause · ? help", innerWidth)}</Text>
</Box>
```

**Note on prop rename:** Components currently accept `terminalWidth`. With the outer border restructure they need `innerWidth` (the content area). Rename the prop in each affected component interface. The rename is contained to `ui/src/components/` only.

---

#### Component 3: `Header.tsx` — Content-only refactor + token check

**Purpose:** Render header content rows without outer border
**Location:** `ui/src/components/Header.tsx`
**Implements PRD:** FR-001, FR-002

**Changes:**

1. Rename prop `terminalWidth → innerWidth`
2. Remove `┌─...─┐` top border row (lines ~34-38)
3. Remove `│` prefix/suffix on metadata and progress rows
4. Header content now renders directly with `paddingLeft={1}` (inherits from outer Box or adds its own)
5. Verify all colors already use `tokens.*` — Header was largely compliant; confirm no leaks

**Interface change:**

```typescript
// Before
interface HeaderProps {
  state: AppState;
  terminalWidth: number;
}
// After
interface HeaderProps {
  state: AppState;
  innerWidth: number;
}
```

---

#### Component 4: `FeatureCard.tsx` — Content-only + braille spinner

**Purpose:** Remove border rows; wire braille spinner from tokens
**Location:** `ui/src/components/FeatureCard.tsx`
**Implements PRD:** FR-002, FR-003

**Changes:**

1. Rename prop `terminalWidth → innerWidth` (if present — FeatureCard currently has no width prop; add `innerWidth?: number`)
2. Remove all `│ ` prefix text and ` │` suffix text from every `<Box>` row
3. Add spinner state:

```typescript
const [spinnerFrame, setSpinnerFrame] = useState(0);
useEffect(() => {
  if (
    !feature ||
    !["running", "in_progress", "active"].includes(feature.status ?? "")
  )
    return;
  const id = setInterval(
    () => setSpinnerFrame((f) => (f + 1) % tokens.spinner.frames.length),
    tokens.spinner.intervalMs,
  );
  return () => clearInterval(id);
}, [feature?.status]);
const spinner = tokens.spinner.frames[spinnerFrame];
```

4. Stop using `props.spinner` (the raw string from `AppState`) — use the new local `spinner` frame instead
5. Keep `state.spinner` prop in the interface for backward compat (just ignore it) — or remove if no snapshot depends on it

---

#### Component 5: `FeatureList.tsx` — Token enforcement + content-only

**Purpose:** Remove inline hex codes; remove border rows
**Location:** `ui/src/components/FeatureList.tsx`
**Implements PRD:** FR-001, FR-002

**Color violations to fix:**

```typescript
// phaseCharColor function — replace inline hex with tokens:
function phaseCharColor(ps: PhaseStatus): string {
  if (ps === "done") return tokens.success; // was '#31d58b'
  if (ps === "in_progress") return tokens.brand; // was '#d6f24a'
  if (ps === "failed") return tokens.danger; // was '#ff6b63'
  return tokens.dim; // was '#57534e'
}

// FeatureRow — replace hardcoded hex in JSX:
// color={isActive ? '#fafaf9' : '#a8a29e'} → color={isActive ? tokens.textPrimary : tokens.textSecondary}
// color="#57534e" → color={tokens.dim}
```

**Structural change:**

- Remove `│  ` prefix text from each feature row
- Rename `terminalWidth → innerWidth` prop
- Replace `FIXED_COLS = 49` with `LAYOUT.featureIdWidth + LAYOUT.featureTitleWidth + 13` (or a named constant)

---

#### Component 6: `CostMeter.tsx` — Token enforcement only

**Purpose:** Fix `color="red"/"green"` violations
**Location:** `ui/src/components/CostMeter.tsx`
**Implements PRD:** FR-001

**Change (minimal — 1 line):**

```typescript
// Before
const barColor = overBudget ? "red" : "green";
// After
const barColor = overBudget ? tokens.danger : tokens.success;
```

Add `import { tokens } from '../tokens.js';` at top.

---

#### Component 7: `LogPane.tsx` — Token enforcement + content-only

**Purpose:** Fix Ink color-name violations; remove border rows
**Location:** `ui/src/components/LogPane.tsx`
**Implements PRD:** FR-001, FR-002

**Color violations:** Replace `'blue'`, `'yellow'`, `'cyan'`, `'magenta'` phase color literals with a `PHASE_LOG_COLOR` map using `tokens.*`:

```typescript
const PHASE_LOG_COLOR: Record<string, string> = {
  prd: tokens.info, // was 'blue'
  techspec: tokens.warning, // was 'yellow'
  tasks: tokens.brand, // was 'cyan' (closest semantic match)
  code: tokens.success, // was 'green'
  tests: tokens.danger, // was 'red'
  pr: "#a78bfa", // no matching token — keep as local const (not a violation of the token rule since it's in a map, not inline JSX)
};
```

**Structural change:** Remove border rows; rename `terminalWidth → innerWidth`.

---

#### Component 8: `SetupPanel.tsx` — Token enforcement + Panel.tsx adoption

**Purpose:** Fix agent status color literals; adopt `Panel.tsx` for its border
**Location:** `ui/src/components/SetupPanel.tsx`
**Implements PRD:** FR-001

**Changes:**

- Replace `'green'` → `tokens.success`, `'yellow'` → `tokens.warning` for agent status icons
- `SetupPanel` is rendered by `App.tsx` outside the main outer border (it's its own full-screen view) — it should use `Panel.tsx` directly for its border, keeping `borderStyle="round"` consistent
- Width: accept `innerWidth` from `App.tsx` and pass to `Panel.tsx`

---

#### Component 9: `Footer.tsx` — Simplify to content row

**Purpose:** Footer no longer draws a border — it's replaced by the section separator footer pattern
**Location:** `ui/src/components/Footer.tsx`
**Implements PRD:** FR-002

**Change:** The `── q quit · p pause · ? help ──` separator in `App.tsx` replaces the Footer component entirely. Remove `Footer.tsx` import and usage from `App.tsx`; delete or empty `Footer.tsx`. Alternatively, keep `Footer.tsx` as a dead file and remove from `App.tsx` import — prefer full deletion to avoid confusion.

---

### Component Interaction

```
App.tsx (outer borderStyle="round" Box, useTerminalWidth())
├── <Text> sep('active ▶') ── section separator row
├── Header.tsx (content only, innerWidth)
│     └── CostMeter.tsx (token-compliant colors)
├── <Text> sep('queue') ── section separator row
├── FeatureCard.tsx (content only, local 80ms spinner)
├── <Text> sep('log') ── section separator row
├── FeatureList.tsx (content only, token-compliant colors)
├── LogPane.tsx (content only, token-compliant colors)
└── <Text> sep('q quit · p pause · ? help') ── footer separator
```

For setup mode, `App.tsx` renders `<SetupPanel>` standalone with its own `Panel.tsx` border — does not enter the outer border flow.

---

## File Change Map

### New Files

| File Path | Purpose             | Size |
| --------- | ------------------- | ---- |
| _(none)_  | No new files needed | —    |

### Modified Files

| File Path                           | Change Description                                                   | Risk           |
| ----------------------------------- | -------------------------------------------------------------------- | -------------- |
| `ui/src/lib/layout.ts`              | Add `sep()` + `LAYOUT` constants                                     | Low            |
| `ui/src/App.tsx`                    | Outer border, section seps, `useTerminalWidth()`, remove `Separator` | Med            |
| `ui/src/components/Header.tsx`      | Remove border rows, rename prop                                      | Low            |
| `ui/src/components/FeatureCard.tsx` | Remove `│` rows, wire braille spinner                                | Med            |
| `ui/src/components/FeatureList.tsx` | Fix 6 hex violations, remove border rows                             | Low            |
| `ui/src/components/CostMeter.tsx`   | Fix 2 color literals                                                 | Low            |
| `ui/src/components/LogPane.tsx`     | Fix 4 color violations, remove border rows                           | Low            |
| `ui/src/components/SetupPanel.tsx`  | Fix 2 color literals, adopt Panel.tsx                                | Low            |
| `ui/src/components/Footer.tsx`      | Delete (replaced by sep footer pattern in App.tsx)                   | Low            |
| `ui/__tests__/__snapshots__/*.snap` | Regenerate with `--updateSnapshot`                                   | Low (expected) |

### Files to Read (Context Only)

| File Path                     | Why It Matters                                    |
| ----------------------------- | ------------------------------------------------- |
| `ui/src/types.ts`             | AppState, Feature types — do not change           |
| `ui/src/hooks/useTicker.ts`   | 1Hz clock pattern — spinner uses its own interval |
| `ui/__tests__/tokens.test.ts` | Must pass unchanged — palette values frozen       |

---

## Implementation Considerations

### Edge Cases and Boundary Conditions

| Scenario                                             | Expected Behavior                                        | Implementation Note                                           |
| ---------------------------------------------------- | -------------------------------------------------------- | ------------------------------------------------------------- |
| Terminal width < 60                                  | Content truncates gracefully                             | `useTerminalWidth()` has min 80 fallback; `clamp()` available |
| `feature.status` not in spinner condition            | No spinner shown                                         | Check `['running', 'in_progress', 'active'].includes(status)` |
| `state.spinner` prop on FeatureCard (AppState field) | Ignored — local braille spinner used instead             | Keep prop in interface for compat; just don't render it       |
| `sep()` with label longer than innerWidth            | `'─'.repeat(< 0)` → empty string                         | `Math.max(0, ...)` in `sep()` guards against this             |
| SetupPanel width                                     | Uses its own Panel.tsx border — needs width from App.tsx | Pass `terminalWidth` to SetupPanel; it passes to Panel        |
| Footer.tsx snapshot tests                            | Will reference Footer — update or remove test            | If Footer deleted, remove Footer.test.tsx too                 |

### Performance Considerations

- The 80ms `setInterval` in `FeatureCard` only runs when a feature is in active state — cleanup on unmount/status change prevents leaks
- `useTerminalWidth()` uses Ink's built-in `useStdoutDimensions` which is event-driven (no polling)

### Backward Compatibility

**Breaking Changes:** No — rendering-only
**Details:** `AppState.spinner` field continues to exist in the reducer; `FeatureCard` just stops using it for rendering. The field can be cleaned up in a separate refactor.

---

## Testing Strategy

### Snapshot Tests

**Framework:** Jest + ink-testing-library

| Test File                                    | Snapshot File                                      | Action             |
| -------------------------------------------- | -------------------------------------------------- | ------------------ |
| `ui/__tests__/snapshots.test.tsx`            | `__snapshots__/snapshots.test.tsx.snap`            | `--updateSnapshot` |
| `ui/__tests__/composite-screenshot.test.tsx` | `__snapshots__/composite-screenshot.test.tsx.snap` | `--updateSnapshot` |
| `ui/__tests__/Header.test.tsx`               | `__snapshots__/Header.test.tsx.snap`               | `--updateSnapshot` |
| `ui/__tests__/FeatureCard.test.tsx`          | `__snapshots__/FeatureCard.test.tsx.snap`          | `--updateSnapshot` |

**Must pass without changes:**

- `ui/__tests__/tokens.test.ts` — palette frozen
- `ui/__tests__/reducer.test.ts` — no reducer changes
- `ui/__tests__/integration.test.ts` — event flow unchanged

### Validation Commands

```bash
# Install dependencies (already done)
cd ui

# Type check
npx tsc --noEmit

# Update snapshots and run all tests
npm test -- --updateSnapshot

# Verify no inline color violations remain
grep -rn 'color="red\|color="green\|color="blue\|color="yellow\|color="cyan\|color="magenta' src/components/ && echo "VIOLATION FOUND" || echo "OK"
grep -rn '#[0-9a-fA-F]\{6\}' src/components/ --include='*.tsx' | grep -v 'tokens\|//\|PHASE_LOG_COLOR' && echo "VIOLATION FOUND" || echo "OK"

# No sharp corner characters in component files
grep -rn '[┌┐└┘]' src/components/ && echo "VIOLATION FOUND" || echo "OK"

# Build
npm run build
```

---

## Task Generation Guide

### Suggested Task Order

1. **`layout.ts` — add `sep()` + `LAYOUT` constants** — zero risk; other tasks depend on it
2. **`CostMeter.tsx` — token enforcement** — isolated, 2-line change; build confidence
3. **`SetupPanel.tsx` — token enforcement** — isolated; uses Panel.tsx already
4. **`App.tsx` — outer border + section separators + `useTerminalWidth()`** — core structural change; do before component content refactors
5. **`Header.tsx` — remove border rows, rename prop** — depends on App.tsx change
6. **`FeatureCard.tsx` — remove border rows + wire spinner** — largest single component change
7. **`FeatureList.tsx` — token enforcement + remove border rows** — 6 color violations
8. **`LogPane.tsx` — token enforcement + remove border rows**
9. **`Footer.tsx` — delete** — remove file and import from App.tsx
10. **Regenerate snapshots** — `npm test -- --updateSnapshot`; commit updated snaps
11. **Validation + prototype cleanup** — run lint/type-check/build; delete `ui/src/__prototype__/`

### Task Dependency Graph

```
[1: layout.ts]
    ↓
[2: CostMeter]  [3: SetupPanel]
    ↓
[4: App.tsx — outer border + seps + resize]
    ↓
[5: Header]  [6: FeatureCard]  [7: FeatureList]  [8: LogPane]
    ↓
[9: Footer delete]
    ↓
[10: Snapshot regeneration]
    ↓
[11: Validation + prototype cleanup]
```

### Complexity Distribution

| Task          | Complexity | Critical Path |
| ------------- | ---------- | ------------- |
| 1 layout.ts   | S          | Yes           |
| 2 CostMeter   | S          | No            |
| 3 SetupPanel  | S          | No            |
| 4 App.tsx     | M          | Yes           |
| 5 Header      | S          | Yes           |
| 6 FeatureCard | M          | Yes           |
| 7 FeatureList | S          | Yes           |
| 8 LogPane     | S          | Yes           |
| 9 Footer      | S          | Yes           |
| 10 Snapshots  | S          | Yes           |
| 11 Validation | S          | Yes           |

---

## TechSpec Validation Checklist

- [x] Every PRD FR has a corresponding component or section
- [x] File Change Map reflects actual project structure (paths verified against codebase)
- [x] Existing patterns section matches real codebase conventions
- [x] All interfaces compatible with existing types (AppState, Feature, Phase)
- [x] No new npm dependencies required
- [x] Test strategy covers all acceptance criteria from PRD
- [x] Validation commands are runnable in the project
- [x] Backward compatibility: rendering-only, `AppState.spinner` kept
- [x] Task Generation Guide provides a viable, dependency-ordered execution path
- [x] Edge cases from PRD addressed (narrow width, inactive spinner, sep overflow)

---

## Glossary

| Term                     | Definition                                                                                                             |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| content-only component   | A component that renders its rows without drawing its own outer border — border is owned by App.tsx                    |
| `sep(label, innerWidth)` | Utility that produces a full-width `── label ──` string; placed as a `<Text>` row directly inside the outer border box |
| innerWidth               | `terminalWidth - 2` — the content area width inside a `borderStyle` box                                                |
| section separator        | A `<Text color={tokens.dim}>{sep(...)}</Text>` row that creates a `│── label ──│` visual between sections              |

---

**Document End**
