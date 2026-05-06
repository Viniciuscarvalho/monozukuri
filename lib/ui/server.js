'use strict';
// lib/ui/server.js — Local HTTP server for the monozukuri web dashboard.
// Usage: node server.js <events_jsonl_path> <run_id>
// Binds to 127.0.0.1:<random-port>, opens browser, serves:
//   GET /          → ui-web/index.html (static)
//   GET /events    → SSE stream tailing <events_jsonl_path>
//   GET /run-id    → JSON { runId, eventsFile }

const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const { execSync } = require('node:child_process');

const eventsFile = process.argv[2];
const runId = process.argv[3] || 'unknown';
const bindPort = parseInt(process.argv[4] || '0', 10);

if (!eventsFile) {
  console.error('usage: node server.js <events_jsonl_path> <run_id> [port]');
  process.exit(1);
}
// Touch the file if it doesn't exist yet (bin/monozukuri creates the dir but
// the orchestrator may not have emitted any events at server startup time).
if (!fs.existsSync(eventsFile)) fs.writeFileSync(eventsFile, '');

const UI_WEB_DIR = path.resolve(__dirname, '..', '..', 'ui-web');
const MIME = { '.html': 'text/html', '.js': 'application/javascript', '.css': 'text/css' };

function serveStatic(res, filePath) {
  const abs = path.resolve(UI_WEB_DIR, filePath);
  if (!abs.startsWith(UI_WEB_DIR)) { res.writeHead(403); res.end(); return; }
  if (!fs.existsSync(abs)) { res.writeHead(404); res.end('Not found'); return; }
  const ext = path.extname(abs);
  res.writeHead(200, { 'Content-Type': MIME[ext] || 'application/octet-stream' });
  fs.createReadStream(abs).pipe(res);
}

const clients = new Set();

function broadcastLine(line) {
  if (!line.trim()) return;
  for (const res of clients) {
    try { res.write(`data: ${line}\n\n`); } catch (_) { clients.delete(res); }
  }
}

// Tail the events file: send existing lines then watch for new content
function startTail(res) {
  const lines = fs.readFileSync(eventsFile, 'utf8').split('\n');
  for (const line of lines) if (line.trim()) res.write(`data: ${line}\n\n`);

  const watcher = fs.watch(eventsFile, { persistent: false }, () => {
    // Re-read only the new content using the current position stored on the watcher
    try {
      const stat = fs.statSync(eventsFile);
      if (stat.size <= (watcher._lastSize || 0)) return;
      const stream = fs.createReadStream(eventsFile, { start: watcher._lastSize || 0 });
      let buf = '';
      stream.on('data', (chunk) => {
        buf += chunk.toString();
        const parts = buf.split('\n');
        buf = parts.pop();
        for (const p of parts) broadcastLine(p);
      });
      watcher._lastSize = stat.size;
    } catch (_) {}
  });
  watcher._lastSize = fs.statSync(eventsFile).size;

  res.on('close', () => { watcher.close(); clients.delete(res); });
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, 'http://localhost');

  if (url.pathname === '/events') {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*',
    });
    res.write(':ok\n\n');
    clients.add(res);
    startTail(res);
    return;
  }

  if (url.pathname === '/run-id') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ runId, eventsFile }));
    return;
  }

  const file = url.pathname === '/' ? 'index.html' : url.pathname.slice(1);
  serveStatic(res, file);
});

server.listen(bindPort, '127.0.0.1', () => {
  const { port } = server.address();
  const dashboardUrl = `http://127.0.0.1:${port}`;
  console.log(`  Dashboard: ${dashboardUrl}`);
  console.log(`  Run ID:    ${runId}`);
  console.log(`  Events:    ${eventsFile}`);
  console.log(`  Press Ctrl-C to stop.\n`);

  // Open browser (best-effort, non-blocking)
  try {
    const open = process.platform === 'darwin' ? 'open' : process.platform === 'win32' ? 'start' : 'xdg-open';
    execSync(`${open} "${dashboardUrl}"`, { stdio: 'ignore' });
  } catch (_) {}
});

process.on('SIGINT', () => { server.close(); process.exit(0); });
