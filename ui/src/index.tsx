import React from 'react';
import { render } from 'ink';
import { openSync } from 'node:fs';
import { ReadStream } from 'node:tty';
import App from './App.js';

// process.stdin is always a pipe (orchestrator JSONL), never a real TTY.
// Ink needs a TTY for raw-mode keyboard input, so we open /dev/tty directly.
// If /dev/tty is unavailable (CI, Docker, piped invocation), fall back to
// passthrough so the caller sees plain JSONL on stdout.
if (!process.stdout.isTTY) {
  process.stdin.pipe(process.stdout);
} else {
  let ttyStdin: ReadStream | undefined;
  try {
    const fd = openSync('/dev/tty', 'r+');
    ttyStdin = new ReadStream(fd);
  } catch {
    // /dev/tty not available
  }

  if (!ttyStdin) {
    process.stdin.pipe(process.stdout);
  } else {
    render(<App />, { stdin: ttyStdin });
  }
}
