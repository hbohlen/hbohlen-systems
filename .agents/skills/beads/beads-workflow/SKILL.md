---
name: beads-workflow
description: Execute daily beads operations — find ready work, claim issues, close completed tasks, and sync. Use when working with the beads issue tracker during development sessions.
tags: [beads, workflow, issue-tracking, daily]
category: beads
metadata:
  version: "1.0"
  source: .agents/
---

# beads-workflow

Execute daily beads operations for issue tracking and work coordination.

## Overview

Beads (`bd`) is a git-backed, AI-native issue tracker using Dolt as its backend. This skill guides the core daily workflow: finding ready work, claiming issues, updating progress, closing completed tasks, and syncing changes.

**Key principle**: Always use `--json` for programmatic access by agents.

## When to Use

- Starting a work session (find what's ready to do)
- During implementation (update issues, track progress)
- Completing work (close with detailed reason)
- Ending a session (sync to preserve changes)

## Daily Session Workflow

### Session Start: Find Ready Work

```bash
# Get list of unblocked issues
bd ready --json

# Example output interpretation:
# [
#   {"id": "bd-a1b2", "title": "Implement feature X", "priority": 1, "status": "open"},
#   {"id": "bd-c3d4", "title": "Fix bug Y", "priority": 0, "status": "open"}
# ]

# Select and claim first ready issue
ISSUE=$(bd ready --json | jq -r '.[0].id')
bd update $ISSUE --claim --json
```

### Session Middle: Work and Update

```bash
# Show current issue details
bd show $ISSUE --json

# Update issue during work
bd update $ISSUE --title "Updated: New findings" --json

# If you discover new work during implementation
bd create "Found: SQL injection in auth.go:45" \
  -t bug -p 0 \
  --description "Critical security issue discovered during implementation" \
  --deps discovered-from:$ISSUE \
  --json

# Add labels as needed
bd update $ISSUE --add-label "in-progress,security" --json
```

### Session End: Close and Sync

```bash
# Close completed issue with detailed reason
bd close $ISSUE \
  --reason "Implemented feature with tests and documentation. PR #123. Ready for review." \
  --json

# CRITICAL: Always sync at session end
bd sync
```

## Common Operations

### Finding Work

```bash
# Find all unblocked, ready issues
bd ready --json

# Find issues blocked by dependencies
bd blocked --json

# Search for specific issues
bd search "authentication" --status open --json
bd list --label-any "nixos,urgent" --priority "0,1" --json
```

### Issue Lifecycle

```bash
# Create new issue
bd create "Implement NixOS module for X" \
  -t task \
  -p 2 \
  --description "Create a reusable NixOS module that provides X service with configuration" \
  --label "nixos,feature" \
  --json

# View full issue (including comments)
bd show bd-a1b2 --full --json

# Update fields
bd update bd-a1b2 \
  --title "Updated title" \
  --priority 1 \
  --add-label "urgent" \
  --json

# Close with reason
bd close bd-a1b2 \
  --reason "Completed and merged in PR #456. Tested on staging." \
  --json

# Reopen if needed
bd reopen bd-a1b2 --reason "Issue reoccurred in production" --json
```

### Dependency Management

```bash
# View dependency tree
bd dep tree bd-a1b2 --depth 3 --json

# Add dependency
bd dep add bd-b2c3 bd-a1b2  # bd-b2c3 depends on bd-a1b2

# Check for circular dependencies
bd dep cycles --json
```

### Sync and Data Integrity

```bash
# Check health
bd doctor --json
bd doctor --fix  # Auto-fix common issues

# Full sync (run at session end)
bd sync

# Export for backup
bd export -o backup.jsonl

# Import from backup
bd import -i backup.jsonl --orphan-handling resurrect
```

## Integration Patterns

### Kiro Spec-Driven Development

Map Kiro phases to beads operations:

```bash
# Start: Create epic for spec
bd create "Feature: User authentication system" \
  -t epic -p 1 \
  --description "Implement OAuth2-based authentication with session management" \
  --label "kiro-spec,feature" \
  --json

EPIC_ID="bd-xxxx"  # Save this ID

# During: Create subtasks for each phase
bd create "Design: Authentication flow" \
  --parent $EPIC_ID \
  -t task -p 2 \
  --label "kiro-design" \
  --json

bd create "Implement: OAuth provider integration" \
  --parent $EPIC_ID \
  -t task -p 2 \
  --label "kiro-implementation" \
  --json

# End: Close epic when all subtasks done
bd close $EPIC_ID --reason "All authentication features implemented and tested" --json
```

### NixOS Module Development

```bash
# Create module task
bd create "NixOS module: Tailscale integration" \
  -t task -p 2 \
  --description "Implement tailscale.nix with automatic key injection from 1Password" \
  --label "nixos-module,networking,security" \
  --json

# During development: Track discoveries
bd create "Discovered: Need Home Manager integration for user keys" \
  -t task -p 2 \
  --deps discovered-from:bd-original-task \
  --label "nixos-module" \
  --json
```

## Best Practices for AI Agents

### 1. Always Use `--json`

```bash
# ✅ GOOD: Programmatic parsing
bd ready --json | jq -r '.[].id'

# ❌ BAD: Human-readable, not parseable by agents
bd ready
```

### 2. Provide Comprehensive Descriptions

```bash
# ✅ GOOD: Context for future agents/humans
bd create "Implement rate limiting middleware" \
  --description "Add rate limiting to prevent brute force attacks on /api/auth. \
Requires: token bucket algorithm, Redis backend, configurable limits per endpoint. \
Reference: OWASP rate limiting best practices." \
  --json

# ❌ BAD: Insufficient context
bd create "Add rate limiting" --json
```

### 3. Claim Work Explicitly

```bash
# Always claim before starting work
bd update $ISSUE --claim --json

# Prevents multiple agents working on same issue
```

### 4. Track Dependencies for Discoveries

```bash
# When discovering new work during implementation
bd create "Found: Missing error handling in auth" \
  -t bug -p 1 \
  --deps discovered-from:$PARENT_ISSUE \
  --description "Error handling missing in login endpoint, needs immediate fix" \
  --json
```

### 5. Detailed Close Reasons

```bash
# ✅ GOOD: Helps future debugging and auditing
bd close $ISSUE \
  --reason "Implemented with full test coverage (98%). \
Tests: test_login_valid_credentials, test_login_invalid_password, test_rate_limiting. \
Documentation: Updated README.md section 4.2. \
PR: #789, merged and deployed to staging 2026-04-09." \
  --json

# ❌ BAD: Insufficient detail
bd close $ISSUE --reason "Done" --json
```

## Workflow Patterns for Complexity

### Multi-Phase Coordination

For work spanning multiple phases (requirements → design → implementation → testing):

```bash
# Create parent epic
EPIC=$(bd create "Major Feature: Multi-region replication" \
  -t epic -p 1 --label "spec-phase" --json | jq -r '.id')

# Create phase tasks
bd create "Phase 1: Requirements and design review" --parent $EPIC -t task -p 2 --json
bd create "Phase 2: Core implementation" --parent $EPIC -t task -p 2 --json
bd create "Phase 3: Testing and hardening" --parent $EPIC -t task -p 2 --json

# Set dependencies between phases
PHASE1=$(bd list --parent $EPIC --json | jq -r '.[0].id')
PHASE2=$(bd list --parent $EPIC --json | jq -r '.[1].id')
PHASE3=$(bd list --parent $EPIC --json | jq -r '.[2].id')

bd dep add $PHASE2 $PHASE1
bd dep add $PHASE3 $PHASE2

# Work through phases sequentially
bd update $PHASE1 --claim --json
# ... complete phase 1 ...
bd close $PHASE1 --reason "Requirements documented and approved" --json

# Now $PHASE2 becomes ready
bd ready --json  # Shows $PHASE2
```

### Blocking Issue Handling

When you encounter blockers:

```bash
# Check what's blocking current work
bd dep tree $ISSUE --json

# If blocker is missing, create it
BLOCKER=$(bd create "Blocker: Database schema migration needed" \
  -t task -p 1 --json | jq -r '.id')

# Mark current issue as depending on blocker
bd dep add $ISSUE $BLOCKER --json

# Check blocked status
bd blocked --json  # $ISSUE will appear here

# When blocker is resolved, $ISSUE becomes ready
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `bd ready` returns empty but work exists | Run `bd doctor --fix` to repair dependencies. Check `bd blocked` for issues with unmet dependencies. |
| Merge conflicts in beads database | Run `bd sync`, then `bd doctor --fix`. If persists, see dolt-operations skill. |
| Issue won't close | Check for open dependencies: `bd dep tree $ISSUE` |
| Data seems stale | Run `bd sync` to pull latest from remote. |
| Can't claim issue | Issue may be claimed by another agent. Run `bd show $ISSUE` to check owner. |

## See Also

- [`dolt-operations`](../dolt-operations/SKILL.md) — Direct database operations (schema inspection, SQL queries)
- **Reference docs** in `.agents/skills/beads/`: core.md, config.md, sync.md, dependencies.md, workflows.md, multi-agent.md
- **Knowledge base**: `docs/beads/beads-knowledge-base.md` — comprehensive beads guide
