# Features

## feat-node-001: Add health check endpoint

Add a `/health` endpoint that returns `{ status: "ok", version: "1.0.0" }`.

Status: backlog

## feat-node-002: Add request logging middleware

Log all incoming requests with method, path, and response time.

Status: backlog

## feat-node-003: Add rate limiting

Add per-IP rate limiting: 100 requests per minute. Return 429 when exceeded.

Status: backlog

## feat-node-004: Add environment config validation

Validate required env vars at startup. Fail fast with clear error if missing.

Status: backlog

## feat-node-005: Add graceful shutdown handler

Handle SIGTERM: stop accepting new connections, drain existing requests, exit cleanly.

Status: backlog
