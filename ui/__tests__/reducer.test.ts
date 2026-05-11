import { initialState, reducer } from '../src/reducer.js';
import type { MonozukuriEvent } from '../src/types.js';

const BASE_RUN_STARTED: MonozukuriEvent = {
  type: 'run.started',
  ts: '2026-04-25T10:00:00Z',
  run_id: 'abc123',
  autonomy: 'checkpoint',
  model: 'claude-sonnet-4-6',
  agent: 'claude-code',
  source: 'markdown',
  feature_count: 1,
};

describe('initialState', () => {
  it('has empty agent', () => {
    expect(initialState().agent).toBe('');
  });
});

describe('reducer run.started', () => {
  it.each(['claude-code', 'codex', 'gemini', 'kiro'])(
    'sets agent to %s',
    (agentName) => {
      const event: MonozukuriEvent = { ...BASE_RUN_STARTED, agent: agentName };
      const state = reducer(initialState(), event);
      expect(state.agent).toBe(agentName);
    }
  );

  it('defaults agent to empty string when field missing', () => {
    const event = { ...BASE_RUN_STARTED } as MonozukuriEvent;
    // Simulate missing agent field (back-compat with old event streams)
    const { agent: _agent, ...eventWithoutAgent } = event as typeof BASE_RUN_STARTED;
    const state = reducer(initialState(), eventWithoutAgent as MonozukuriEvent);
    expect(state.agent).toBe('');
  });

  it('preserves other state fields', () => {
    const state = reducer(initialState(), BASE_RUN_STARTED);
    expect(state.runId).toBe('abc123');
    expect(state.model).toBe('claude-sonnet-4-6');
    expect(state.autonomy).toBe('checkpoint');
    expect(state.agent).toBe('claude-code');
  });
});

describe('reducer phase.token_update (PR #176 events)', () => {
  const FEAT_ID = 'feat-001';

  const seedWithFeature = () => {
    let state = reducer(initialState(), {
      type: 'run.started',
      ts: '2026-05-11T00:00:00Z',
      run_id: 'run-1',
      autonomy: 'checkpoint',
      model: 'claude-sonnet-4-6',
      agent: 'claude-code',
    } as MonozukuriEvent);
    state = reducer(state, {
      type: 'feature.started',
      ts: '2026-05-11T00:00:00Z',
      run_id: 'run-1',
      feature_id: FEAT_ID,
      title: 'test',
    } as MonozukuriEvent);
    return state;
  };

  it('updates tokensOut on phase.token_update', () => {
    let state = seedWithFeature();
    state = reducer(state, {
      type: 'phase.token_update',
      ts: '2026-05-11T00:00:01Z',
      run_id: 'run-1',
      feature_id: FEAT_ID,
      phase: 'code',
      tokens_out: 100,
      tokens_in: 500,
    } as MonozukuriEvent);
    expect(state.features[FEAT_ID].tokensOut).toBe(100);
    expect(state.features[FEAT_ID].tokensIn).toBe(500);
  });

  it('computes tokenRate from successive samples within 60s', () => {
    let state = seedWithFeature();
    const real = Date.now;
    let t = 1_700_000_000_000;
    Date.now = () => t;
    try {
      state = reducer(state, {
        type: 'phase.token_update',
        ts: '2026-05-11T00:00:01Z',
        run_id: 'run-1',
        feature_id: FEAT_ID,
        phase: 'code',
        tokens_out: 100,
      } as MonozukuriEvent);
      t += 6_000; // 6s later, 600 more tokens → 6000 tokens/min
      state = reducer(state, {
        type: 'phase.token_update',
        ts: '2026-05-11T00:00:07Z',
        run_id: 'run-1',
        feature_id: FEAT_ID,
        phase: 'code',
        tokens_out: 700,
      } as MonozukuriEvent);
    } finally {
      Date.now = real;
    }
    expect(state.features[FEAT_ID].tokensOut).toBe(700);
    expect(state.features[FEAT_ID].tokenRate).toBeCloseTo(6000, -1);
  });

  it('does not compute rate when samples are > 60s apart (stale sample)', () => {
    let state = seedWithFeature();
    const real = Date.now;
    let t = 1_700_000_000_000;
    Date.now = () => t;
    try {
      state = reducer(state, {
        type: 'phase.token_update',
        ts: '2026-05-11T00:00:01Z',
        run_id: 'run-1',
        feature_id: FEAT_ID,
        phase: 'code',
        tokens_out: 100,
      } as MonozukuriEvent);
      t += 120_000; // 2 minutes later
      state = reducer(state, {
        type: 'phase.token_update',
        ts: '2026-05-11T00:02:01Z',
        run_id: 'run-1',
        feature_id: FEAT_ID,
        phase: 'code',
        tokens_out: 1000,
      } as MonozukuriEvent);
    } finally {
      Date.now = real;
    }
    expect(state.features[FEAT_ID].tokensOut).toBe(1000);
    expect(state.features[FEAT_ID].tokenRate).toBeUndefined();
  });
});

describe('reducer phase.completed (PR #176 extended fields)', () => {
  const FEAT_ID = 'feat-001';

  const seedWithFeature = () => {
    let state = reducer(initialState(), {
      type: 'run.started',
      ts: '2026-05-11T00:00:00Z',
      run_id: 'run-1',
      autonomy: 'checkpoint',
      model: 'claude-sonnet-4-6',
      agent: 'claude-code',
    } as MonozukuriEvent);
    state = reducer(state, {
      type: 'feature.started',
      ts: '2026-05-11T00:00:00Z',
      run_id: 'run-1',
      feature_id: FEAT_ID,
      title: 'test',
    } as MonozukuriEvent);
    return state;
  };

  it('captures tokens_in/out/total and cache counts on phase.completed', () => {
    let state = seedWithFeature();
    state = reducer(state, {
      type: 'phase.completed',
      ts: '2026-05-11T00:00:01Z',
      run_id: 'run-1',
      feature_id: FEAT_ID,
      phase: 'code',
      tokens_in: 1234,
      tokens_out: 180,
      tokens_total: 1414,
      cache_creation_input_tokens: 500,
      cache_read_input_tokens: 2000,
    } as MonozukuriEvent);
    const f = state.features[FEAT_ID];
    expect(f.tokensIn).toBe(1234);
    expect(f.tokensOut).toBe(180);
    expect(f.tokensTotal).toBe(1414);
    expect(f.cacheCreationTokens).toBe(500);
    expect(f.cacheReadTokens).toBe(2000);
    expect(f.tokens).toBe(1414); // resolved from tokens_total
  });

  it('falls back to legacy tokens_used when new fields missing', () => {
    let state = seedWithFeature();
    state = reducer(state, {
      type: 'phase.completed',
      ts: '2026-05-11T00:00:01Z',
      run_id: 'run-1',
      feature_id: FEAT_ID,
      phase: 'code',
      tokens_used: 999,
      cost_usd: 0.42,
    } as MonozukuriEvent);
    expect(state.features[FEAT_ID].tokens).toBe(999);
    expect(state.features[FEAT_ID].costUsd).toBeCloseTo(0.42);
  });

  it('clears live tokenRate when phase ends', () => {
    let state = seedWithFeature();
    state = reducer(state, {
      type: 'phase.token_update',
      ts: '2026-05-11T00:00:01Z',
      run_id: 'run-1',
      feature_id: FEAT_ID,
      phase: 'code',
      tokens_out: 100,
    } as MonozukuriEvent);
    state = reducer(state, {
      type: 'phase.completed',
      ts: '2026-05-11T00:00:02Z',
      run_id: 'run-1',
      feature_id: FEAT_ID,
      phase: 'code',
      tokens_total: 100,
    } as MonozukuriEvent);
    expect(state.features[FEAT_ID].tokenRate).toBeUndefined();
    expect(state.features[FEAT_ID].tokensSampledAt).toBeUndefined();
  });
});
