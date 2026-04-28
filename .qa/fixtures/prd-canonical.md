# PRD — feat-qa-001: Add health endpoint

**Feature:** feat-qa-001
**Source:** qa-fixture
**Date:** 2026-01-01
**Status:** backlog

---

## Problem Statement

The service has no standardised health check endpoint. Orchestration tools
(Kubernetes, ECS) cannot determine liveness without scraping the main index
route, which is expensive and masks real errors.

## Success Criteria

- `GET /health` returns HTTP 200 and `{"status":"ok"}` within 50 ms
- Unhealthy state (DB unreachable) returns HTTP 503 and `{"status":"degraded"}`
- Endpoint is excluded from auth middleware
