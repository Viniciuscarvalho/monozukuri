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
