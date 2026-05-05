# Features

## feat-go-001: Add health check handler

Add a `GET /health` handler returning `{"status":"ok","version":"1.0.0"}` as JSON.

Status: backlog

## feat-go-002: Add request ID middleware

Generate a UUID request ID per request; set it in `X-Request-ID` response header.

Status: backlog

## feat-go-003: Add structured logging with slog

Replace fmt.Println with slog for structured JSON log output.

Status: backlog

## feat-go-004: Add graceful shutdown

Handle os.Signal: drain in-flight requests within 30s, then exit 0.

Status: backlog

## feat-go-005: Add Prometheus metrics

Expose `/metrics` with request count and latency histograms via `prometheus/client_golang`.

Status: backlog
