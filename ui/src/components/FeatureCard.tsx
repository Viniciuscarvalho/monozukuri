import React from 'react';
import { Box, Text } from 'ink';
import { PhaseTimeline } from './PhaseTimeline.js';
import type { Feature } from '../types.js';
import { tokens } from '../tokens.js';

interface FeatureCardProps {
  feature: Feature | null;
  spinner: string;
  now: Date;
}

function formatElapsed(startedAt: string | undefined, now: Date): string {
  if (!startedAt) return '—';
  const start = new Date(startedAt).getTime();
  const elapsed = Math.max(0, Math.floor((now.getTime() - start) / 1000));
  const m = Math.floor(elapsed / 60);
  const s = elapsed % 60;
  return m > 0 ? `${m}m ${s}s` : `${s}s`;
}

function formatTokens(tokens: number | undefined): string {
  if (tokens === undefined) return '—';
  if (tokens >= 1000) return `${Math.round(tokens / 1000)}k`;
  return String(tokens);
}

function truncate(str: string, maxLen: number): string {
  if (str.length <= maxLen) return str;
  return str.slice(0, maxLen - 1) + '…';
}

interface WaitingCardProps {
  // Empty state
}

function WaitingCard(_props: WaitingCardProps): React.ReactElement {
  return (
    <Box flexDirection="column" paddingLeft={2} paddingY={1}>
      <Text color={tokens.dim}>waiting for run...</Text>
    </Box>
  );
}

export function FeatureCard({ feature, spinner, now }: FeatureCardProps): React.ReactElement {
  if (!feature) {
    return <WaitingCard />;
  }

  if (feature.status === 'deferred') {
    const reason = feature.error ?? 'no reason given';
    return (
      <Box flexDirection="column" paddingLeft={1}>
        <Box>
          <Text>│ </Text>
          <Text color={tokens.warning}>⏸ </Text>
          <Text bold color={tokens.warning}>{feature.id}</Text>
          <Text>  </Text>
          <Text color={tokens.dim}>{truncate(feature.title || feature.id, 42)}</Text>
          <Text> │</Text>
        </Box>
        <Box>
          <Text>│   </Text>
          <Text color={tokens.warning}>deferred: </Text>
          <Text>{truncate(reason, 50)}</Text>
          <Text> │</Text>
        </Box>
      </Box>
    );
  }

  const elapsed = formatElapsed(feature.startedAt, now);
  const tokenCount = formatTokens(feature.tokens);
  const estTokens = feature.estimatedTokens ? formatTokens(feature.estimatedTokens) : '~?';
  const title = truncate(feature.title || feature.id, 42);
  const spinnerText = spinner ? truncate(spinner, 50) : '';

  return (
    <Box flexDirection="column" paddingLeft={1}>
      {/* Feature header line */}
      <Box>
        <Text>│ </Text>
        <Text color={tokens.brand}>▸ </Text>
        <Text bold color={tokens.brand}>{feature.id}</Text>
        <Text>  </Text>
        <Text>{title}</Text>
        <Text color={tokens.dim}>  elapsed: </Text>
        <Text color={tokens.warning}>{elapsed}</Text>
        <Text> │</Text>
      </Box>

      {/* Skill / memory subtitle */}
      {feature.currentSkill && (
        <Box>
          <Text>│   </Text>
          <Text color={tokens.dim}>{'skill: '}</Text>
          <Text color={feature.compaction && feature.compaction !== 'none' ? tokens.warning : tokens.success}>
            {feature.currentSkill}
          </Text>
          <Text color={tokens.dim}>{' · tier '}</Text>
          <Text>{feature.currentTier ?? '—'}</Text>
          <Text color={tokens.dim}>{' · mem: '}</Text>
          <Text color={feature.compaction && feature.compaction !== 'none' ? tokens.warning : tokens.success}>
            {feature.compaction && feature.compaction !== 'none'
              ? `compaction:${feature.compaction}`
              : 'ok'}
          </Text>
          <Text> │</Text>
        </Box>
      )}

      {/* Phase timeline */}
      <Box>
        <Text>│   </Text>
        <PhaseTimeline phases={feature.phases} />
        <Text> │</Text>
      </Box>

      {/* Tokens + spinner */}
      <Box>
        <Text>│   </Text>
        <Text color={tokens.dim}>tokens: </Text>
        <Text>{tokenCount}</Text>
        <Text color={tokens.dim}> / {estTokens} est.</Text>
        {spinnerText ? (
          <>
            <Text color={tokens.dim}>   </Text>
            <Text color={tokens.warning}>{spinnerText}</Text>
          </>
        ) : null}
        <Text> │</Text>
      </Box>
    </Box>
  );
}
