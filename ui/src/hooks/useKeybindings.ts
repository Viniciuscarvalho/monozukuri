import { useInput } from 'ink';
import type { ViewMode } from '../types.js';

interface UseKeybindingsOptions {
  setView: (view: ViewMode) => void;
}

export function useKeybindings({ setView }: UseKeybindingsOptions): void {
  const orchestratorPid = process.env['MONOZUKURI_ORCHESTRATOR_PID']
    ? Number(process.env['MONOZUKURI_ORCHESTRATOR_PID'])
    : null;

  useInput((input, key) => {
    // q or Ctrl+C → send SIGINT to orchestrator and exit
    if (input === 'q' || key.ctrl && input === 'c') {
      if (orchestratorPid) {
        try {
          process.kill(orchestratorPid, 'SIGINT');
        } catch {
          // Process may already be gone
        }
      }
      process.exit(0);
    }

    // p → pause (SIGUSR1)
    if (input === 'p') {
      if (orchestratorPid) {
        try {
          process.kill(orchestratorPid, 'SIGUSR1');
        } catch {
          // Process may already be gone
        }
      }
      return;
    }

    // View navigation
    if (input === 'l') {
      setView('learnings');
      return;
    }
    if (input === 'f') {
      setView('filter');
      return;
    }
    if (input === '/') {
      setView('search');
      return;
    }
    if (input === '?') {
      setView('help');
      return;
    }
    if (key.escape) {
      setView('main');
      return;
    }
  });
}
