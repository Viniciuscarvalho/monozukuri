// Event types arriving as JSONL on stdin

export type Phase = 'prd' | 'techspec' | 'tasks' | 'code' | 'tests' | 'pr';
export type PhaseStatus = 'pending' | 'in_progress' | 'done' | 'failed';
export type FeatureStatus = 'queued' | 'active' | 'done' | 'failed' | 'skipped' | 'deferred';

export interface Feature {
  id: string;
  title: string;
  status: FeatureStatus;
  phases: Record<Phase, PhaseStatus>;
  currentPhase?: Phase;
  tokens?: number;
  estimatedTokens?: number;
  costUsd?: number;
  prUrl?: string;
  error?: string;
  startedAt?: string;
  currentSkill?: string;
  currentTier?: string;
  memoryDir?: string;
  compaction?: 'none' | 'workflow' | 'task' | 'both';
}

export interface LogLine {
  ts: string;
  featureId: string;
  phase: string;
  text: string;
}

export interface AppState {
  runId: string | null;
  autonomy: string;
  model: string;
  agent: string;
  source: string;
  featureCount: number;
  budget: number;
  features: Record<string, Feature>;
  order: string[];
  current: string | null;
  totals: {
    succeeded: number;
    failed: number;
    skipped: number;
    costUsd: number;
  };
  log: LogLine[];
  spinner: string;
  setupMode: boolean;
  setupAgents: Record<string, string>;
  setupSkills: Array<{ agent: string; skill: string; status: string }>;
}

// ── Raw event shapes ────────────────────────────────────────────────────

interface BaseEvent {
  type: string;
  ts: string;
  run_id: string;
}

export interface RunStartedEvent extends BaseEvent {
  type: 'run.started';
  run_id: string;
  autonomy: string;
  model: string;
  agent: string;
  source: string;
  feature_count: number;
}

export interface BacklogLoadedEvent extends BaseEvent {
  type: 'backlog.loaded';
  features: Array<{ id: string; title: string; size_estimate?: number }>;
}

export interface FeatureQueuedEvent extends BaseEvent {
  type: 'feature.queued';
  feature_id: string;
  position: number;
}

export interface FeatureStartedEvent extends BaseEvent {
  type: 'feature.started';
  feature_id: string;
  worktree_path: string;
  branch: string;
  agent?: string;
}

export interface FeatureSkippedEvent extends BaseEvent {
  type: 'feature.skipped';
  feature_id: string;
  reason: string;
  estimated_tokens?: number;
}

export interface PhaseStartedEvent extends BaseEvent {
  type: 'phase.started';
  feature_id: string;
  phase: Phase;
}

export interface PhaseProgressEvent extends BaseEvent {
  type: 'phase.progress';
  feature_id: string;
  phase: Phase;
  elapsed_ms: number;
  tokens_used: number;
}

export interface PhaseCompletedEvent extends BaseEvent {
  type: 'phase.completed';
  feature_id: string;
  phase: Phase;
  duration_ms: number;
  tokens_used: number;
  cost_usd: number;
}

export interface PhaseFailedEvent extends BaseEvent {
  type: 'phase.failed';
  feature_id: string;
  phase: Phase;
  error: string;
  retryable: boolean;
}

export interface FeatureCompletedEvent extends BaseEvent {
  type: 'feature.completed';
  feature_id: string;
  pr_url: string;
  total_tokens: number;
  total_cost_usd: number;
}

export interface FeatureFailedEvent extends BaseEvent {
  type: 'feature.failed';
  feature_id: string;
  error: string;
}

export interface FeatureDeferredEvent extends BaseEvent {
  type: 'feature.deferred';
  feature_id: string;
  reason: string;
  blocked_by: string;
}

export interface LearningCapturedEvent extends BaseEvent {
  type: 'learning.captured';
  feature_id: string;
  tier: string;
  summary: string;
}

export interface LogLineEvent extends BaseEvent {
  type: 'log.line';
  feature_id: string;
  stream: string;
  text: string;
}

export interface RunCompletedEvent extends BaseEvent {
  type: 'run.completed';
  run_id: string;
  succeeded: number;
  failed: number;
  skipped: number;
  total_cost_usd: number;
}

export interface SkillInvokedEvent extends BaseEvent {
  type: 'skill.invoked';
  feature_id: string;
  phase: Phase;
  tier: string;
  skill: string;
}

export interface SkillCompletedEvent extends BaseEvent {
  type: 'skill.completed';
  feature_id: string;
  phase: Phase;
  tier: string;
}

export interface SkillFailedEvent extends BaseEvent {
  type: 'skill.failed';
  feature_id: string;
  phase: Phase;
  tier: string;
  exit_code: string;
}

export interface SkillFallbackEvent extends BaseEvent {
  type: 'skill.fallback';
  feature_id: string;
  phase: Phase;
  from_skill: string;
  to_skill: string;
  exit_code: string;
}

export interface MemoryBootstrapEvent extends BaseEvent {
  type: 'memory.bootstrap';
  feature_id: string;
  memory_dir: string;
  task_file: string;
  compaction: 'none' | 'workflow' | 'task' | 'both';
}

export interface MemoryNoteEvent extends BaseEvent {
  type: 'memory.note';
  feature_id: string;
  line: string;
}

export interface SetupStartedEvent extends BaseEvent {
  type: 'setup.started';
  action: string;
}

export interface SetupAgentProgressEvent extends BaseEvent {
  type: 'setup.agent_progress';
  agent: string;
  status: string;
}

export interface SetupSkillInstalledEvent extends BaseEvent {
  type: 'setup.skill_installed';
  agent: string;
  skill: string;
  status: string;
}

export interface SetupCompletedEvent extends BaseEvent {
  type: 'setup.completed';
  action: string;
}

export type MonozukuriEvent =
  | RunStartedEvent
  | BacklogLoadedEvent
  | FeatureQueuedEvent
  | FeatureStartedEvent
  | FeatureSkippedEvent
  | PhaseStartedEvent
  | PhaseProgressEvent
  | PhaseCompletedEvent
  | PhaseFailedEvent
  | FeatureCompletedEvent
  | FeatureFailedEvent
  | FeatureDeferredEvent
  | LearningCapturedEvent
  | LogLineEvent
  | RunCompletedEvent
  | SkillInvokedEvent
  | SkillCompletedEvent
  | SkillFailedEvent
  | SkillFallbackEvent
  | MemoryBootstrapEvent
  | MemoryNoteEvent
  | SetupStartedEvent
  | SetupAgentProgressEvent
  | SetupSkillInstalledEvent
  | SetupCompletedEvent;

export type ViewMode = 'main' | 'learnings' | 'filter' | 'search' | 'help';
