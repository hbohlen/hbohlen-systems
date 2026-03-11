## Context

The workflow orchestrator skill will be a pi skill that helps manage the overall development workflow by:
1. Querying OpenSpec for current change state
2. Querying beads for workflow phase tracking
3. Computing the current phase
4. Presenting a resume point

This skill addresses the session resume problem - when returning to a project after a break, what was I working on?

## Goals / Non-Goals

**Goals:**
- Query OpenSpec state via CLI or direct file read
- Query beads state via CLI
- Compute current phase from combined state
- Present actionable resume point

**Non-Goals:**
- Modifying beads or OpenSpec state (read-only)
- Auto-advancing phases (user confirms)
- Creating new changes or beads

## Decisions

### 1. Query Strategy
**Decision**: Use CLI tools (`openspec` and `bd`) for state queries.

**Rationale**: CLI is the primary interface, simpler than programmatic APIs.

**Alternatives considered**:
- Direct file parsing - more fragile, may not match CLI output
- SDK integration - adds complexity, overkill for read-only queries

### 2. Phase Computation Logic
**Decision**: Use artifact dependency order to determine phase.

**Rationale**: Phase is the first incomplete artifact in dependency order.

**Alternatives considered**:
- Use bead type directly - may not match artifact state
- Use most recent timestamp - can be misleading

### 3. Resume Format
**Decision**: Present structured information: current phase, what's ready, what's blocked.

**Rationale**: Actionable information helps user resume quickly.

**Alternatives considered**:
- Single sentence - too terse
- Full dump - overwhelming

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|------------|
| CLI output format changes | Skill breaks | Pin CLI versions, test on updates |
| Missing beads or OpenSpec | Can't determine phase | Graceful fallback with warnings |
| Multiple in-progress artifacts | Ambiguous phase | Use earliest in dependency order |

## Open Questions

1. Should skill auto-invoke on session start or require invocation?
2. How to handle multiple concurrent changes?
3. What commands should be available besides "resume"?
