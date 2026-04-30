#!/bin/bash
# scripts/agent-discovery.sh
# Scans the project for agents and builds agents-manifest.json
#
# Scan locations (in order, following symlinks):
#   .claude/agents/*.md
#   .claude/agents/**/*.md
#
# Each file must have YAML frontmatter with at least `name` and `description`.
# Optional: `capabilities` list and `phase` mapping.

set -euo pipefail

PROJECT_ROOT="${1:-$PWD}"
MANIFEST="${2:-$PROJECT_ROOT/.monozukuri/agents-manifest.json}"

AGENT_DIR="$PROJECT_ROOT/.claude/agents"
AGENTS_MD="$PROJECT_ROOT/AGENTS.md"

# Use node for reliable YAML frontmatter parsing
node -e "
const fs = require('fs');
const path = require('path');

const projectRoot = '$PROJECT_ROOT';
const agentDir = '$AGENT_DIR';
const agentsMdPath = '$AGENTS_MD';
const manifestPath = '$MANIFEST';

// Recursively find all .md files
function findMdFiles(dir) {
  const results = [];
  if (!fs.existsSync(dir)) return results;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...findMdFiles(full));
    } else if (entry.name.endsWith('.md')) {
      results.push(full);
    }
  }
  return results;
}

// Extract YAML frontmatter between --- markers
function extractFrontmatter(content) {
  if (!content.startsWith('---')) return null;
  const end = content.indexOf('---', 3);
  if (end === -1) return null;
  return content.substring(3, end).trim();
}

// Parse simple YAML key-value pairs and lists
function parseFrontmatter(fm) {
  const result = {};
  let currentKey = null;
  let currentList = null;

  for (const line of fm.split('\n')) {
    // List item under current key
    const listMatch = line.match(/^\s+-\s+(.+)/);
    if (listMatch && currentKey) {
      if (!currentList) currentList = [];
      currentList.push(listMatch[1].trim());
      continue;
    }

    // Flush previous list
    if (currentList && currentKey) {
      result[currentKey] = currentList;
      currentList = null;
    }

    // Key: value pair
    const kvMatch = line.match(/^(\w[\w_-]*)\s*:\s*(.*)/);
    if (kvMatch) {
      currentKey = kvMatch[1];
      const val = kvMatch[2].trim();
      if (val && !val.startsWith('>')) {
        // Check for inline array [a, b, c]
        const inlineArr = val.match(/^\[(.+)\]$/);
        if (inlineArr) {
          result[currentKey] = inlineArr[1].split(',').map(s => s.trim().replace(/[\"']/g, ''));
        } else {
          result[currentKey] = val.replace(/^[\"']|[\"']$/g, '');
        }
        currentKey = null;
      }
      // If val is empty or >, expect list items next
    }
  }

  // Flush final list
  if (currentList && currentKey) {
    result[currentKey] = currentList;
  }

  return result;
}

// Slug: lower-case, spaces to hyphens, strip non-word chars
function slugify(s) {
  return s.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]/g, '');
}

// Parse AGENTS.md: strip generated block, split on ## headings,
// extract optional YAML frontmatter from each section body.
function parseAgentsMd(mdPath) {
  if (!fs.existsSync(mdPath)) return [];
  let content = fs.readFileSync(mdPath, 'utf-8');

  // Remove monozukuri-generated block
  content = content.replace(
    /<!--\s*monozukuri:generated-start[^>]*-->[\s\S]*?<!--\s*monozukuri:generated-end\s*-->/g,
    ''
  );

  const results = [];
  // Split on level-2 headings (## Name)
  const sections = content.split(/^##\s+/m).slice(1);
  for (const section of sections) {
    const lines = section.split('\n');
    const rawName = lines[0].trim();
    if (!rawName) continue;
    const body = lines.slice(1).join('\n').trim();

    let fm = {};
    let prompt = body;
    if (body.startsWith('---')) {
      const fmRaw = extractFrontmatter(body);
      if (fmRaw) {
        fm = parseFrontmatter(fmRaw);
        // Body after frontmatter block
        const fmEnd = body.indexOf('---', 3);
        prompt = body.substring(fmEnd + 3).trim();
      }
    }

    results.push({
      name: fm.name || slugify(rawName),
      description: fm.description || rawName,
      path: 'AGENTS.md#' + slugify(rawName),
      capabilities: Array.isArray(fm.phases) ? fm.phases :
                    (fm.phases ? [fm.phases] : []),
      phase: Array.isArray(fm.phases) ? fm.phases.join(',') : (fm.phases || 'any'),
      model: fm.model || '',
      stack: fm.stack || '',
      source: 'agents-md',
      prompt: prompt.substring(0, 500)
    });
  }
  return results;
}

const agents = [];
const seenNames = new Set();

// Primary source: .claude/agents/*.md files
const files = findMdFiles(agentDir);
for (const file of files) {
  const content = fs.readFileSync(file, 'utf-8');
  const fmRaw = extractFrontmatter(content);
  if (!fmRaw) continue;

  const fm = parseFrontmatter(fmRaw);
  if (!fm.name) continue;

  const relPath = path.relative(projectRoot, file);
  seenNames.add(fm.name);
  agents.push({
    name: fm.name,
    description: fm.description || '',
    path: relPath,
    capabilities: Array.isArray(fm.capabilities) ? fm.capabilities : [],
    phase: fm.phase || 'any',
    source: 'agents-dir'
  });
}

// Secondary source: AGENTS.md (## sections, outside generated markers)
const mdAgents = parseAgentsMd(agentsMdPath);
for (const a of mdAgents) {
  if (seenNames.has(a.name)) {
    console.log('  [discovery] collision: ' + a.name + ' already declared in .claude/agents/ — skipping AGENTS.md entry');
    continue;
  }
  seenNames.add(a.name);
  agents.push(a);
}

const hasAgentsDir = fs.existsSync(agentDir);
const hasAgentsMd = fs.existsSync(agentsMdPath);
if (!hasAgentsDir && !hasAgentsMd) {
  console.log('  [discovery] No agents directory found at ' + agentDir + ' and no AGENTS.md — empty manifest');
} else if (!hasAgentsDir) {
  console.log('  [discovery] No agents directory at ' + agentDir + ' — using AGENTS.md only');
}

const manifest = {
  discovered_at: new Date().toISOString(),
  project_root: projectRoot,
  agents
};

fs.mkdirSync(path.dirname(manifestPath), { recursive: true });
fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
console.log('  [discovery] Found ' + agents.length + ' agents → ' + manifestPath);
agents.forEach(a => console.log('    - ' + a.name + ' [' + a.phase + '] (' + (a.capabilities || []).join(', ') + ') [' + (a.source || '') + ']'));
"
