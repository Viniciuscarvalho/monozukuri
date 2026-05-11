import React from 'react';
import { Box, Text } from 'ink';
import { tokens } from '../tokens.js';

interface FooterProps {
  terminalWidth?: number;
}

// Day-5 plan: drop the footer to 3 primary keybindings + ? for the full
// help overlay. The overlay itself is out of scope for this PR — when it
// lands, `?` will pop a Box listing every key.
const PRIMARY_KEYS = ' q quit · p pause · ? help';

export function Footer({ terminalWidth = 70 }: FooterProps): React.ReactElement {
  const innerWidth = Math.max(PRIMARY_KEYS.length, terminalWidth - 2);
  const padded = PRIMARY_KEYS.padEnd(innerWidth);
  const bottomDashes = '─'.repeat(Math.max(0, terminalWidth - 2));

  return (
    <Box flexDirection="column">
      <Box>
        <Text dimColor>{'│'}</Text>
        <Text color={tokens.dim}>{padded}</Text>
        <Text dimColor>{'│'}</Text>
      </Box>
      <Box>
        <Text dimColor>{'└'}</Text>
        <Text dimColor>{bottomDashes}</Text>
        <Text dimColor>{'┘'}</Text>
      </Box>
    </Box>
  );
}
