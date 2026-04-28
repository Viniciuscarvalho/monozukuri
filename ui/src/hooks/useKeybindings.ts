import { useState } from 'react';
import { useInput } from 'ink';
import type { ViewMode } from '../types.js';

interface UseKeybindingsOptions {
  setView: (view: ViewMode) => void;
}

export function useKeybindings({ setView }: UseKeybindingsOptions): void {
  const orchestratorPid = process.env['MONOZUKURI_ORCHESTRATOR_PID']
    ? Number(process.env['MONOZUKURI_ORCHESTRATOR_PID'])
    : null;
  const [paused, setPaused] = useState(false);

  function sendSignal(sig: NodeJS.Signals) {
    if (orchestratorPid) {
      try { process.kill(orchestratorPid, sig); } catch { /* process gone */ }
    }
  }

  useInput((input, key) => {
    // q or Ctrl+C → send SIGINT to orchestrator and exit
    if (input === 'q' || key.ctrl && input === 'c') {
      sendSignal('SIGINT');
      process.exit(0);
    }

    // p → toggle pause (SIGUSR1) / resume (SIGUSR2)
    if (input === 'p') {
      if (paused) {
        sendSignal('SIGUSR2');
        setPaused(false);
      } else {
        sendSignal('SIGUSR1');
        setPaused(true);
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
