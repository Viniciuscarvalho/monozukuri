# Security Policy

## Reporting a Vulnerability

Please report security vulnerabilities via [GitHub private vulnerability reporting](https://github.com/Viniciuscarvalho/monozukuri/security/advisories/new).

Do not open a public issue for security vulnerabilities.

**Response timeline:**

- Acknowledgement: within 7 days
- Patch release: within 30 days for confirmed vulnerabilities

## Scope

In scope:

- Shell scripts in `scripts/` and `lib/`
- Node.js adapters in `scripts/adapters/`
- The Ink UI in `ui/`
- Config parsing and environment variable handling

Out of scope:

- The Claude Code skill invoked by Monozukuri (report to Anthropic)
- Third-party dependencies (report upstream)

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 1.x     | Yes       |
| < 1.0   | No        |
