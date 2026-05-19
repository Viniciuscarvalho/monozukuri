import { jsx as _jsx } from "react/jsx-runtime";
import { render } from 'ink';
import { openSync } from 'node:fs';
import { ReadStream } from 'node:tty';
import App from './App.js';
import { registerCleanup } from './runtime.js';
// process.stdin is always a pipe (orchestrator JSONL), never a real TTY.
// Ink needs a TTY for raw-mode keyboard input, so we open /dev/tty directly.
// If /dev/tty is unavailable (CI, Docker, sub-shell invocation) or if
// setRawMode fails (e.g. running inside Claude Code's session), fall back to
// passthrough so the caller sees plain JSONL on stdout.
if (!process.stdout.isTTY) {
    process.stdin.pipe(process.stdout);
}
else {
    let ttyStdin;
    try {
        const fd = openSync('/dev/tty', 'r+');
        const stream = new ReadStream(fd);
        // Swallow EIO that fires during teardown when the controlling terminal fd
        // is closed by the parent before Node finishes draining the stream.
        stream.on('error', () => { });
        // Probe raw mode before handing to Ink — setRawMode throws EIO when the
        // controlling terminal is owned by a parent process (e.g. Claude Code).
        stream.setRawMode(true);
        stream.setRawMode(false);
        ttyStdin = stream;
    }
    catch {
        // /dev/tty not available or raw mode not supported
    }
    if (!ttyStdin) {
        process.stdin.pipe(process.stdout);
    }
    else {
        const inkInstance = render(_jsx(App, {}), { stdin: ttyStdin });
        const capturedStdin = ttyStdin;
        registerCleanup(() => {
            inkInstance.unmount();
            capturedStdin.destroy();
        });
    }
}
