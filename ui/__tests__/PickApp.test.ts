import { applyPickTestKeys } from '../src/pick.js';
import type { PickBacklogItem } from '../src/types.js';

const items: PickBacklogItem[] = [
  { id: 'feat-001', title: 'Backlog list', priority: 5, effort: 3, status: 'ready', deps: [] },
  { id: 'feat-002', title: 'Feature preview', priority: 4, effort: 5, status: 'ready', deps: ['feat-001'] },
];

function captureStdout(run: () => number): { code: number; stdout: string } {
  let stdout = '';
  const originalWrite = process.stdout.write;
  process.stdout.write = ((chunk: string | Uint8Array) => {
    stdout += String(chunk);
    return true;
  }) as typeof process.stdout.write;

  try {
    return { code: run(), stdout };
  } finally {
    process.stdout.write = originalWrite;
  }
}

describe('applyPickTestKeys', () => {
  it('selects the focused item with space and submits ids with enter', () => {
    const result = captureStdout(() => applyPickTestKeys(items, 'space,enter'));
    expect(result).toEqual({ code: 0, stdout: 'feat-001\n' });
  });

  it('moves with j before selection', () => {
    const result = captureStdout(() => applyPickTestKeys(items, 'j,space,enter'));
    expect(result).toEqual({ code: 0, stdout: 'feat-002\n' });
  });

  it('cancels through q with code 130 and no stdout', () => {
    const result = captureStdout(() => applyPickTestKeys(items, 'q'));
    expect(result).toEqual({ code: 130, stdout: '' });
  });

  it('enters with no selection as empty successful output', () => {
    const result = captureStdout(() => applyPickTestKeys(items, 'enter'));
    expect(result).toEqual({ code: 0, stdout: '' });
  });
});

