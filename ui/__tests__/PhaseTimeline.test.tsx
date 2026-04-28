import React from 'react';
import { render } from 'ink-testing-library';
import { PhaseTimeline } from '../src/components/PhaseTimeline.js';
import type { Phase, PhaseStatus } from '../src/types.js';

function allPhases(status: PhaseStatus): Record<Phase, PhaseStatus> {
  return { prd: status, techspec: status, tasks: status, code: status, tests: status, pr: status };
}

describe('PhaseTimeline', () => {
  it('renders all pending phases', () => {
    const { lastFrame } = render(<PhaseTimeline phases={allPhases('pending')} />);
    const frame = lastFrame() ?? '';
    expect(frame).toContain('○');
    expect(frame).toContain('PRD');
    expect(frame).toContain('PR');
  });

  it('renders all done phases', () => {
    const { lastFrame } = render(<PhaseTimeline phases={allPhases('done')} />);
    const frame = lastFrame() ?? '';
    expect(frame).toContain('●');
  });

  it('renders in-progress phase', () => {
    const phases = { ...allPhases('pending'), prd: 'in_progress' as PhaseStatus };
    const { lastFrame } = render(<PhaseTimeline phases={phases} />);
    const frame = lastFrame() ?? '';
    expect(frame).toContain('◐');
  });

  it('renders failed phase', () => {
    const phases = { ...allPhases('done'), code: 'failed' as PhaseStatus };
    const { lastFrame } = render(<PhaseTimeline phases={phases} />);
    const frame = lastFrame() ?? '';
    expect(frame).toContain('✗');
  });

  it('renders all 6 phase labels', () => {
    const { lastFrame } = render(<PhaseTimeline phases={allPhases('pending')} />);
    const frame = lastFrame() ?? '';
    for (const label of ['PRD', 'TechSpec', 'Tasks', 'Code', 'Tests', 'PR']) {
      expect(frame).toContain(label);
    }
  });
});
