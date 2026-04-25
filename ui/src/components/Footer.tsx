import React from 'react';
import { Box, Text } from 'ink';

interface FooterProps {
  terminalWidth?: number;
}

export function Footer({ terminalWidth = 70 }: FooterProps): React.ReactElement {
  const keysLine = '  q quit  p pause  l learnings  f filter  / search  ?  help';
  // Pad the inner content to fill the border width
  const innerWidth = Math.max(keysLine.length, terminalWidth - 2);
  const padded = keysLine.padEnd(innerWidth);
  const bottomDashes = '─'.repeat(terminalWidth - 2);

  return (
    <Box flexDirection="column">
      <Box>
        <Text dimColor>{'│'}</Text>
        <Text dimColor>{padded}</Text>
        <Text dimColor>{'│'}</Text>
      </Box>
      <Box>
        <Text>{'└'}</Text>
        <Text dimColor>{bottomDashes}</Text>
        <Text>{'┘'}</Text>
      </Box>
    </Box>
  );
}
