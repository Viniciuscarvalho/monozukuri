# Tasks: Ink TUI Visual Polish (ux-tui-polish)

## Task 1: Add `sep()` utility and `LAYOUT` constants to `layout.ts`

**Estimated effort**: 10 minutes

**Description**: Extend `ui/src/lib/layout.ts` with the `sep()` separator string builder and named `LAYOUT` constants. This is the foundation task — all other tasks depend on `sep()` being available.

**Files to modify**:

- `ui/src/lib/layout.ts`

**Implementation details**:

- Add `export function sep(label: string, innerWidth: number): string` — produces `── label ─────` of exactly `innerWidth` chars; uses `Math.max(0, ...)` guard
- Add `export const LAYOUT = { featureIdWidth: 18, featureTitleWidth: 30, featureCardTitleMax: 42, logChromeCols: 26, logMsgMax: 50 } as const`
- Keep existing `useTerminalWidth()` and `clamp()` exports unchanged

**Success criteria**:

- `sep('log', 80)` returns string of exactly 80 chars
- `sep('', 80)` returns 80 `─` chars (empty label path)
- `sep('very long label exceeding width', 5)` returns empty string without throwing
- TypeScript compiles with `npx tsc --noEmit`

---

## Task 2: Fix `CostMeter.tsx` color violations

**Estimated effort**: 5 minutes

**Description**: Replace `color="red"` and `color="green"` Ink color literals in `CostMeter.tsx` with `tokens.danger` and `tokens.success`.

**Files to modify**:

- `ui/src/components/CostMeter.tsx`

**Implementation details**:

- Add `import { tokens } from '../tokens.js';` if not already present
- Replace `const barColor = overBudget ? 'red' : 'green'` with `const barColor = overBudget ? tokens.danger : tokens.success`

**Success criteria**:

- No `color="red"` or `color="green"` literals in file
- `grep -n '"red"\|"green"' src/components/CostMeter.tsx` returns nothing
- TypeScript compiles

---

## Task 3: Fix `SetupPanel.tsx` color violations

**Estimated effort**: 10 minutes

**Description**: Replace `'green'` and `'yellow'` Ink color literals in `SetupPanel.tsx` with `tokens.success` and `tokens.warning`. Verify that `SetupPanel` already uses or can use `Panel.tsx` for its border.

**Files to modify**:

- `ui/src/components/SetupPanel.tsx`

**Implementation details**:

- Replace agent status icon color `'green'` → `tokens.success`
- Replace skill/warning color `'yellow'` → `tokens.warning`
- Ensure `import { tokens }` is present
- `SetupPanel` is rendered as a standalone full-screen view — it should use `borderStyle="round"` (via `Panel.tsx` or directly) for its outer border; verify this is already the case or adopt `Panel.tsx`

**Success criteria**:

- No `'green'` or `'yellow'` literals in file
- `grep -n "'green'\|'yellow'" src/components/SetupPanel.tsx` returns nothing
- TypeScript compiles

---

## Task 4: Restructure `App.tsx` — outer border, section separators, reactive width

**Estimated effort**: 30 minutes

**Description**: Core structural change. Wrap the main dashboard in a single outer `Box borderStyle="round"`, replace the inline `Separator` component with `sep()` text rows, and switch from `stdout?.columns ?? 80` to `useTerminalWidth()`. This is the central dependency for all per-component content-only refactors.

**Files to modify**:

- `ui/src/App.tsx`

**Implementation details**:

- Remove the local `Separator` component (current lines ~17–24)
- Import `useTerminalWidth`, `sep` from `../lib/layout.js`
- Replace `const width = stdout?.columns ?? 80` (or equivalent) with `const terminalWidth = useTerminalWidth()`
- Derive `const innerWidth = terminalWidth - 2`
- Wrap main dashboard JSX in:
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
    <Text color={tokens.dim}>
      {sep("q quit · p pause · ? help", innerWidth)}
    </Text>
  </Box>
  ```
- Remove Footer import and usage (replaced by sep footer separator above)
- For setup mode view, render `<SetupPanel>` standalone (not inside outer Box); pass `terminalWidth`
- For run-complete / done view, render with appropriate border or reuse outer Box

**Success criteria**:

- App renders without throwing
- No local `Separator` component in file
- No `stdout?.columns` reference in file
- TypeScript compiles
- `npm test` runs (will fail snapshots — expected; fix in Task 10)

---

## Task 5: Refactor `Header.tsx` — content-only, rename prop

**Estimated effort**: 15 minutes

**Description**: Make `Header.tsx` a content-only component. Remove its outer border rows (`┌─...─┐` top line, any manual `│` chars). Rename the prop `terminalWidth → innerWidth`.

**Files to modify**:

- `ui/src/components/Header.tsx`

**Implementation details**:

- Change interface: `terminalWidth: number` → `innerWidth: number`
- Remove any `┌`, `┐`, `└`, `┘`, or manual top/bottom border `Text` rows
- Remove `│ ` prefix text and ` │` suffix text from content rows if present
- Keep `paddingLeft={1}` on content boxes so text doesn't touch left border of App.tsx outer box
- Verify all colors use `tokens.*` — Header was mostly compliant already
- Use `innerWidth` (not `innerWidth + 2`) for any fill calculations (sep, dash fill, etc.)

**Success criteria**:

- No `┌┐└┘` chars in file
- No `│ ` string literal used as border prefix
- Prop is `innerWidth`
- TypeScript compiles

---

## Task 6: Refactor `FeatureCard.tsx` — content-only + wire braille spinner

**Estimated effort**: 25 minutes

**Description**: Largest single-component change. Remove all manual border rows (`│ ` prefix text). Wire the braille spinner from `tokens.spinner.frames` with a local 80ms `setInterval` instead of rendering `props.spinner` (the raw string label from AppState).

**Files to modify**:

- `ui/src/components/FeatureCard.tsx`

**Implementation details**:

- Add `innerWidth?: number` to props interface; default to 80 if absent
- Remove all `│ ` prefix text and ` │` suffix text from every row
- Remove any `┌─...─┐` / `└─...─┘` border row elements
- Add spinner state wiring:
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
- Use local `spinner` in JSX instead of `props.spinner`
- Keep `props.spinner` in the interface (just don't render it) for AppState backward compat — or remove if no test asserts on it
- Use `LAYOUT.featureCardTitleMax` (from `layout.ts`) instead of magic `42` for title truncation

**Success criteria**:

- No `│ ` border prefix strings in JSX
- Braille char (`⠋⠙⠹⠸...`) appears in the rendered output for active features
- No `props.spinner` render path
- TypeScript compiles

---

## Task 7: Refactor `FeatureList.tsx` — 6 hex violations + content-only

**Estimated effort**: 20 minutes

**Description**: Replace 6 inline hex color codes with `tokens.*` references. Remove border rows. Replace magic `FIXED_COLS` constant.

**Files to modify**:

- `ui/src/components/FeatureList.tsx`

**Implementation details**:

- Fix `phaseCharColor()` function:
  ```typescript
  function phaseCharColor(ps: PhaseStatus): string {
    if (ps === "done") return tokens.success; // was '#31d58b'
    if (ps === "in_progress") return tokens.brand; // was '#d6f24a'
    if (ps === "failed") return tokens.danger; // was '#ff6b63'
    return tokens.dim; // was '#57534e'
  }
  ```
- In JSX feature rows, replace:
  - `color={isActive ? '#fafaf9' : '#a8a29e'}` → `color={isActive ? tokens.textPrimary : tokens.textSecondary}`
  - `color="#57534e"` → `color={tokens.dim}`
- Remove `FIXED_COLS = 49` magic constant; use `LAYOUT.featureIdWidth + LAYOUT.featureTitleWidth + 13` or a named derivation
- Rename prop `terminalWidth → innerWidth`
- Remove `│  ` prefix text from each feature row
- Remove any `┌─...─┐` / `└─...─┘` border row elements

**Success criteria**:

- `grep -n '#[0-9a-fA-F]\{6\}' src/components/FeatureList.tsx` returns nothing (outside comments)
- No `FIXED_COLS` literal in file
- TypeScript compiles

---

## Task 8: Refactor `LogPane.tsx` — 4 Ink color violations + content-only

**Estimated effort**: 15 minutes

**Description**: Replace Ink color-name strings (`'blue'`, `'yellow'`, `'cyan'`, `'magenta'`) in `LogPane.tsx` with a `PHASE_LOG_COLOR` map using `tokens.*`. Remove border rows.

**Files to modify**:

- `ui/src/components/LogPane.tsx`

**Implementation details**:

- Replace the phase color map with:
  ```typescript
  const PHASE_LOG_COLOR: Record<string, string> = {
    prd: tokens.info, // was 'blue'
    techspec: tokens.warning, // was 'yellow'
    tasks: tokens.brand, // was 'cyan'
    code: tokens.success, // was 'green'
    tests: tokens.danger, // was 'red'
    pr: "#a78bfa", // no matching token — local const acceptable
  };
  ```
- Remove `│` prefix/suffix rows
- Rename `terminalWidth → innerWidth`
- Use `LAYOUT.logChromeCols` and `LAYOUT.logMsgMax` instead of magic `42`
- Keep `paddingLeft={1}` on content

**Success criteria**:

- No Ink color name literals (`'blue'`, `'yellow'`, `'cyan'`, `'magenta'`, `'red'`, `'green'`) in file
- `grep -n "'blue'\|'yellow'\|'cyan'\|'magenta'" src/components/LogPane.tsx` returns nothing
- TypeScript compiles

---

## Task 9: Delete `Footer.tsx`

**Estimated effort**: 5 minutes

**Description**: `Footer.tsx` is fully replaced by the `sep('q quit · p pause · ? help', innerWidth)` text row at the bottom of `App.tsx`'s outer Box. Delete the file and remove any remaining imports or test files.

**Files to modify**:

- Delete `ui/src/components/Footer.tsx`
- Remove `Footer` import from `ui/src/App.tsx` (should already be removed in Task 4)
- Delete `ui/__tests__/Footer.test.tsx` if it exists

**Implementation details**:

- Verify Footer is no longer imported anywhere: `grep -rn 'Footer' src/`
- Delete the file

**Success criteria**:

- `Footer.tsx` does not exist
- No import of `Footer` anywhere in `src/`
- `grep -rn 'Footer' src/` returns nothing

---

## Task 10: Regenerate snapshots

**Estimated effort**: 10 minutes

**Description**: Run the full test suite with `--updateSnapshot` to regenerate all Ink snapshot files that changed due to the visual restructure. Verify that `tokens.test.ts` and `reducer.test.ts` pass without changes.

**Files to modify**:

- `ui/__tests__/__snapshots__/snapshots.test.tsx.snap`
- `ui/__tests__/__snapshots__/composite-screenshot.test.tsx.snap`
- `ui/__tests__/__snapshots__/Header.test.tsx.snap` (if exists)
- `ui/__tests__/__snapshots__/FeatureCard.test.tsx.snap` (if exists)

**Implementation details**:

```bash
cd ui
npm test -- --updateSnapshot
```

- Confirm `tokens.test.ts` passes (palette unchanged)
- Confirm `reducer.test.ts` passes (no reducer changes)
- Confirm `integration.test.ts` passes (IPC/event flow unchanged)
- All snapshot files committed

**Success criteria**:

- `npm test` exits 0 with no failures after snapshot update
- `tokens.test.ts` passed without `--updateSnapshot`
- New snapshot content reflects rounded border and braille spinner

---

## Task 11: Validation pass + delete prototype

**Estimated effort**: 10 minutes

**Description**: Run all lint/type-check/violation-grep commands to confirm zero remaining violations. Delete the throwaway prototype directory. Run `npm run build` for clean production build.

**Files to modify**:

- Delete `ui/src/__prototype__/` (entire directory)

**Implementation details**:

```bash
cd ui

# Type check
npx tsc --noEmit

# Inline color violations
grep -rn 'color="red\|color="green\|color="blue\|color="yellow\|color="cyan\|color="magenta' src/components/ && echo "VIOLATION" || echo "OK"
grep -rn '#[0-9a-fA-F]\{6\}' src/components/ --include='*.tsx' | grep -v '//' && echo "VIOLATION" || echo "OK"

# Sharp corner characters
grep -rn '[┌┐└┘]' src/components/ && echo "VIOLATION" || echo "OK"

# Build
npm run build

# Delete prototype
rm -rf src/__prototype__/
```

**Success criteria**:

- All three grep checks return "OK"
- `npx tsc --noEmit` exits 0
- `npm run build` exits 0
- `ui/src/__prototype__/` does not exist
- `npm test` still exits 0 after prototype deletion
