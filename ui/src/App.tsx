import React, { useEffect, useState } from 'react';
import { writeFileSync } from 'node:fs';
import { Box, Text } from 'ink';
import { cleanup } from './runtime.js';
import { tokens } from './tokens.js';
import { useTerminalWidth, sep } from './lib/layout.js';
import { Header } from './components/Header.js';
import { FeatureCard } from './components/FeatureCard.js';
import { FeatureList } from './components/FeatureList.js';
import { LogPane } from './components/LogPane.js';
import { SetupPanel } from './components/SetupPanel.js';
import { useEventStream } from './hooks/useEventStream.js';
import { useKeybindings } from './hooks/useKeybindings.js';
import { useTicker } from './hooks/useTicker.js';
import type { ViewMode } from './types.js';

export default function App(): React.ReactElement {
  const [view, setView] = useState<ViewMode>('main');
  const [done, setDone] = useState(false);
  const state = useEventStream();
  const now = useTicker();
  const terminalWidth = useTerminalWidth();
  const innerWidth = terminalWidth - 2;

  useKeybindings({ setView });

  // When run.completed arrives, surface the summary frame briefly then exit
  useEffect(() => {
    if (state.current === null && state.totals.succeeded + state.totals.failed > 0) {
      setDone(true);
      // Write plain-text summary to /dev/tty so it persists in scrollback after Ink unmounts
      try {
        const summary = [
          '',
          `  Monozukuri run complete`,
          `  ✓ done: ${state.totals.succeeded}   ✗ failed: ${state.totals.failed}   ~ skipped: ${state.totals.skipped}`,
          `  cost: $${(state.totals.costUsd ?? 0).toFixed(4)}`,
          '',
        ].join('\n');
        writeFileSync('/dev/tty', summary);
      } catch {
        // /dev/tty may not be writable in some environments
      }
      setTimeout(() => { cleanup?.(); process.exit(0); }, 200);
    }
  }, [state.current, state.totals]);

  if (done) {
    return (
      <Box flexDirection="column" paddingY={1}>
        <Text bold color={tokens.success}>Run complete</Text>
        <Text>
          {'  '}
          <Text color={tokens.success}>✓ {state.totals.succeeded} done</Text>
          {'  '}
          <Text color={tokens.danger}>✗ {state.totals.failed} failed</Text>
          {'  '}
          <Text dimColor>~ {state.totals.skipped} skipped</Text>
        </Text>
        <Text dimColor>  cost: ${(state.totals.costUsd ?? 0).toFixed(4)}</Text>
      </Box>
    );
  }

  const currentFeature = state.current ? (state.features[state.current] ?? null) : null;

  if (view === 'help') {
    return (
      <Box flexDirection="column">
        <Text bold>Monozukuri — Keyboard Shortcuts</Text>
        <Text> </Text>
        <Text>{'  q         Quit (sends SIGINT to orchestrator)'}</Text>
        <Text>{'  p         Pause / resume orchestrator (SIGUSR1)'}</Text>
        <Text>{'  l         View learnings'}</Text>
        <Text>{'  f         Filter features'}</Text>
        <Text>{'  /         Search'}</Text>
        <Text>{'  ?         This help screen'}</Text>
        <Text>{'  Escape    Return to main view'}</Text>
        <Text> </Text>
        <Text dimColor>Press Escape to return.</Text>
      </Box>
    );
  }

  if (view === 'learnings') {
    return (
      <Box flexDirection="column">
        <Text bold>Learnings view</Text>
        <Text dimColor>(not yet implemented — press Escape to return)</Text>
      </Box>
    );
  }

  if (view === 'filter') {
    return (
      <Box flexDirection="column">
        <Text bold>Filter view</Text>
        <Text dimColor>(not yet implemented — press Escape to return)</Text>
      </Box>
    );
  }

  if (view === 'search') {
    return (
      <Box flexDirection="column">
        <Text bold>Search view</Text>
        <Text dimColor>(not yet implemented — press Escape to return)</Text>
      </Box>
    );
  }

  // Main dashboard view
  if (state.setupMode) {
    return <SetupPanel state={state} />;
  }

  return (
    <Box borderStyle="round" borderColor={tokens.dim} width={terminalWidth} flexDirection="column">
      <Header state={state} innerWidth={innerWidth} />
      <Text color={tokens.dim}>{sep('active ▶', innerWidth)}</Text>
      <FeatureCard feature={currentFeature} now={now} innerWidth={innerWidth} />
      <Text color={tokens.dim}>{sep('queue', innerWidth)}</Text>
      <FeatureList features={state.features} order={state.order} innerWidth={innerWidth} />
      <Text color={tokens.dim}>{sep('log', innerWidth)}</Text>
      <LogPane log={state.log} innerWidth={innerWidth} />
      <Text color={tokens.dim}>{sep('q quit · p pause · ? help', innerWidth)}</Text>
    </Box>
  );
}
