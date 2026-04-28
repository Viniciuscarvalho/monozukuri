import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { initialState, reducer } from '../src/reducer.js';
import type { MonozukuriEvent } from '../src/types.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const FIXTURES_DIR = join(__dirname, 'fixtures/events');
const ADAPTERS = ['claude-code', 'codex', 'gemini', 'kiro'] as const;

function replayFixture(name: string) {
  const lines = readFileSync(join(FIXTURES_DIR, `${name}.jsonl`), 'utf-8')
    .split('\n')
    .filter(Boolean);
  return lines.reduce(
    (state, line) => reducer(state, JSON.parse(line) as MonozukuriEvent),
    initialState()
  );
}

describe.each(ADAPTERS)('integration: %s fixture', (adapter) => {
  let state: ReturnType<typeof replayFixture>;

  beforeAll(() => {
    state = replayFixture(adapter);
  });

  it('sets the agent name', () => {
    expect(state.agent).toBe(adapter);
  });

  it('has a run ID', () => {
    expect(state.runId).toBeTruthy();
  });

  it('loads at least one feature', () => {
    expect(Object.keys(state.features).length).toBeGreaterThan(0);
  });

  it('marks the first feature as done after run completes', () => {
    const firstId = state.order[0];
    expect(firstId).toBeTruthy();
    expect(state.features[firstId!]?.status).toBe('done');
  });

  it('records cost in totals', () => {
    expect(state.totals.costUsd).toBeGreaterThan(0);
  });

  it('records success in totals', () => {
    expect(state.totals.succeeded).toBeGreaterThan(0);
  });
});
