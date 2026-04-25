import React from 'react';
import { Box, Text } from 'ink';
import type { LogLine } from '../types.js';

type InkColor = 'black' | 'red' | 'green' | 'yellow' | 'blue' | 'magenta' | 'cyan' | 'white' | 'gray';

const PHASE_COLORS: Record<string, InkColor> = {
  code: 'blue',
  tests: 'yellow',
  pr: 'cyan',
  prd: 'magenta',
  techspec: 'green',
  tasks: 'white',
};

interface LogPaneProps {
  log: LogLine[];
  terminalWidth: number;
}

function formatTime(ts: string): string {
  try {
    const d = new Date(ts);
    if (isNaN(d.getTime())) return ts.slice(0, 8);
    const hh = String(d.getHours()).padStart(2, '0');
    const mm = String(d.getMinutes()).padStart(2, '0');
    const ss = String(d.getSeconds()).padStart(2, '0');
    return `${hh}:${mm}:${ss}`;
  } catch {
    return '??:??:??';
  }
}

function truncate(str: string, maxLen: number): string {
  if (str.length <= maxLen) return str;
  return str.slice(0, maxLen - 1) + '…';
}

export function LogPane({ log, terminalWidth }: LogPaneProps): React.ReactElement {
  const tail = log.slice(-5);
  const maxTextLen = Math.max(20, terminalWidth - 42);

  // Section header
  const headerDashes = '─'.repeat(Math.max(0, terminalWidth - 16));

  return (
    <Box flexDirection="column">
      {/* Section header */}
      <Box>
        <Text>├─ log (tail) </Text>
        <Text dimColor>{headerDashes}</Text>
        <Text>┤</Text>
      </Box>

      {tail.length === 0 ? (
        <Box>
          <Text>│  </Text>
          <Text dimColor>(no log entries yet)</Text>
        </Box>
      ) : (
        tail.map((line, i) => {
          const time = formatTime(line.ts);
          const phaseColor = PHASE_COLORS[line.phase] ?? 'white';
          const text = truncate(line.text, maxTextLen);

          return (
            <Box key={i}>
              <Text>│  </Text>
              <Text dimColor>{time} </Text>
              <Text dimColor>{truncate(line.featureId, 10)}</Text>
              <Text>  </Text>
              <Text color={phaseColor}>[{line.phase}]</Text>
              <Text>  </Text>
              <Text>{text}</Text>
            </Box>
          );
        })
      )}
    </Box>
  );
}
