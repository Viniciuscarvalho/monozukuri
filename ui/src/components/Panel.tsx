import React from 'react';
import { Box, Text } from 'ink';
import { tokens } from '../tokens.js';

interface PanelProps {
  title?: string;
  width?: number;
  children: React.ReactNode;
}

export function Panel({ title, width, children }: PanelProps): React.ReactElement {
  const effectiveWidth = width || 60;
  const sepLen = title ? Math.max(1, effectiveWidth - title.length - 3) : Math.max(1, effectiveWidth - 2);
  const sep = '─'.repeat(sepLen);
  return (
    <Box flexDirection="column" borderStyle="round" borderColor={tokens.border} width={width} paddingX={1}>
      {title && (
        <Box marginBottom={0}>
          <Text bold color={tokens.brand}>{title}</Text>
          <Text color={tokens.dim}> {sep}</Text>
        </Box>
      )}
      {children}
    </Box>
  );
}
