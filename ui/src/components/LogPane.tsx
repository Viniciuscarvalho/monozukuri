import React from 'react';
import { Box, Text } from 'ink';
import type { LogLine } from '../types.js';
import { tokens } from '../tokens.js';
import { LAYOUT } from '../lib/layout.js';

const PHASE_LOG_COLOR: Record<string, string> = {
  prd:      tokens.info,
  techspec: tokens.warning,
  tasks:    tokens.brand,
  code:     tokens.success,
  tests:    tokens.danger,
  pr:       '#a78bfa',
};

interface LogPaneProps {
  log: LogLine[];
  innerWidth: number;
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

export function LogPane({ log, innerWidth }: LogPaneProps): React.ReactElement {
  const tail = log.slice(-12);
  const maxTextLen = Math.max(20, innerWidth - LAYOUT.logChromeCols);

  return (
    <Box flexDirection="column">
      {tail.length === 0 ? (
        <Box paddingLeft={2}>
          <Text dimColor>(no log entries yet)</Text>
        </Box>
      ) : (
        tail.map((line, i) => {
          const time = formatTime(line.ts);
          const phaseColor = PHASE_LOG_COLOR[line.phase] ?? tokens.muted;
          const text = truncate(line.text, maxTextLen);

          return (
            <Box key={i} paddingLeft={2}>
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
