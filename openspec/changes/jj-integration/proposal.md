## Why

The workflow orchestrator needs to integrate Jujutsu (jj) as the version control layer alongside beads (issue tracking), OpenSpec (spec-driven development), and pi (AI coding agent). jj provides a superior experience for AI-assisted development with its undo capabilities, conflict resolution, and immutable history—but we need to establish how it interacts with beads for tracking and pi for execution.

## What Changes

- Add jj as the primary VCS layer with git interoperability
- Create jj-based workflows for session management and branch handling
- Integrate jj operations with beads for persistent tracking
- Define how pi leverages jj for worktree isolation and change management

## Capabilities

### New Capabilities

- **jj-workflows**: Define jj commands and patterns for the workflow orchestrator (branch creation, session isolation, sync with git)
- **jj-beads-integration**: Track jj operations (describe, log, diff) in beads for audit and resume
- **jj-pi-integration**: How pi uses jj for worktrees, change tracking, and session resume

### Modified Capabilities

- (none yet - this is the initial spec-driven setup)

## Impact

- New directory: `docs/superpowers/research/jj-integration/`
- New jj configuration files
- Potential skill updates for jj-aware operations
