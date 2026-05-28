#!/bin/bash
# cmd/doctor.sh — Pre-flight dependency checks for Monozukuri
# Contains sub_doctor(); sourced by orchestrate.sh and dispatched.

set -euo pipefail

_doctor_pass() { printf "  %s✓%s %s\n" "${T_SUCCESS:-\033[0;32m}" "${T_RESET:-\033[0m}" "$1"; }
_doctor_fail() {
  printf "  %s✗%s %s\n    → %s\n" "${T_DANGER:-\033[0;31m}" "${T_RESET:-\033[0m}" "$1" "$2" >&2
}

_doctor_config_path() {
  if [ -n "${OPT_CONFIG:-}" ] && [ -f "${OPT_CONFIG}" ]; then
    printf '%s\n' "${OPT_CONFIG}"
  elif [ -f ".monozukuri/config.yaml" ]; then
    printf '%s\n' ".monozukuri/config.yaml"
  elif [ -f ".monozukuri/config.yml" ]; then
    printf '%s\n' ".monozukuri/config.yml"
  fi
}

_doctor_configured_agent() {
  if [ -n "${MONOZUKURI_AGENT:-}" ]; then
    printf '%s\n' "$MONOZUKURI_AGENT"
    return
  fi

  local cfg
  cfg="$(_doctor_config_path)"
  if [ -z "$cfg" ]; then
    return 0
  fi

  local agent
  agent="$(awk -F: '
    /^[[:space:]]*agent[[:space:]]*:/ {
      value=$2
      sub(/#.*/, "", value)
      gsub(/^[[:space:]"'\''"]+|[[:space:]"'\''"]+$/, "", value)
      print value
      exit
    }
  ' "$cfg" | xargs 2>/dev/null || true)"
  printf '%s\n' "${agent:-claude-code}"
}

_doctor_setup_agent_id() {
  case "$1" in
    gemini) echo "gemini-cli" ;;
    *)      echo "$1" ;;
  esac
}

_doctor_agent_display_name() {
  local setup_id
  setup_id="$(_doctor_setup_agent_id "$1")"
  if declare -f setup_agent_name &>/dev/null; then
    setup_agent_name "$setup_id"
  else
    case "$1" in
      claude-code) echo "Claude Code" ;;
      codex)       echo "OpenAI Codex CLI" ;;
      gemini)      echo "Google Gemini CLI" ;;
      kiro)        echo "Kiro" ;;
      aider)       echo "Aider" ;;
      *)           echo "$1" ;;
    esac
  fi
}

_doctor_agent_cli_bin() {
  case "$1" in
    claude-code) echo "claude" ;;
    codex)       echo "codex" ;;
    gemini)      echo "gemini" ;;
    kiro)        echo "kiro" ;;
    aider)       echo "aider" ;;
    *)           echo "$1" ;;
  esac
}

_doctor_agent_supports_native_skills() {
  case "$1" in
    claude-code) return 0 ;;
    *)           return 1 ;;
  esac
}

_doctor_check_active_agent() {
  local agent="$1"
  local adapter="${LIB_DIR}/agent/adapter-${agent}.sh"
  local bin
  bin="$(_doctor_agent_cli_bin "$agent")"
  if [ ! -f "$adapter" ]; then
    _doctor_fail "$agent adapter not found" "Choose one of: claude-code, codex, gemini, kiro, aider"
    return 1
  fi
  if command -v "$bin" >/dev/null 2>&1; then
    _doctor_pass "${agent} CLI installed"
  else
    _doctor_fail "${agent} CLI missing" "Install ${bin}; hint: source ${adapter} && agent_login_hint"
    return 1
  fi

  (
    # shellcheck source=/dev/null
    source "$adapter"
    agent_doctor >/dev/null 2>&1
  )
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    _doctor_pass "${agent} auth OK"
    _doctor_pass "loop live validable: ${agent} ready"
  else
    _doctor_fail "${agent} auth not OK" "Authenticate ${bin}; hint: source ${adapter} && agent_login_hint"
    return 1
  fi
}

_doctor_project_readiness_json() {
  local active_agent="${1:-}"
  node - "${ROOT_DIR:-$PWD}" "${LIB_DIR:-}" "$active_agent" <<'NODE'
const fs = require('fs');
const path = require('path');
const cp = require('child_process');

const root = process.argv[2] || process.cwd();
const libDir = process.argv[3] || path.join(root, 'lib');
const activeAgentArg = process.argv[4] || '';
const phases = ['prd', 'techspec', 'tasks', 'code', 'tests', 'pr'];
const defaultPhaseSkills = {
  prd: 'mz-create-prd',
  techspec: 'mz-create-techspec',
  tasks: 'mz-create-tasks',
  code: 'mz-execute-task',
  tests: 'mz-run-tests',
  pr: 'mz-open-pr'
};
const capabilities = {
  'claude-code': { skills: true, skill_injection: false, native_context: ['AGENTS.md', 'CLAUDE.md'] },
  codex: { skills: false, skill_injection: true, native_context: ['AGENTS.md'] },
  gemini: { skills: false, skill_injection: true, native_context: ['AGENTS.md', 'GEMINI.md'] },
  aider: { skills: false, skill_injection: false, native_context: ['AGENTS.md', 'CONVENTIONS.md'] },
  kiro: { skills: false, skill_injection: false, native_context: ['AGENTS.md'] }
};
const cliBins = {
  'claude-code': 'claude',
  codex: 'codex',
  gemini: 'gemini',
  aider: 'aider',
  kiro: 'kiro'
};

const checks = [];
const fixes = [];
const fixKeys = new Set();

function rel(p) {
  if (!p) return '';
  const r = path.relative(root, p);
  return r && !r.startsWith('..') ? r : p;
}

function exists(p) {
  try { return fs.existsSync(p); } catch (_) { return false; }
}

function read(p) {
  try { return fs.readFileSync(p, 'utf8'); } catch (_) { return ''; }
}

function strip(value) {
  return String(value || '').trim().replace(/^['"]|['"]$/g, '');
}

function addCheck(id, status, summary, evidence = {}, fix = '') {
  checks.push({ id, status, summary, evidence, ...(fix ? { fix } : {}) });
  if (status !== 'pass' && fix) addFix(status === 'fail' ? 'blocker' : 'warning', id, fix);
}

function addFix(severity, target, action) {
  const key = `${severity}|${target}|${action}`;
  if (fixKeys.has(key)) return;
  fixKeys.add(key);
  fixes.push({ severity, target, action });
}

function parseConfigFlat(configPath) {
  const flat = {};
  if (!configPath || !exists(configPath)) return flat;
  const content = read(configPath);
  let section = '';
  let subsection = '';
  let sub2section = '';
  const norm = (key) => key.replace(/-/g, '_').toUpperCase();
  for (const line of content.split('\n')) {
    if (/^\s*(#|$)/.test(line)) continue;
    const indent = (line.match(/^(\s*)/) || ['',''])[1].length;
    const m = line.match(/^\s*([\w][\w_-]*)\s*:\s*(.*)$/);
    if (!m) continue;
    const key = m[1];
    const val = strip(m[2].replace(/\s+#.*$/, ''));
    if (indent === 0) {
      subsection = '';
      sub2section = '';
      if (val && val !== '[]' && val !== '{}') {
        section = '';
        flat[`CFG_${norm(key)}`] = val;
      } else {
        section = key;
      }
    } else if (indent >= 2 && indent <= 3 && section) {
      sub2section = '';
      if (val && val !== '[]' && val !== '{}') {
        subsection = '';
        flat[`CFG_${norm(section)}_${norm(key)}`] = val;
      } else {
        subsection = key;
      }
    } else if (indent >= 4 && indent <= 5 && section && subsection) {
      if (val && val !== '[]' && val !== '{}') {
        sub2section = '';
        flat[`CFG_${norm(section)}_${norm(subsection)}_${norm(key)}`] = val;
      } else {
        sub2section = key;
      }
    } else if (indent >= 6 && section && subsection && sub2section) {
      flat[`CFG_${norm(section)}_${norm(subsection)}_${norm(sub2section)}_${norm(key)}`] = val;
    }
  }
  return flat;
}

function findConfig() {
  for (const p of ['.monozukuri/config.yaml', '.monozukuri/config.yml']) {
    const abs = path.join(root, p);
    if (exists(abs)) return abs;
  }
  return '';
}

function commandOk(command, timeout = 3000) {
  const result = cp.spawnSync('bash', ['-lc', command], { cwd: root, timeout, stdio: 'ignore' });
  return result.status === 0;
}

function detectStack() {
  const stack = [];
  if (exists(path.join(root, 'package.json'))) stack.push('nodejs');
  if (exists(path.join(root, 'Cargo.toml'))) stack.push('rust');
  if (exists(path.join(root, 'go.mod'))) stack.push('go');
  if (exists(path.join(root, 'pyproject.toml')) || exists(path.join(root, 'requirements.txt')) || exists(path.join(root, 'setup.py'))) stack.push('python');
  if (exists(path.join(root, 'Package.swift')) || fs.readdirSync(root, { withFileTypes: true }).some((d) => d.name.endsWith('.xcodeproj') || d.name.endsWith('.xcworkspace'))) stack.push('ios');
  return stack;
}

function detectPackageManager() {
  const candidates = [
    ['pnpm', 'pnpm-lock.yaml'],
    ['yarn', 'yarn.lock'],
    ['bun', 'bun.lockb'],
    ['npm', 'package-lock.json'],
    ['cargo', 'Cargo.lock'],
    ['go', 'go.mod'],
    ['spm', 'Package.swift'],
    ['poetry', 'poetry.lock'],
    ['pip', 'requirements.txt']
  ];
  for (const [name, file] of candidates) {
    if (exists(path.join(root, file))) return { name, evidence: file };
  }
  if (exists(path.join(root, 'package.json'))) return { name: 'npm', evidence: 'package.json' };
  return { name: 'unknown', evidence: '' };
}

function detectTests() {
  const evidence = [];
  const pkgPath = path.join(root, 'package.json');
  if (exists(pkgPath)) {
    try {
      const pkg = JSON.parse(read(pkgPath));
      if (pkg.scripts && pkg.scripts.test) evidence.push('package.json scripts.test');
    } catch (_) {}
  }
  for (const dir of ['test', 'tests', '__tests__']) {
    if (exists(path.join(root, dir))) evidence.push(`${dir}/`);
  }
  for (const file of ['Makefile', 'makefile']) {
    if (exists(path.join(root, file)) && /\b(test|bats|pytest|go test|cargo test)\b/.test(read(path.join(root, file)))) evidence.push(`${file} test target`);
  }
  return [...new Set(evidence)];
}

function detectCi() {
  const evidence = [];
  const workflowDir = path.join(root, '.github/workflows');
  if (exists(workflowDir)) {
    for (const f of fs.readdirSync(workflowDir).filter((name) => /\.ya?ml$/.test(name))) {
      evidence.push(`.github/workflows/${f}`);
    }
  }
  for (const file of ['.gitlab-ci.yml', 'circle.yml', '.circleci/config.yml', 'Jenkinsfile']) {
    if (exists(path.join(root, file))) evidence.push(file);
  }
  return evidence;
}

function extractFrontmatter(content) {
  if (!content.startsWith('---')) return {};
  const end = content.indexOf('\n---', 3);
  if (end === -1) return {};
  const fm = content.slice(3, end).trim();
  const out = {};
  let current = '';
  for (const rawLine of fm.split('\n')) {
    const list = rawLine.match(/^\s+-\s+(.+)$/);
    if (list && current) {
      if (!Array.isArray(out[current])) out[current] = out[current] ? [out[current]] : [];
      out[current].push(strip(list[1]));
      continue;
    }
    const kv = rawLine.match(/^([\w][\w_-]*)\s*:\s*(.*)$/);
    if (!kv) continue;
    current = kv[1];
    const val = strip(kv[2]);
    if (!val) {
      out[current] = [];
    } else if (/^\[.*\]$/.test(val)) {
      out[current] = val.slice(1, -1).split(',').map((part) => strip(part)).filter(Boolean);
    } else {
      out[current] = val;
    }
  }
  return out;
}

function findLegacyReferences(content) {
  const patterns = [
    ['Task tool', /Task tool/],
    ['Task(...)', /\bTask\s*\(/],
    ['TodoWrite', /\bTodoWrite\b/],
    ['Bash(...)', /\bBash\s*\(/],
    ['Read(...)', /\bRead\s*\(/],
    ['Edit(...)', /\bEdit\s*\(/],
    ['Write(...)', /\bWrite\s*\(/],
    ['mcp__*', /\bmcp__[A-Za-z0-9_:-]+/],
    ['claude-code', /\bclaude-code\b/i],
    ['Claude Code', /\bClaude Code\b/]
  ];
  const found = [];
  for (const line of content.split('\n')) {
    for (const [label, re] of patterns) {
      if (!re.test(line)) continue;
      if (line.includes(`\`${label.replace('(...)', '(')}\``) || line.includes(`\`${label}\``)) continue;
      found.push(label);
    }
  }
  return [...new Set(found)];
}

function scanSkills() {
  const home = process.env.HOME || '';
  const bundledRoot = path.resolve(libDir, '..', 'skills');
  const roots = [
    { dir: path.join(root, '.claude/skills'), scope: 'project', agent: 'claude-code' },
    { dir: path.join(root, '.agents/skills'), scope: 'project', agent: 'any' },
    { dir: path.join(root, '.codex/skills'), scope: 'project', agent: 'codex' },
    { dir: path.join(home, '.claude/skills'), scope: 'global', agent: 'claude-code' },
    { dir: path.join(home, '.agents/skills'), scope: 'global', agent: 'any' },
    { dir: bundledRoot, scope: 'bundled', agent: 'any' }
  ];
  const skills = [];
  const seen = new Set();
  for (const src of roots) {
    if (!src.dir || !exists(src.dir)) continue;
    let entries = [];
    try { entries = fs.readdirSync(src.dir, { withFileTypes: true }); } catch (_) { continue; }
    for (const entry of entries) {
      if (!entry.isDirectory()) continue;
      const skillMd = path.join(src.dir, entry.name, 'SKILL.md');
      if (!exists(skillMd)) continue;
      const content = read(skillMd);
      const fm = extractFrontmatter(content);
      const name = fm.name || entry.name;
      const key = `${src.scope}:${src.agent}:${name}:${skillMd}`;
      if (seen.has(key)) continue;
      seen.add(key);
      const phaseRaw = fm.phases || fm.phase || [];
      const phases = Array.isArray(phaseRaw) ? phaseRaw : (phaseRaw ? [phaseRaw] : []);
      skills.push({
        name,
        description: fm.description || '',
        path: rel(skillMd),
        abs_path: skillMd,
        scope: src.scope,
        agent: fm.agent || src.agent,
        phases,
        legacy_references: findLegacyReferences(content)
      });
    }
  }
  return skills;
}

function agentMatches(skillAgent, activeAgent) {
  if (!skillAgent || skillAgent === 'any') return true;
  if (skillAgent === activeAgent) return true;
  if (activeAgent === 'gemini' && skillAgent === 'gemini-cli') return true;
  return false;
}

function preferredSkill(skills, name, activeAgent) {
  const matches = skills.filter((s) => s.name === name);
  if (matches.length === 0) return null;
  const scoped = matches.find((s) => s.scope === 'project' && agentMatches(s.agent, activeAgent));
  if (scoped) return scoped;
  const global = matches.find((s) => s.scope === 'global' && agentMatches(s.agent, activeAgent));
  if (global) return global;
  const bundled = matches.find((s) => s.scope === 'bundled');
  return bundled || matches[0];
}

function configuredPhaseSkill(flat, activeAgent, phase) {
  const agentNorm = activeAgent.replace(/-/g, '_').toUpperCase();
  return flat[`CFG_AGENTS_${agentNorm}_SKILLS_${phase.toUpperCase()}`] || '';
}

function classifySkill(skill, activeAgent, routed) {
  if (!skill) {
    return {
      classification: 'missing',
      reason: 'Configured or expected skill was not found in project, global, or bundled skill roots.',
      fixes: ['Install the skill or move it to the agent-visible skill root before routing it.']
    };
  }

  const cap = capabilities[activeAgent] || {};
  if (skill.legacy_references.length > 0 && activeAgent !== 'claude-code') {
    return {
      classification: 'incompatible',
      reason: `Contains unsupported runtime/tool assumptions for ${activeAgent}: ${skill.legacy_references.join(', ')}.`,
      fixes: [`Remove Claude-only tool references from ${skill.path}: ${skill.legacy_references.join(', ')}.`]
    };
  }

  if (routed) {
    if (activeAgent === 'claude-code') {
      if (skill.agent === 'claude-code' && (skill.scope === 'project' || skill.scope === 'global')) {
        return { classification: 'usable-native', reason: 'Claude Code can load this SKILL.md natively.', fixes: [] };
      }
      return {
        classification: 'missing',
        reason: 'Claude Code cannot load this skill natively from its current root.',
        fixes: [`Move ${skill.name} to .claude/skills/${skill.name}/SKILL.md or run monozukuri setup --agent claude-code.`]
      };
    }
    if (cap.skill_injection) {
      return { classification: 'usable-injected', reason: `${activeAgent} receives this SKILL.md through portable prompt injection.`, fixes: [] };
    }
    return {
      classification: 'missing',
      reason: `${activeAgent} does not support native skills or portable skill injection.`,
      fixes: [`Use rendered phase templates for ${activeAgent}, or switch to Codex/Gemini/Claude Code for skill-backed phases.`]
    };
  }

  return {
    classification: 'discovered-not-routed',
    reason: 'Skill was discovered but is not connected to any Monozukuri phase.',
    fixes: [`Add phase frontmatter to ${skill.path}, or configure agents.${activeAgent}.skills.<phase>: ${skill.name}.`, `Manual use: ask the agent to "use ${skill.name} to <task>".`]
  };
}

function scanLocalAgents(activeAgent) {
  const roots = [
    { dir: path.join(root, '.claude/agents'), runtime: 'claude-code' },
    { dir: path.join(root, '.agents/agents'), runtime: 'any' },
    { dir: path.join(root, '.codex/agents'), runtime: 'codex' }
  ];
  const agents = [];
  for (const src of roots) {
    if (!exists(src.dir)) continue;
    for (const name of fs.readdirSync(src.dir).filter((f) => /\.(md|ya?ml)$/.test(f)).sort()) {
      const agent = {
        name: name.replace(/\.(md|ya?ml)$/, ''),
        path: rel(path.join(src.dir, name)),
        runtime: src.runtime,
        status: 'usable',
        fixes: []
      };
      if (src.runtime !== 'any' && src.runtime !== activeAgent) {
        agent.status = 'discovered-not-routed';
        agent.reason = `${activeAgent || 'the active agent'} does not consume ${rel(src.dir)} project agents.`;
        agent.fixes.push(`Move reusable instructions from ${agent.path} into AGENTS.md or convert them into .agents/skills/${agent.name}/SKILL.md.`);
      }
      agents.push(agent);
    }
  }
  return agents;
}

const configPath = findConfig();
const flat = parseConfigFlat(configPath);
const activeAgent = activeAgentArg || process.env.MONOZUKURI_AGENT || flat.CFG_AGENT || (configPath ? 'claude-code' : '');

if (configPath) {
  addCheck('config', 'pass', 'Project config found.', { path: rel(configPath), active_agent: activeAgent || null });
} else {
  addCheck('config', 'fail', 'Project config is missing.', {}, 'Run monozukuri init to create .monozukuri/config.yaml.');
}

const stack = detectStack();
if (stack.length > 0) addCheck('stack', 'pass', `Detected stack: ${stack.join(', ')}.`, { stack });
else addCheck('stack', 'warn', 'No supported project stack detected.', {}, 'Add a supported project manifest such as package.json, pyproject.toml, go.mod, Cargo.toml, Package.swift, or an Xcode project.');

const pm = detectPackageManager();
if (pm.name !== 'unknown') addCheck('package_manager', 'pass', `Detected package manager: ${pm.name}.`, pm);
else addCheck('package_manager', 'warn', 'No package manager detected.', {}, 'Add a lockfile or supported project manifest so Monozukuri can infer build/test commands.');

const tests = detectTests();
if (tests.length > 0) addCheck('tests', 'pass', 'Test surface detected.', { evidence: tests });
else addCheck('tests', 'warn', 'No test command or test directory detected.', {}, 'Add a test script or documented test directory before relying on full_auto.');

const ci = detectCi();
if (ci.length > 0) addCheck('ci', 'pass', 'CI configuration detected.', { files: ci });
else addCheck('ci', 'warn', 'No CI configuration detected.', {}, 'Add a CI workflow so generated PRs have an objective merge gate.');

const sourceAdapter = flat.CFG_SOURCE_ADAPTER || (configPath ? 'markdown' : '');
if (!configPath) {
  addCheck('backlog', 'fail', 'Backlog source cannot be resolved without config.', {}, 'Run monozukuri init and configure source.adapter.');
} else if (sourceAdapter === 'markdown' || sourceAdapter === '') {
  const backlogFile = flat.CFG_SOURCE_MARKDOWN_FILE || 'features.md';
  if (exists(path.join(root, backlogFile))) addCheck('backlog', 'pass', 'Markdown backlog found.', { adapter: 'markdown', file: backlogFile });
  else addCheck('backlog', 'fail', 'Markdown backlog file is missing.', { adapter: 'markdown', file: backlogFile }, `Create ${backlogFile} or update source.markdown.file in .monozukuri/config.yaml.`);
} else if (sourceAdapter === 'github') {
  if (commandOk('command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1')) addCheck('backlog', 'pass', 'GitHub backlog adapter is available.', { adapter: 'github' });
  else addCheck('backlog', 'fail', 'GitHub backlog adapter is configured but gh is not authenticated.', { adapter: 'github' }, 'Install GitHub CLI and run gh auth login.');
} else if (sourceAdapter === 'linear') {
  if (process.env.LINEAR_API_KEY) addCheck('backlog', 'pass', 'Linear backlog adapter has credentials.', { adapter: 'linear' });
  else addCheck('backlog', 'fail', 'Linear backlog adapter is configured but LINEAR_API_KEY is missing.', { adapter: 'linear' }, 'Set LINEAR_API_KEY before running Monozukuri.');
} else {
  addCheck('backlog', 'warn', `Backlog adapter '${sourceAdapter}' is not recognized by doctor.`, { adapter: sourceAdapter }, 'Use markdown, github, or linear for V2 readiness checks.');
}

if (activeAgent) {
  const bin = cliBins[activeAgent] || activeAgent;
  if (!commandOk(`command -v ${bin} >/dev/null 2>&1`)) {
    addCheck('active_agent', 'fail', `${activeAgent} CLI is not installed.`, { active_agent: activeAgent, binary: bin }, `Install/authenticate ${bin}, then rerun monozukuri doctor.`);
  } else if (activeAgent === 'codex' && !commandOk('codex login status >/dev/null 2>&1')) {
    addCheck('active_agent', 'fail', 'Codex CLI is installed but not authenticated.', { active_agent: activeAgent }, 'Run codex login.');
  } else if (activeAgent === 'gemini' && !exists(path.join(process.env.HOME || '', '.gemini/oauth_creds.json'))) {
    addCheck('active_agent', 'fail', 'Gemini CLI is installed but OAuth credentials were not found.', { active_agent: activeAgent }, 'Run gemini auth login.');
  } else if (activeAgent === 'aider' && !process.env.ANTHROPIC_API_KEY && !process.env.OPENAI_API_KEY) {
    addCheck('active_agent', 'fail', 'Aider is installed but no API key is configured.', { active_agent: activeAgent }, 'Set ANTHROPIC_API_KEY or OPENAI_API_KEY.');
  } else {
    addCheck('active_agent', 'pass', `${activeAgent} is available.`, { active_agent: activeAgent, binary: bin });
  }
} else {
  addCheck('active_agent', 'warn', 'No active agent configured.', {}, 'Set agent: claude-code, codex, gemini, kiro, or aider in .monozukuri/config.yaml.');
}

const discoveredSkills = scanSkills();
const phaseRouting = {};
const routedNames = new Set();
if (activeAgent) {
  for (const phase of phases) {
    let skillName = configuredPhaseSkill(flat, activeAgent, phase);
    let source = skillName ? 'config' : '';
    if (!skillName) {
      const frontmatterMatch = discoveredSkills.find((s) => s.phases.includes(phase) && agentMatches(s.agent, activeAgent));
      if (frontmatterMatch) {
        skillName = frontmatterMatch.name;
        source = 'frontmatter';
      }
    }
    if (!skillName) {
      skillName = defaultPhaseSkills[phase];
      source = 'default';
    }
    routedNames.add(skillName);
    const skill = preferredSkill(discoveredSkills, skillName, activeAgent);
    const verdict = classifySkill(skill, activeAgent, true);
    phaseRouting[phase] = {
      skill: skillName,
      source,
      classification: verdict.classification,
      reason: verdict.reason,
      path: skill ? skill.path : null,
      fixes: verdict.fixes
    };
  }
}

const skillRows = [];
const includedSkillKeys = new Set();
for (const skill of discoveredSkills) {
  const isProject = skill.scope === 'project';
  const isRouted = routedNames.has(skill.name);
  if (!isProject && !isRouted) continue;
  const verdict = activeAgent
    ? classifySkill(skill, activeAgent, isRouted)
    : {
        classification: 'discovered-not-routed',
        reason: 'No active agent is configured, so doctor cannot prove how this skill is consumed.',
        fixes: [`Set agent: claude-code, codex, or gemini in .monozukuri/config.yaml before routing ${skill.name}.`, `Manual use: ask the agent to "use ${skill.name} to <task>".`]
      };
  const key = `${skill.scope}:${skill.path}`;
  if (includedSkillKeys.has(key)) continue;
  includedSkillKeys.add(key);
  const row = {
    name: skill.name,
    path: skill.path,
    scope: skill.scope,
    agent: skill.agent,
    phases: skill.phases,
    classification: verdict.classification,
    reason: verdict.reason,
    legacy_references: skill.legacy_references,
    fixes: verdict.fixes
  };
  skillRows.push(row);
  if (!['usable-native', 'usable-injected'].includes(row.classification)) {
    for (const action of row.fixes) addFix('warning', `skill:${row.name}`, action);
  }
}

for (const [phase, route] of Object.entries(phaseRouting)) {
  if (!['usable-native', 'usable-injected'].includes(route.classification)) {
    for (const action of route.fixes) addFix(route.classification === 'missing' ? 'warning' : 'warning', `phase:${phase}`, action);
  }
}

const localAgents = scanLocalAgents(activeAgent || '');
for (const agent of localAgents) {
  if (agent.status !== 'usable') {
    for (const action of agent.fixes) addFix('warning', `agent:${agent.name}`, action);
  }
}

const unusablePhaseCount = Object.values(phaseRouting).filter((r) => !['usable-native', 'usable-injected'].includes(r.classification)).length;
if (!activeAgent) {
  addCheck('phase_skills', 'warn', 'Phase-routed skills cannot be evaluated without an active agent.', {}, 'Set agent: claude-code, codex, gemini, kiro, or aider in .monozukuri/config.yaml.');
} else if (unusablePhaseCount === 0) {
  addCheck('phase_skills', 'pass', 'All phase-routed skills are usable by the active agent.', { active_agent: activeAgent || null });
} else {
  addCheck('phase_skills', 'warn', `${unusablePhaseCount} phase-routed skill(s) need attention.`, { active_agent: activeAgent || null, count: unusablePhaseCount }, 'Review phase_routing and apply the listed skill fixes.');
}

const projectSkillIssues = skillRows.filter((s) => s.scope === 'project' && !['usable-native', 'usable-injected'].includes(s.classification));
if (projectSkillIssues.length === 0) {
  addCheck('project_skills', 'pass', 'No project-local skill issues detected.', { count: skillRows.filter((s) => s.scope === 'project').length });
} else {
  addCheck('project_skills', 'warn', `${projectSkillIssues.length} project-local skill(s) need routing or compatibility fixes.`, { count: projectSkillIssues.length }, 'Route discovered skills to phases or remove unsupported runtime assumptions.');
}

let status = 'ready';
if (checks.some((c) => c.status === 'fail')) status = 'blocked';
else if (checks.some((c) => c.status === 'warn') || localAgents.some((a) => a.status !== 'usable')) status = 'partial';

const result = {
  schema_version: 'doctor-readiness/v1',
  status,
  active_agent: activeAgent || null,
  checks,
  agents: localAgents,
  skills: skillRows,
  phase_routing: phaseRouting,
  fixes
};
process.stdout.write(JSON.stringify(result, null, 2));
NODE
}

_doctor_print_project_readiness() {
  local tmp_json
  tmp_json="$(mktemp)"
  cat > "$tmp_json"
  node - "$tmp_json" <<'NODE'
const fs = require('fs');
const input = fs.readFileSync(process.argv[2], 'utf8');
  let data;
  try { data = JSON.parse(input); } catch (_) { process.exit(0); }
  const symbol = data.status === 'ready' ? '✓' : (data.status === 'blocked' ? '✗' : '~');
  console.log('');
  console.log('Project readiness');
  console.log(`  ${symbol} ${data.status}`);
  console.log(`  Active agent: ${data.active_agent || 'not configured'}`);
  console.log('');
  console.log('Project skills and agents');
  console.log('  Phase routing:');
  let printedPhase = false;
  for (const phase of ['prd', 'techspec', 'tasks', 'code', 'tests', 'pr']) {
    const route = data.phase_routing[phase];
    if (!route) continue;
    printedPhase = true;
    const location = route.path ? ` (${route.path})` : '';
    console.log(`    ${phase}: ${route.skill} -> ${route.classification}${location}`);
  }
  if (!printedPhase) console.log('    not evaluated; configure an active agent first');
  const attentionSkills = data.skills.filter((s) => !['usable-native', 'usable-injected'].includes(s.classification));
  if (attentionSkills.length > 0) {
    console.log('  Skills needing attention:');
    for (const skill of attentionSkills.slice(0, 8)) {
      console.log(`    ${skill.name}: ${skill.classification} - ${skill.reason}`);
      if (skill.fixes[0]) console.log(`      fix: ${skill.fixes[0]}`);
    }
    if (attentionSkills.length > 8) console.log(`    ... ${attentionSkills.length - 8} more`);
  } else {
    console.log('  Skills needing attention: none');
  }
  const attentionAgents = data.agents.filter((a) => a.status !== 'usable');
  if (attentionAgents.length > 0) {
    console.log('  Agents needing attention:');
    for (const agent of attentionAgents) {
      console.log(`    ${agent.name}: ${agent.status} - ${agent.reason || ''}`);
      if (agent.fixes[0]) console.log(`      fix: ${agent.fixes[0]}`);
    }
  }
  console.log('  Manual skill invocation: ask the active agent to "use <skill-name> to <task>".');
  if (data.fixes.length > 0) {
    console.log('');
    console.log('Fixes');
    for (const fix of data.fixes.slice(0, 10)) {
      console.log(`  [${fix.severity}] ${fix.target}: ${fix.action}`);
    }
    if (data.fixes.length > 10) console.log(`  ... ${data.fixes.length - 10} more fixes in doctor --json`);
  }
NODE
  rm -f "$tmp_json"
}

sub_doctor() {
  local failed=0

  # Source semantic tokens if not already loaded
  [ -z "${T_RESET:-}" ] && [ -f "${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")/../lib}/cli/colors.sh" ] && \
    source "${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")/../lib}/cli/colors.sh"

  local active_agent
  active_agent="$(_doctor_configured_agent)"

  if [ "${OPT_JSON:-false}" = "true" ]; then
    _doctor_project_readiness_json "$active_agent"
    return 0
  fi

  printf "%sMonozukuri — pre-flight checks%s\n\n" "${T_BOLD:-\033[1m}" "${T_RESET:-\033[0m}"

  # node >= 18
  if command -v node >/dev/null 2>&1; then
    local node_ver
    node_ver=$(node -e 'process.stdout.write(process.versions.node)' 2>/dev/null)
    local node_major
    node_major=$(echo "$node_ver" | cut -d. -f1)
    if [ "${node_major:-0}" -ge 18 ]; then
      _doctor_pass "node ${node_ver}"
    else
      _doctor_fail "node ${node_ver} — need ≥ 18" "brew upgrade node"
      failed=1
    fi
  else
    _doctor_fail "node not found" "brew install node  |  https://nodejs.org"
    failed=1
  fi

  # jq
  if command -v jq >/dev/null 2>&1; then
    _doctor_pass "jq $(jq --version 2>/dev/null | sed 's/jq-//')"
  else
    _doctor_fail "jq not found" "brew install jq  |  apt install jq"
    failed=1
  fi

  # gh installed + authenticated
  if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
      _doctor_pass "gh authenticated"
    else
      _doctor_fail "gh not authenticated" "gh auth login"
      failed=1
    fi
  else
    _doctor_fail "gh not found" "brew install gh  |  https://cli.github.com"
    failed=1
  fi

  # git worktree (must be inside a git repo when running a project command)
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    _doctor_pass "git worktree available"
  else
    _doctor_fail "not inside a git repository" "Run monozukuri from the root of your project"
    failed=1
  fi

  # Active agent CLI/auth is blocking only when a project config or
  # MONOZUKURI_AGENT selects one. Otherwise, agent CLIs are advisory.
  if [ -n "$active_agent" ]; then
    _doctor_check_active_agent "$active_agent" || failed=1
  else
    printf "  %s~%s no .monozukuri config found; agent CLI checks are advisory\n" \
      "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}"
  fi

  # gum (optional — needed for interactive mode)
  if command -v gum >/dev/null 2>&1; then
    _doctor_pass "gum $(gum --version 2>/dev/null | head -1) (interactive mode enabled)"
  else
    printf "  %s~%s gum not found (optional — enables interactive prompts)\n" "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}"
    printf "    → brew install gum\n"
  fi

  # mz-* skills — check all installed agents have the full skill set
  if [ -n "${LIB_DIR:-}" ] && [ -f "${LIB_DIR}/setup/detect.sh" ] && [ -f "${LIB_DIR}/setup/install.sh" ]; then
    # shellcheck source=/dev/null
    source "${LIB_DIR}/setup/detect.sh"
    source "${LIB_DIR}/setup/install.sh"
    source "${LIB_DIR}/agent/skill-detect.sh"
    local detected_agents total_skills ag ok missing_list skill active_setup_agent
    detected_agents="$(setup_detected_agents)"
    total_skills="$(setup_skills_list | wc -l | tr -d ' ')"
    active_setup_agent="$(_doctor_setup_agent_id "${active_agent:-}")"
    if [ -z "$detected_agents" ]; then
      printf "  %s~%s mz-* skills: no agents detected\n" "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}"
    else
      for ag in $detected_agents; do
        if ! _doctor_agent_supports_native_skills "$ag"; then
          _doctor_pass "$(setup_agent_name "$ag") uses rendered prompts; mz-* native skills not required"
          continue
        fi

        ok=0; missing_list=""
        while IFS= read -r skill; do
          if skill_installed "$ag" "$skill"; then
            ok=$((ok + 1))
          else
            missing_list="${missing_list:+$missing_list, }$skill"
          fi
        done < <(setup_skills_list)
        if [ -z "$missing_list" ]; then
          _doctor_pass "$(setup_agent_name "$ag") skills: ${ok}/${total_skills} installed"
        elif [ -n "$active_setup_agent" ] && [ "$ag" = "$active_setup_agent" ]; then
          _doctor_fail "$(setup_agent_name "$ag") skills: missing — $missing_list" \
                       "monozukuri setup --agent $ag"
          failed=1
        else
          printf "  %s~%s %s skills: missing — %s (optional; run monozukuri setup --agent %s)\n" \
            "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}" \
            "$(setup_agent_name "$ag")" "$missing_list" "$ag"
        fi
      done
    fi
  else
    printf "  %s~%s mz-* skills: skipped (library path unavailable)\n" "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}"
  fi

  # Optional adapter CLIs
  local _pair _cli _cli_bin
  for _pair in "claude-code:claude" "codex:codex" "gemini:gemini" "kiro:kiro" "aider:aider"; do
    _cli="${_pair%%:*}"; _cli_bin="${_pair##*:}"
    [ -n "${active_agent:-}" ] && [ "$_cli" = "$active_agent" ] && continue
    if command -v "$_cli_bin" >/dev/null 2>&1; then
      _doctor_pass "${_cli} CLI found"
    else
      printf "  %s-%s %s CLI not installed (optional)\n" "${T_DIM:-\033[2m}" "${T_RESET:-\033[0m}" "$_cli"
    fi
  done

  # Project-local agents (.claude/agents/)
  if [ -d ".claude/agents" ]; then
    local _agent_count=0 _f
    while IFS= read -r _f; do
      [ -n "$_f" ] && _agent_count=$((_agent_count + 1))
    done < <(find .claude/agents -maxdepth 1 \( -name '*.md' -o -name '*.yaml' -o -name '*.yml' \) 2>/dev/null | sort)
    if [ "$_agent_count" -gt 0 ]; then
      _doctor_pass ".claude/agents/: ${_agent_count} project-local agent(s)"
      find .claude/agents -maxdepth 1 \( -name '*.md' -o -name '*.yaml' -o -name '*.yml' \) 2>/dev/null | sort \
        | while IFS= read -r _f; do printf "    %s\n" "$(basename "$_f")"; done
    else
      printf "  %s~%s .claude/agents/ exists but no agent files found\n" "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}"
    fi
  else
    printf "  %s-%s .claude/agents/ not present\n" "${T_DIM:-\033[2m}" "${T_RESET:-\033[0m}"
  fi

  # Project-local skills (.claude/skills/ — user-installed, beyond mz-*)
  if [ -d ".claude/skills" ]; then
    local _skill_count=0 _sd
    while IFS= read -r _sd; do
      [ -n "$_sd" ] && [ -f "$_sd/SKILL.md" ] && _skill_count=$((_skill_count + 1))
    done < <(find .claude/skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort)
    if [ "$_skill_count" -gt 0 ]; then
      _doctor_pass ".claude/skills/: ${_skill_count} project-local skill(s)"
      find .claude/skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort \
        | while IFS= read -r _sd; do
            [ -f "$_sd/SKILL.md" ] && printf "    %s\n" "$(basename "$_sd")"
          done
    else
      printf "  %s~%s .claude/skills/ exists but no SKILL.md files found\n" "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}"
    fi
  else
    printf "  %s-%s .claude/skills/ not present\n" "${T_DIM:-\033[2m}" "${T_RESET:-\033[0m}"
  fi

  # Portable project-local skills (.agents/skills/ — rendered-prompt adapters)
  if [ -d ".agents/skills" ]; then
    local _agent_skill_count=0 _asd
    while IFS= read -r _asd; do
      [ -n "$_asd" ] && [ -f "$_asd/SKILL.md" ] && _agent_skill_count=$((_agent_skill_count + 1))
    done < <(find .agents/skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort)
    if [ "$_agent_skill_count" -gt 0 ]; then
      _doctor_pass ".agents/skills/: ${_agent_skill_count} portable project-local skill(s)"
      find .agents/skills -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort \
        | while IFS= read -r _asd; do
            [ -f "$_asd/SKILL.md" ] && printf "    %s\n" "$(basename "$_asd")"
          done
    else
      printf "  %s~%s .agents/skills/ exists but no SKILL.md files found\n" "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}"
    fi
  else
    printf "  %s-%s .agents/skills/ not present\n" "${T_DIM:-\033[2m}" "${T_RESET:-\033[0m}"
  fi

  # Discovered skills manifest (written by `monozukuri run` via skill-discovery.sh)
  local _skills_manifest=".monozukuri/skills-manifest.json"
  if [ -f "$_skills_manifest" ] && command -v jq >/dev/null 2>&1; then
    local _total _proj _glob _injectable
    _total=$(jq '.skills | length' "$_skills_manifest" 2>/dev/null || echo 0)
    _proj=$(jq '[.skills[] | select(.scope == "project")] | length' "$_skills_manifest" 2>/dev/null || echo 0)
    _glob=$(jq '[.skills[] | select(.scope == "global")]  | length' "$_skills_manifest" 2>/dev/null || echo 0)
    _doctor_pass "skills-manifest.json: ${_total} skill(s) discovered (${_proj} project, ${_glob} global)"
    _doctor_pass "skills discovered: ${_total} (${_proj} project, ${_glob} global)"
    if [ -n "${active_agent:-}" ]; then
      _injectable=$(jq --arg agent "$active_agent" '
        def norm(a): if a == "gemini-cli" then "gemini" else a end;
        [.skills[] | select((.agent == null) or (.agent == "any") or (norm(.agent) == norm($agent)))] | length
      ' "$_skills_manifest" 2>/dev/null || echo 0)
      _doctor_pass "skills injectable for ${active_agent}: ${_injectable}"
    fi
  else
    printf "  %s-%s skills-manifest.json: not yet built (run \`monozukuri run\` to populate)\n" \
      "${T_DIM:-\033[2m}" "${T_RESET:-\033[0m}"
  fi

  # Known-incompatible skills — warn (non-blocking) when config routes a phase
  # to a skill that violates the monozukuri autonomy contract.
  local _ki_sh="${LIB_DIR}/agent/known-incompatible.sh"
  local _cfg=".monozukuri/config.yaml"
  if [ -f "$_ki_sh" ] && [ -f "$_cfg" ]; then
    # shellcheck source=../lib/agent/known-incompatible.sh
    source "$_ki_sh"
    # Extract phase → skill pairs from agents.claude-code.skills block.
    # grep targets lines of the form "  <phase>: <skill-name>" (2-space indent).
    local _ki_phase _ki_skill _ki_warned=0
    while IFS=': ' read -r _ki_phase _ki_skill; do
      _ki_phase="${_ki_phase##*( )}"   # strip leading spaces (bash 4 extglob)
      _ki_skill="${_ki_skill%%[[:space:]]*}" # strip trailing spaces / comments
      [ -z "$_ki_skill" ] && continue
      if is_skill_known_incompatible "$_ki_skill"; then
        local _ki_reason
        _ki_reason=$(known_incompatible_reason "$_ki_skill")
        printf "  %s~%s skill '%s' (phase '%s') is known incompatible: %s\n" \
          "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}" \
          "$_ki_skill" "$_ki_phase" "$_ki_reason" >&2
        printf "    See: docs/adapter-contract.md#known-incompatible-skills\n" >&2
        _ki_warned=$((_ki_warned + 1))
      fi
    done < <(grep -E '^\s+(prd|techspec|tasks|code|tests|pr):\s+\S' "$_cfg" 2>/dev/null || true)
    if [ "$_ki_warned" -eq 0 ] && [ -f "$_cfg" ]; then
      _doctor_pass "skill compatibility: no known-incompatible skills configured"
    fi
  fi

  # ADR-017: multi-turn visibility (only printed when opted in)
  if [[ "${MONOZUKURI_MULTI_TURN:-0}" == "1" ]]; then
    local _mt_agent
    _mt_agent=$(grep -E '^\s*agent\s*:' ".monozukuri/config.yaml" 2>/dev/null | head -1 \
      | sed 's/.*:\s*//' | tr -d '"' | xargs 2>/dev/null || echo "claude-code")
    local _mt_adapter="${LIB_DIR}/agent/adapter-${_mt_agent}.sh"
    if [[ -f "$_mt_adapter" ]] && grep -q '"session_continuity":[[:space:]]*true' "$_mt_adapter" 2>/dev/null; then
      _doctor_pass "MONOZUKURI_MULTI_TURN=1 (${_mt_agent}: session_continuity active, mz-* skills bypassed)"
    else
      printf "  %s~%s MONOZUKURI_MULTI_TURN=1 but '%s' lacks session_continuity — cold-process fallback\n" \
        "${T_WARNING:-\033[0;33m}" "${T_RESET:-\033[0m}" "$_mt_agent"
    fi
  fi

  local readiness_json readiness_status
  readiness_json="$(_doctor_project_readiness_json "$active_agent" 2>/dev/null || true)"
  if [ -n "$readiness_json" ]; then
    printf '%s\n' "$readiness_json" | _doctor_print_project_readiness
    readiness_status="$(printf '%s\n' "$readiness_json" | node -e "let s='';process.stdin.on('data',c=>s+=c);process.stdin.on('end',()=>{try{process.stdout.write(JSON.parse(s).status||'')}catch(_){}})" 2>/dev/null || true)"
  else
    readiness_status=""
  fi

  echo ""
  if [ "$failed" -eq 0 ]; then
    if [ "$readiness_status" = "ready" ]; then
      printf "%s✓ All checks passed — ready to run%s\n" "${T_SUCCESS:-\033[0;32m}" "${T_RESET:-\033[0m}"
    else
      printf "%s~ Pre-flight checks passed; project readiness is %s%s\n" \
        "${T_WARNING:-\033[0;33m}" "${readiness_status:-unknown}" "${T_RESET:-\033[0m}"
    fi
    return 0
  else
    printf "%s✗ One or more checks failed — fix the issues above and re-run%s\n" "${T_DANGER:-\033[0;31m}" "${T_RESET:-\033[0m}"
    exit 11
  fi
}
