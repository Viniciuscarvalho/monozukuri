import React from 'react';
import { render } from 'ink';
import { createReadStream } from 'node:fs';
import App from './App.js';

// Non-TTY passthrough: if stdout is not a terminal, bypass the UI entirely
// so raw JSONL can flow through unmodified.
if (!process.stdout.isTTY) {
  process.stdin.pipe(process.stdout);
} else if (!process.stdin.isTTY) {
  // stdin is a pipe (JSONL from the orchestrator) but stdout is a TTY.
  // Open /dev/tty directly so Ink can call setRawMode for keyboard input
  // while process.stdin carries the event stream from the orchestrator.
  const ttyStdin = createReadStream('/dev/tty');
  render(<App />, { stdin: ttyStdin as unknown as NodeJS.ReadStream });
} else {
  render(<App />);
}
