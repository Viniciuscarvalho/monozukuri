#!/bin/bash
# scripts/skill-discovery.sh
# Scans the project + user's home for installed skills and builds
# .monozukuri/skills-manifest.json. Mirrors scripts/agent-discovery.sh.
#
# Scan locations (in order; first-seen wins for collisions):
#   <project>/.claude/skills/*/SKILL.md      (Claude Code, project-local)
#   <project>/.agents/skills/*/SKILL.md      (Cursor/Codex/Gemini, project-local)
#   ~/.claude/skills/*/SKILL.md              (Claude Code, user-global)
#   ~/.agents/skills/*/SKILL.md              (Cursor/Codex/Gemini, user-global)
#
# Each SKILL.md must have YAML frontmatter with at least `name`. Optional:
# `description`, `phase` (single or list — drives phase_to_skill lookup),
# `allowed-tools`, `agent` (claude-code / codex / gemini-cli / cursor / any).
#
# Output: { discovered_at, project_root, skills: [...] } where each skill is
# { name, description, path, phase, agent, source }.
#
# Override default global location with CLAUDE_CONFIG_DIR (Claude Code's
# convention) — same env var lib/agent/skill-detect.sh already respects.

set -euo pipefail

PROJECT_ROOT="${1:-$PWD}"
MANIFEST="${2:-$PROJECT_ROOT/.monozukuri/skills-manifest.json}"

CLAUDE_GLOBAL_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
AGENTS_GLOBAL_DIR="$HOME/.agents"

node -e "
const fs = require('fs');
const path = require('path');

const projectRoot = '$PROJECT_ROOT';
const manifestPath = '$MANIFEST';

const SCAN = [
  { dir: path.join(projectRoot, '.claude/skills'),         scope: 'project', agent: 'claude-code'  },
  { dir: path.join(projectRoot, '.agents/skills'),         scope: 'project', agent: 'any'          },
  { dir: '$CLAUDE_GLOBAL_DIR/skills',                      scope: 'global',  agent: 'claude-code'  },
  { dir: '$AGENTS_GLOBAL_DIR/skills',                      scope: 'global',  agent: 'any'          },
];

function extractFrontmatter(content) {
  if (!content.startsWith('---')) return null;
  const end = content.indexOf('---', 3);
  if (end === -1) return null;
  return content.substring(3, end).trim();
}

function parseFrontmatter(fm) {
  const result = {};
  let currentKey = null;
  let currentList = null;

  for (const line of fm.split('\n')) {
    const listMatch = line.match(/^\s+-\s+(.+)/);
    if (listMatch && currentKey) {
      if (!currentList) currentList = [];
      currentList.push(listMatch[1].trim());
      continue;
    }
    if (currentList && currentKey) {
      result[currentKey] = currentList;
      currentList = null;
    }
    const kvMatch = line.match(/^(\w[\w_-]*)\s*:\s*(.*)/);
    if (kvMatch) {
      currentKey = kvMatch[1];
      const val = kvMatch[2].trim();
      if (val && !val.startsWith('>')) {
        const inlineArr = val.match(/^\[(.+)\]$/);
        if (inlineArr) {
          result[currentKey] = inlineArr[1].split(',').map(s => s.trim().replace(/[\"']/g, ''));
        } else {
          result[currentKey] = val.replace(/^[\"']|[\"']$/g, '');
        }
        currentKey = null;
      }
    }
  }
  if (currentList && currentKey) result[currentKey] = currentList;
  return result;
}

const skills = [];
const seenNames = new Set();
let scanned = 0;

for (const src of SCAN) {
  if (!fs.existsSync(src.dir)) continue;
  let entries;
  try { entries = fs.readdirSync(src.dir, { withFileTypes: true }); }
  catch { continue; }
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const skillMd = path.join(src.dir, entry.name, 'SKILL.md');
    if (!fs.existsSync(skillMd)) continue;
    scanned++;

    const content = fs.readFileSync(skillMd, 'utf-8');
    const fmRaw = extractFrontmatter(content);
    if (!fmRaw) {
      console.log('  [skill-discovery] skipped (no frontmatter): ' + skillMd);
      continue;
    }
    const fm = parseFrontmatter(fmRaw);
    const name = fm.name || entry.name;

    if (seenNames.has(name)) {
      console.log('  [skill-discovery] collision: ' + name + ' already declared — skipping ' + skillMd);
      continue;
    }
    seenNames.add(name);

    const phaseRaw = fm.phase || fm.phases || '';
    const phaseList = Array.isArray(phaseRaw) ? phaseRaw :
                      (phaseRaw ? [phaseRaw] : []);

    const toolsRaw = fm['allowed-tools'] || fm.allowed_tools || '';
    const toolsList = Array.isArray(toolsRaw) ? toolsRaw :
                      (toolsRaw ? [toolsRaw] : []);

    skills.push({
      name,
      description: fm.description || '',
      path: src.scope === 'project' ? path.relative(projectRoot, skillMd) : skillMd,
      scope: src.scope,
      agent: fm.agent || src.agent,
      phase: phaseList.length > 0 ? phaseList.join(',') : '',
      phases: phaseList,
      allowed_tools: toolsList,
      source: src.scope + ':' + src.agent
    });
  }
}

const manifest = {
  discovered_at: new Date().toISOString(),
  project_root: projectRoot,
  skills
};

fs.mkdirSync(path.dirname(manifestPath), { recursive: true });
fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));

if (scanned === 0) {
  console.log('  [skill-discovery] No SKILL.md files found in project or global locations — empty manifest');
} else {
  console.log('  [skill-discovery] Found ' + skills.length + ' skill(s) (' + scanned + ' scanned) → ' + manifestPath);
  skills.forEach(s => console.log('    - ' + s.name + ' [' + (s.phase || 'no-phase') + '] (' + s.scope + '/' + s.agent + ')'));
}
"
