import React from 'react';
import { render } from 'ink';
import { openSync } from 'node:fs';
import { ReadStream } from 'node:tty';
import App from './App.js';

// process.stdin is always a pipe (orchestrator JSONL), never a real TTY.
// Ink needs a TTY for raw-mode keyboard input, so we open /dev/tty directly.
// If /dev/tty is unavailable (CI, Docker, sub-shell invocation) or if
// setRawMode fails (e.g. running inside Claude Code's session), fall back to
// passthrough so the caller sees plain JSONL on stdout.
if (!process.stdout.isTTY) {
  process.stdin.pipe(process.stdout);
} else {
  let ttyStdin: ReadStream | undefined;
  try {
    const fd = openSync('/dev/tty', 'r+');
    const stream = new ReadStream(fd);
    // Probe raw mode before handing to Ink — setRawMode throws EIO when the
    // controlling terminal is owned by a parent process (e.g. Claude Code).
    stream.setRawMode(true);
    stream.setRawMode(false);
    ttyStdin = stream;
  } catch {
    // /dev/tty not available or raw mode not supported
  }

  if (!ttyStdin) {
    process.stdin.pipe(process.stdout);
  } else {
    render(<App />, { stdin: ttyStdin });
  }
}
