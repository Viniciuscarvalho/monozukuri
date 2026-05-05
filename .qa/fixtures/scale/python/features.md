# Features

## feat-py-001: Add health check route

Add a `/health` route that returns `{"status": "ok"}` with HTTP 200.

Status: backlog

## feat-py-002: Add structured logging

Replace print statements with structlog for JSON-structured log output.

Status: backlog

## feat-py-003: Add database connection pool

Configure SQLAlchemy connection pool with configurable pool_size and max_overflow.

Status: backlog

## feat-py-004: Add input validation with pydantic

Validate all request bodies with pydantic v2 models. Return 422 on validation failure.

Status: backlog

## feat-py-005: Add API versioning prefix

Prefix all routes with `/api/v1`. Serve a redirect from `/api` to `/api/v1`.

Status: backlog
