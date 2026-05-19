import { readdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';

const distRoot = new URL('../dist/', import.meta.url);

async function collectJavaScriptFiles(directoryUrl) {
  const entries = await readdir(directoryUrl, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const childUrl = new URL(entry.name, directoryUrl);
    if (entry.isDirectory()) {
      files.push(...await collectJavaScriptFiles(new URL(`${entry.name}/`, directoryUrl)));
    } else if (entry.isFile() && entry.name.endsWith('.js')) {
      files.push(childUrl);
    }
  }

  return files;
}

await import('../dist/index.js');

const compiledFiles = await collectJavaScriptFiles(distRoot);
for (const fileUrl of compiledFiles) {
  const source = await readFile(fileUrl, 'utf8');
  if (source.includes('Dynamic require of "assert"') || source.includes("Dynamic require of 'assert'")) {
    throw new Error(`Ink bundle regression: ${fileUrl.pathname} contains Dynamic require of assert`);
  }
}

