// Event types arriving as JSONL on stdin

export type Phase = 'prd' | 'techspec' | 'tasks' | 'code' | 'tests' | 'pr';
export type PhaseStatus = 'pending' | 'in_progress' | 'done' | 'failed';
export type FeatureStatus = 'queued' | 'active' | 'done' | 'failed' | 'skipped';

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
  | LearningCapturedEvent
  | LogLineEvent
  | RunCompletedEvent;

export type ViewMode = 'main' | 'learnings' | 'filter' | 'search' | 'help';
