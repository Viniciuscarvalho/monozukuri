import React from 'react';
import { render } from 'ink-testing-library';
import { Header } from '../src/components/Header.js';
import { initialState } from '../src/reducer.js';

const baseState = {
  ...initialState(),
  agent: 'claude-code',
  model: 'claude-sonnet-4-6',
  autonomy: 'checkpoint',
  source: 'markdown',
};

describe('Header', () => {
  it('renders agent and model together', () => {
    const { lastFrame } = render(<Header state={baseState} terminalWidth={160} />);
    const frame = lastFrame() ?? '';
    expect(frame).toContain('agent: claude-code');
    expect(frame).toContain('model: claude-sonnet-4-6');
  });

  it.each(['claude-code', 'codex', 'gemini', 'kiro'])(
    'renders %s as agent name',
    (agentName) => {
      const state = { ...baseState, agent: agentName };
      const { lastFrame } = render(<Header state={state} terminalWidth={160} />);
      expect(lastFrame() ?? '').toContain(`agent: ${agentName}`);
    }
  );

  it('renders — when agent is empty', () => {
    const state = { ...baseState, agent: '' };
    const { lastFrame } = render(<Header state={state} terminalWidth={160} />);
    expect(lastFrame() ?? '').toContain('agent: —');
  });

  it('renders autonomy', () => {
    const { lastFrame } = render(<Header state={baseState} terminalWidth={160} />);
    expect(lastFrame() ?? '').toContain('autonomy: checkpoint');
  });
});
