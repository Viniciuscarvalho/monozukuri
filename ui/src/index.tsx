import React from 'react';
import { render } from 'ink';
import App from './App.js';

// Non-TTY passthrough: if stdout is not a terminal, bypass the UI entirely
// so raw JSONL can flow through unmodified.
if (!process.stdout.isTTY) {
  process.stdin.pipe(process.stdout);
} else {
  render(<App />);
}
