import React from 'react';
import { Box, Text } from 'ink';
import { PhaseTimeline } from './PhaseTimeline.js';
import type { Feature } from '../types.js';

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
      <Text dimColor>waiting for run...</Text>
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
          <Text color="yellow">⏸ </Text>
          <Text bold color="yellow">{feature.id}</Text>
          <Text>  </Text>
          <Text dimColor>{truncate(feature.title || feature.id, 42)}</Text>
          <Text> │</Text>
        </Box>
        <Box>
          <Text>│   </Text>
          <Text color="yellow">deferred: </Text>
          <Text>{truncate(reason, 50)}</Text>
          <Text> │</Text>
        </Box>
      </Box>
    );
  }

  const elapsed = formatElapsed(feature.startedAt, now);
  const tokens = formatTokens(feature.tokens);
  const estTokens = feature.estimatedTokens ? formatTokens(feature.estimatedTokens) : '~?';
  const title = truncate(feature.title || feature.id, 42);
  const spinnerText = spinner ? truncate(spinner, 50) : '';

  return (
    <Box flexDirection="column" paddingLeft={1}>
      {/* Feature header line */}
      <Box>
        <Text>│ </Text>
        <Text color="cyan">▸ </Text>
        <Text bold color="cyan">{feature.id}</Text>
        <Text>  </Text>
        <Text>{title}</Text>
        <Text dimColor>  elapsed: </Text>
        <Text color="yellow">{elapsed}</Text>
        <Text> │</Text>
      </Box>

      {/* Skill / memory subtitle */}
      {feature.currentSkill && (
        <Box>
          <Text>│   </Text>
          <Text dimColor>{'skill: '}</Text>
          <Text color={feature.compaction && feature.compaction !== 'none' ? 'yellow' : 'green'}>
            {feature.currentSkill}
          </Text>
          <Text dimColor>{' · tier '}</Text>
          <Text>{feature.currentTier ?? '—'}</Text>
          <Text dimColor>{' · mem: '}</Text>
          <Text color={feature.compaction && feature.compaction !== 'none' ? 'yellow' : 'green'}>
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
        <Text dimColor>tokens: </Text>
        <Text>{tokens}</Text>
        <Text dimColor> / {estTokens} est.</Text>
        {spinnerText ? (
          <>
            <Text dimColor>   </Text>
            <Text color="yellow">{spinnerText}</Text>
          </>
        ) : null}
        <Text> │</Text>
      </Box>
    </Box>
  );
}
