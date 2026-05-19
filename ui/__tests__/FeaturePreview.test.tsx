import React from 'react';
import { render } from 'ink-testing-library';
import { FeaturePreview, renderMarkdownPreview } from '../src/components/FeaturePreview.js';
import type { PickBacklogItem } from '../src/types.js';

const item: PickBacklogItem = {
  id: 'feat-010',
  title: 'Pick backlog items interactively',
  description: [
    '## Why',
    'Use **ranked backlog** data from `monozukuri pick`.',
    '- Keep stdout clean for [scripts](https://example.com).',
  ].join('\n'),
  priority: 5,
  effort: 8,
  status: 'ready',
  score: 82,
  deps: ['feat-001', 'feat-004'],
};

describe('renderMarkdownPreview', () => {
  it('normalizes markdown into terminal-friendly lines', () => {
    expect(renderMarkdownPreview(item.description)).toEqual([
      'Why',
      'Use ranked backlog data from monozukuri pick.',
      '• Keep stdout clean for scripts.',
    ]);
  });

  it('returns a fallback for missing descriptions', () => {
    expect(renderMarkdownPreview(undefined)).toEqual(['No description provided.']);
  });
});

describe('FeaturePreview', () => {
  it('renders title, metadata, markdown description, and deps', () => {
    const { lastFrame } = render(<FeaturePreview item={item} innerWidth={64} />);
    const frame = lastFrame() ?? '';

    expect(frame).toContain('Pick backlog items interactively');
    expect(frame).toContain('feat-010');
    expect(frame).toContain('ready');
    expect(frame).toContain('Use ranked backlog data from monozukuri pick.');
    expect(frame).toContain('feat-001');
    expect(frame).toContain('feat-004');
  });

  it('renders fallbacks for no selection and no deps', () => {
    const noSelection = render(<FeaturePreview item={null} />);
    expect(noSelection.lastFrame() ?? '').toContain('No feature selected.');

    const noDeps = render(<FeaturePreview item={{ ...item, deps: [], description: undefined }} />);
    const frame = noDeps.lastFrame() ?? '';
    expect(frame).toContain('No description provided.');
    expect(frame).toContain('none');
  });

  it('truncates long title and description lines', () => {
    const { lastFrame } = render(
      <FeaturePreview
        item={{
          ...item,
          title: 'A very long feature title that should be truncated by the preview panel',
          description: 'A very long markdown description line that should also be truncated by the preview panel',
        }}
        innerWidth={36}
      />
    );

    expect(lastFrame() ?? '').toContain('…');
  });
});

