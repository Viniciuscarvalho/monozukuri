# PRD - feat-py-004

## Problem

Add input validation with pydantic is not implemented yet, which blocks users from relying on this capability.

## Solution

Implement the smallest deterministic behavior that satisfies the feature request for python.

## Success criteria

| Criterion | How verified |
| --- | --- |
| Feature works | Run the relevant project tests |

## Functional requirements

- The implementation covers Validate all request bodies with pydantic v2 models. Return 422 on validation failure.

## Out of scope

- Unrelated refactors
