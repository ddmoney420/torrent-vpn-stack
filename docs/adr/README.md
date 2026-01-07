# Architecture Decision Records (ADR)

This directory contains Architecture Decision Records for the Go-native rewrite.

## Index

- [ADR-001](001-vpn-strategy.md) - VPN Integration Strategy
- [ADR-002](002-provider-plugins.md) - Provider Plugin Architecture
- [ADR-003](003-state-store.md) - State Store Selection

## Format

Each ADR follows this structure:

```markdown
# ADR-XXX: Title

## Status
[Proposed | Accepted | Deprecated | Superseded]

## Context
What is the issue we're trying to solve?

## Decision
What is the change we're proposing/announcing?

## Consequences
What becomes easier or more difficult because of this change?
```

## Creating a New ADR

1. Copy `template.md` to `NNN-short-title.md`
2. Fill in the sections
3. Submit as part of your PR
4. Link from this README once accepted
