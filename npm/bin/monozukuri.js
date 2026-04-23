#!/usr/bin/env node
const { execSync } = require('child_process');
const path = require('path');
const monozukuriHome = path.join(__dirname, '..', '..', 'scripts');
const args = process.argv.slice(2).join(' ');
try {
  execSync(`bash "${monozukuriHome}/orchestrate.sh" ${args}`, {
    stdio: 'inherit',
    cwd: process.cwd(),
    env: { ...process.env, MONOZUKURI_HOME: monozukuriHome }
  });
} catch (e) {
  process.exit(e.status || 1);
}
