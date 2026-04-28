import React from 'react';
import { Box, Text } from 'ink';
import { CostMeter } from './CostMeter.js';
import type { AppState } from '../types.js';

interface HeaderProps {
  state: AppState;
  terminalWidth: number;
}

export function Header({ state, terminalWidth }: HeaderProps): React.ReactElement {
  const { runId, autonomy, model, agent, source, featureCount, budget, features, totals } = state;

  const completed = totals.succeeded + totals.failed + totals.skipped;
  const totalCost = totals.costUsd;

  // Build source label (e.g. "linear (team: FE)")
  const sourceLabel = source || 'unknown';

  // Width of inner content area (terminal minus 2 for borders)
  const innerWidth = Math.max(20, terminalWidth - 2);

  const runLabel = runId ? `run ${runId.slice(0, 8)}` : 'run —';
  const titleLeft = ' monozukuri ';
  const titleRight = ` ${runLabel} `;
  const dashes = '─'.repeat(Math.max(0, innerWidth - titleLeft.length - titleRight.length));

  return (
    <Box flexDirection="column">
      {/* Top border with title */}
      <Box>
        <Text>┌─</Text>
        <Text bold>{titleLeft}</Text>
        <Text dimColor>{dashes}</Text>
        <Text>{titleRight}</Text>
        <Text>──┐</Text>
      </Box>

      {/* Metadata row */}
      <Box paddingLeft={1} paddingRight={1}>
        <Text>│</Text>
        <Text> autonomy: </Text>
        <Text color="cyan">{autonomy || '—'}</Text>
        <Text>   model: </Text>
        <Text color="yellow">{model || '—'}</Text>
        <Text>   agent: </Text>
        <Text color="green">{agent || '—'}</Text>
        <Text>   source: </Text>
        <Text color="magenta">{sourceLabel}</Text>
        <Text> │</Text>
      </Box>

      {/* Progress bar row */}
      <Box paddingLeft={1}>
        <Text>│  </Text>
        <CostMeter
          completed={completed}
          total={featureCount || Object.keys(features).length}
          costUsd={totalCost}
          budget={budget}
          width={innerWidth}
        />
        <Text> │</Text>
      </Box>
    </Box>
  );
}
