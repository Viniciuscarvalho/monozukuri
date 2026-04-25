import React, { useState } from 'react';
import { Box, Text, useStdout } from 'ink';
import { Header } from './components/Header.js';
import { FeatureCard } from './components/FeatureCard.js';
import { FeatureList } from './components/FeatureList.js';
import { LogPane } from './components/LogPane.js';
import { Footer } from './components/Footer.js';
import { useEventStream } from './hooks/useEventStream.js';
import { useKeybindings } from './hooks/useKeybindings.js';
import { useTicker } from './hooks/useTicker.js';
import type { ViewMode } from './types.js';

function Separator({ width }: { width: number }): React.ReactElement {
  const dashes = '─'.repeat(Math.max(0, width - 2));
  return (
    <Box>
      <Text>{'├' + dashes + '┤'}</Text>
    </Box>
  );
}

export default function App(): React.ReactElement {
  const [view, setView] = useState<ViewMode>('main');
  const state = useEventStream();
  const now = useTicker();
  const { stdout } = useStdout();
  const terminalWidth = stdout?.columns ?? 80;

  useKeybindings({ setView });

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
  return (
    <Box flexDirection="column">
      {/* Header: title bar + metadata + progress */}
      <Header state={state} terminalWidth={terminalWidth} />

      {/* Separator */}
      <Separator width={terminalWidth} />

      {/* Active feature card */}
      <FeatureCard feature={currentFeature} spinner={state.spinner} now={now} />

      {/* Queue + Done split pane */}
      <FeatureList
        features={state.features}
        order={state.order}
        terminalWidth={terminalWidth}
      />

      {/* Log tail */}
      <LogPane log={state.log} terminalWidth={terminalWidth} />

      {/* Footer */}
      <Footer terminalWidth={terminalWidth} />
    </Box>
  );
}
