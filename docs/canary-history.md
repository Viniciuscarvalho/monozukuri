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
