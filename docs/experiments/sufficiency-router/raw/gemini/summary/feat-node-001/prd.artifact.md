# PRD - feat-node-001

## Problem

Add health check endpoint is not implemented yet, which blocks users from relying on this capability.

## Solution

Implement the smallest deterministic behavior that satisfies the feature request for node.

## Success criteria

| Criterion | How verified |
| --- | --- |
| Feature works | Run the relevant project tests |

## Functional requirements

- The implementation covers Add a `/health` endpoint that returns `{ status: "ok", version: "1.0.0" }`.

## Out of scope

- Unrelated refactors
