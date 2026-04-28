# PRD — feat-qa-002: Cache warming on startup

**Feature:** feat-qa-002
**Source:** qa-fixture

---

## Background

Cold-start latency spikes to 2 s because the in-memory cache is empty on
restart. Users experience these spikes when the service is redeployed during
peak traffic windows.

## Acceptance Criteria

- First request after restart is served from warm cache within 200 ms
- Cache warming completes in the background; the process does not block
  the HTTP server from accepting connections
- Warm-up skipped when `DISABLE_CACHE_WARMING=true` is set
