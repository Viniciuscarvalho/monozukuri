import React from 'react';
import { Box } from 'ink';
import { render } from 'ink-testing-library';
import { Header } from '../src/components/Header.js';
import { FeatureCard } from '../src/components/FeatureCard.js';
import { Footer } from '../src/components/Footer.js';
import { initialState } from '../src/reducer.js';
import type { Feature, Phase, PhaseStatus } from '../src/types.js';

// Composite "screenshot" — renders the major TUI components together with
// realistic mock state, as if a phase were mid-execution with the full
// telemetry pipeline (Days 1→5) flowing. Output is captured as text via
// ink-testing-library's lastFrame(). Use this when you want to eyeball the
// final visual without spawning a real terminal + Claude CLI.

const pendingPhases: Record<Phase, PhaseStatus> = {
  prd: 'pending', techspec: 'pending', tasks: 'pending',
  code: 'pending', tests: 'pending', pr: 'pending',
};

const NOW = new Date('2026-05-11T10:05:53Z');

const headerState = {
  ...initialState(),
  runId: 'run-abc123def456',
  agent: 'claude-code',
  model: 'claude-sonnet-4-6',
  autonomy: 'checkpoint',
  source: 'markdown',
};

const activeFeature: Feature = {
  id: 'feat-005',
  title: 'Add greeting API endpoint',
  status: 'active',
  phases: {
    ...pendingPhases,
    prd: 'done', techspec: 'done', tasks: 'done',
    code: 'in_progress',
  },
  currentPhase: 'code',
  tokensOut: 1840,
  tokensIn: 32540,
  tokensTotal: undefined,
  tokenRate: 4200,
  tokensSampledAt: NOW.getTime() - 1500,
  cacheCreationTokens: 1200,
  cacheReadTokens: 28000,
  estimatedTokens: 5000,
  costUsd: 1.84,
  startedAt: '2026-05-11T10:00:00Z',
  currentSkill: 'mz-execute-task',
  currentTier: 'project',
  compaction: 'none',
  recentEvents: [
    { ts: new Date('2026-05-11T10:05:38Z').getTime(), tool: 'Read',  target: 'src/services/api.js' },
    { ts: new Date('2026-05-11T10:05:43Z').getTime(), tool: 'Edit',  target: 'src/services/api.js' },
    { ts: new Date('2026-05-11T10:05:50Z').getTime(), tool: 'Bash',  target: 'npm test' },
  ],
};

describe('composite — full TUI render with all five PRs applied', () => {
  it('captures the full Header + FeatureCard + Footer stack with live telemetry', () => {
    const Composite = () => (
      <Box flexDirection="column">
        <Header state={headerState} terminalWidth={88} />
        <FeatureCard feature={activeFeature} spinner="⠋ Editing src/services/api.js" now={NOW} />
        <Footer terminalWidth={88} />
      </Box>
    );

    const { lastFrame } = render(<Composite />);
    const frame = lastFrame() ?? '';

    // The frame is the "screenshot" — log it so the test output doubles as
    // a visual artifact when run interactively. Also commit it as a snapshot
    // so changes are caught explicitly.
    // eslint-disable-next-line no-console
    console.log('\n=== COMPOSITE TUI FRAME ===\n' + frame + '\n=== END ===\n');

    expect(frame).toMatchSnapshot();

    // Sanity checks that the chain of five PRs all contributed something:
    //   Day 1 (#176): n/a — bash-side
    //   Day 2 (#177): reducer accepted tokens fields → "2k" / "4.2k/min" appear
    //   Day 3 (#178): tokens.ts symbols → no hardcoded "color=" patterns
    //   Day 4 (#179): FeatureCard activity tree → "recent activity" + tree chars
    //   Day 5 (#180): minimal footer → "q quit · p pause · ? help"
    expect(frame).toContain('feat-005');                  // FeatureCard renders ID
    expect(frame).toContain('Add greeting API endpoint'); // and title
    expect(frame).toContain('2k');                        // tokensOut from #177 + #179
    expect(frame).toContain('4.2k/min');                  // tokenRate from #177 + #179
    expect(frame).toContain('recent activity');           // Day 4 #179 section
    expect(frame).toContain('Read');
    expect(frame).toContain('Edit');
    expect(frame).toContain('Bash');
    expect(frame).toContain('├─');                        // Day 4 tree chars
    expect(frame).toContain('└─');                        // Day 4 tree chars (last)
    expect(frame).toContain('q quit');                    // Day 5 #180 footer
    expect(frame).toContain('p pause');
    expect(frame).toContain('? help');
    expect(frame).not.toContain('learnings');             // Day 5 trim
    expect(frame).not.toContain('search');                // Day 5 trim
  });
});
