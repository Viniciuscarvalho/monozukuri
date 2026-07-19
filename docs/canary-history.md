# Canary Run History

This file records the results of weekly canary benchmark runs. Each row represents one run against the fixed benchmark suite.

## Schema

| Column               | Type       | Description                                   |
| -------------------- | ---------- | --------------------------------------------- |
| date                 | YYYY-MM-DD | Date of canary run                            |
| run_id               | string     | Unique identifier (e.g., run-20260426-123456) |
| headline\_%          | number     | CI-pass-rate-on-first-PR (0-100)              |
| tokens_avg           | number     | Average tokens per feature                    |
| completion\_%        | number     | Feature completion rate (0-100)               |
| stack_breakdown_json | JSON       | Per-stack metrics as JSON object              |

## History

| date       | run_id              | headline\_% | tokens_avg | completion\_% | stack_breakdown_json                      |
| ---------- | ------------------- | ----------- | ---------- | ------------- | ----------------------------------------- |
| 2026-04-26 | run-20260426-183854 | 100         | 42516      | 100           | {"backend":100,"data":100,"frontend":100} |
2026-05-17 | run-20260517-040021 | 100 | 44648 | 100 | {
  "backend": 100,
  "data": 100,
  "frontend": 100
}
2026-05-24 | run-20260524-041045 | 100 | 41133 | 67 | {
  "backend": 100,
  "data": 100,
  "frontend": 100
}
2026-05-31 | run-20260531-042331 | 100 | 43434 | 100 | {
  "backend": 100,
  "data": 100,
  "frontend": 100
}
2026-06-07 | run-20260607-043840 | 100 | 46370 | 67 | {
  "backend": 100,
  "data": 100,
  "frontend": 100
}
2026-06-14 | run-20260614-044741 | 67 | 42457 | 100 | {
  "backend": 100,
  "data": 100,
  "frontend": 0
}
2026-06-21 | run-20260621-045628 | 67 | 46779 | 100 | {
  "backend": 100,
  "data": 0,
  "frontend": 100
}
2026-06-28 | run-20260628-042154 | 100 | 46115 | 67 | {
  "backend": 100,
  "data": 100,
  "frontend": 100
}
2026-07-05 | run-20260705-040025 | 100 | 44824 | 100 | {
  "backend": 100,
  "data": 100,
  "frontend": 100
}
2026-07-12 | run-20260712-033016 | 100 | 42210 | 100 | {
  "backend": 100,
  "data": 100,
  "frontend": 100
}
2026-07-19 | run-20260719-032650 | 67 | 42266 | 100 | {
  "backend": 100,
  "data": 100,
  "frontend": 0
}
