#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');

const root = process.argv[2] ? path.resolve(process.argv[2]) : process.cwd();
const pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
const distDir = path.join(root, 'ui', 'dist');
const externalImports = new Set();

function packageName(specifier) {
  if (specifier.startsWith('node:') || specifier.startsWith('.') || specifier.startsWith('/')) {
    return null;
  }
  if (specifier.startsWith('@')) {
    const [scope, name] = specifier.split('/');
    return scope && name ? `${scope}/${name}` : specifier;
  }
  return specifier.split('/')[0];
}

function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(fullPath);
      continue;
    }
    if (!entry.name.endsWith('.js')) continue;

    const source = fs.readFileSync(fullPath, 'utf8');
    const importRe = /\bimport\s+(?:[^'"]+\s+from\s+)?['"]([^'"]+)['"]/g;
    let match;
    while ((match = importRe.exec(source)) !== null) {
      const name = packageName(match[1]);
      if (name) externalImports.add(name);
    }
  }
}

walk(distDir);

const declared = new Set([
  ...Object.keys(pkg.dependencies || {}),
  ...Object.keys(pkg.optionalDependencies || {}),
]);
const missing = [...externalImports].filter((name) => !declared.has(name)).sort();

if (missing.length > 0) {
  console.error(`missing dependencies for ui/dist imports: ${missing.join(', ')}`);
  process.exit(1);
}
