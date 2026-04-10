# Beads Skill Definitions for hbohlen-systems

## Introduction

This document defines six skill domains for using beads (`bd`) within the hbohlen-systems NixOS configuration repository. Each skill domain provides targeted guidance for AI agents, focusing on practical usage patterns, integration with project workflows, and best practices.

### Project Context
- **Beads Version**: v0.63.3 via `llm-agents.nix` flake input
- **Access**: Available via `nix develop .#ai --command bd --help`
- **Integration**: Part of AI-DLC and Spec-driven development workflow
- **Storage**: Database committed to git (user preference)

### Key Principles for AI Agents
1. **Always use `--json` flag** for programmatic access and parsing
2. **Always run `bd sync`** at end of work session (critical for data preservation)
3. **Start with `bd ready`** to find unblocked work before starting
4. **Track discoveries** with `--deps discovered-from:<parent>` when finding new work
5. **Use formulas** for repetitive project workflows (NixOS modules, Specs)

---

## Skill 1: Core Issue Management

### Purpose and Scope
Manage the basic issue lifecycle: creation, viewing, updating, and closing issues. This skill forms the foundation of all beads workflows.

### Essential Commands (Always with `--json`)

```bash
# Create issues (always include description for context)
bd create "Implement NixOS module for service X" \
  -t task -p 2 \
  --description "Create a NixOS module that provides service X with configuration options" \
  --json

# List and filter issues
bd list --status open --priority "0,1,2" --type "task,feature" --json
bd list --label-any "nixos,spec" --json
bd search "authentication" --status open --json

# View issue details
bd show bd-a1b2 --json
bd show bd-a1b2 --full --json  # Includes comments

# Update issues (claim work, modify fields)
bd update bd-a1b2 --claim --json
bd update bd-a1b2 --priority 0 --add-label "urgent,security" --json
bd update bd-a1b2 --title "Updated: Implement auth module" --description "Revised scope..." --json

# Close issues (always provide reason)
bd close bd-a1b2 --reason "Implemented in PR #123, tested on staging" --json
bd reopen bd-a1b2 --json  # Reopen if needed
```

### Common Patterns and Best Practices

**Daily Workflow Pattern:**
```bash
# Start of session: Find ready work
READY_ISSUES=$(bd ready --json | jq -r '.[].id')
if [ -n "$READY_ISSUES" ]; then
  FIRST_ISSUE=$(echo "$READY_ISSUES" | head -1)
  bd update $FIRST_ISSUE --claim --json
  echo "Claimed issue: $FIRST_ISSUE"
else
  echo "No ready work. Check blocked issues or create new work."
fi

# During work: Regular updates
bd update $ISSUE_ID --add-label "in-progress" --json

# Completion: Close with detailed reason
bd close $ISSUE_ID --reason "Implemented with tests, documented in README" --json
```

**Issue Creation Best Practices:**
- Always include `--description` with sufficient context for future agents
- Use appropriate issue types: `task` (implementation), `feature` (new functionality), `bug` (defects), `epic` (large features), `chore` (maintenance)
- Set realistic priorities: 0 (critical), 1 (high), 2 (normal), 3 (low), 4 (backlog)
- Apply 2-4 relevant labels for filtering

### Integration with Project Workflows

**Kiro Spec Integration:**
```bash
# Spec creation → beads epic
bd create "Feature: Multi-agent coordination system" \
  -t epic -p 1 \
  --description "Spec for multi-agent coordination using beads routing" \
  --label "spec,multi-agent" \
  --json

# Kiro task generation → beads subtasks
bd create "Design routing configuration format" \
  --parent bd-epic-id \
  -t task -p 2 \
  --description "Design TOML/JSON format for .beads/routes.jsonl" \
  --label "spec-design" \
  --json
```

**NixOS Module Development:**
```bash
# NixOS module issue
bd create "Create NixOS module for tailscale" \
  -t task -p 2 \
  --description "Implement tailscale.nix module with auth key management" \
  --label "nixos-module,security,networking" \
  --json
```

### Potential Pitfalls and Troubleshooting

1. **Missing `--json` flag**: Causes output formatting issues for AI parsing
   - **Fix**: Always include `--json` for programmatic access

2. **Insufficient description**: Makes issues hard to understand later
   - **Fix**: Always provide detailed `--description` including context, requirements, references

3. **Wrong issue type**: Confuses workflow tracking
   - **Fix**: Use consistent types: `task` for implementation work, `feature` for new capabilities, `bug` for fixes

4. **Forgetting to claim work**: Multiple agents might work on same issue
   - **Fix**: Always use `bd update <id> --claim --json` when starting work

---

## Skill 2: Dependency Management

### Purpose and Scope
Manage relationships between issues to enable dependency-aware execution. This skill ensures agents work on unblocked tasks and maintain proper issue hierarchies.

### Essential Commands

```bash
# Add dependencies
bd dep add bd-child bd-parent --type blocks  # Hard dependency (default)
bd dep add bd-related bd-source --type related  # Soft relationship
bd dep add bd-discovered bd-origin --type discovered-from  # Discovery tracking

# Remove dependencies
bd dep remove bd-child bd-parent

# View dependency structures
bd dep tree bd-epic-id --depth 3 --json
bd dep tree bd-epic-id --direction upstream --json  # What blocks this
bd dep tree bd-epic-id --direction downstream --json  # What this blocks

# Find circular dependencies
bd dep cycles --json

# Find ready and blocked work
bd ready --priority "0,1,2" --json
bd blocked --json
bd blocked --by bd-a1b2 --json  # What blocks specific issue
```

### Common Patterns and Best Practices

**Dependency-Aware Workflow:**
```bash
# Before starting work, check if ready
READY_CHECK=$(bd ready --json | jq -r 'length')
if [ "$READY_CHECK" -eq 0 ]; then
  BLOCKED_ISSUES=$(bd blocked --json | jq -r '.[].id')
  echo "No ready work. Blocked issues: $BLOCKED_ISSUES"
  # Optionally work on unblocking dependencies
else
  ISSUE_ID=$(bd ready --json | jq -r '.[0].id')
  echo "Starting work on: $ISSUE_ID"
  bd update $ISSUE_ID --claim --json
fi
```

**Hierarchical Issue Management (Epics):**
```bash
# Create epic (returns ID like bd-a3f8e9)
EPIC_ID=$(bd create "Auth system overhaul" -t epic -p 1 --json | jq -r '.id')

# Create auto-numbered subtasks
bd create "Design new auth flow" --parent $EPIC_ID -t task --json  # Becomes bd-a3f8e9.1
bd create "Implement OAuth2 provider" --parent $EPIC_ID -t task --json  # bd-a3f8e9.2
bd create "Update documentation" --parent $EPIC_ID -t task --json  # bd-a3f8e9.3

# View epic structure
bd dep tree $EPIC_ID --json
```

**Discovery Tracking:**
```bash
# When discovering new work during implementation
bd create "Found race condition in auth cache" \
  -t bug -p 0 \
  --description "Race condition between cache invalidation and auth checks" \
  --deps discovered-from:bd-current-issue \
  --json
```

### Integration with Project Workflows

**Kiro Spec Dependency Chain:**
```bash
# Spec phases as dependencies
REQUIREMENTS_ID=$(bd create "Requirements analysis" --parent $EPIC_ID --json | jq -r '.id')
DESIGN_ID=$(bd create "System design" --parent $EPIC_ID --json | jq -r '.id')
IMPLEMENTATION_ID=$(bd create "Implementation" --parent $EPIC_ID --json | jq -r '.id')

# Set phase dependencies
bd dep add $DESIGN_ID $REQUIREMENTS_ID --type blocks
bd dep add $IMPLEMENTATION_ID $DESIGN_ID --type blocks

# Only requirements is initially ready
bd ready --json  # Shows only requirements issue
```

**NixOS Module Dependencies:**
```bash
# Module dependencies
BD_NIXPKGS=$(bd create "Update nixpkgs input" -t task --label "flake-update" --json | jq -r '.id')
BD_MODULE=$(bd create "Implement new module" -t task --label "nixos-module" --json | jq -r '.id')
BD_TEST=$(bd create "Test module" -t task --label "testing" --json | jq -r '.id')

# Dependency chain
bd dep add $BD_MODULE $BD_NIXPKGS  # Module depends on nixpkgs update
bd dep add $BD_TEST $BD_MODULE     # Testing depends on module
```

### Potential Pitfalls and Troubleshooting

1. **Circular dependencies**: Cause deadlocks where no work is ready
   - **Detection**: `bd dep cycles --json`
   - **Fix**: Break cycle by changing dependency type or restructuring

2. **Missing `discovered-from` tracking**: Lose context of how work was found
   - **Fix**: Always use `--deps discovered-from:<parent>` for discovered work

3. **Over-blocking**: Making everything block everything else
   - **Fix**: Use appropriate dependency types: `blocks` for hard dependencies, `related` for soft links

4. **Epic explosion**: Too many levels of hierarchy
   - **Fix**: Keep epics to 2-3 levels max; use labels for additional categorization

---

## Skill 3: Sync & Data Management

### Purpose and Scope
Manage database synchronization, data integrity, and integration with git. This skill is critical for data preservation and collaboration.

### Essential Commands

```bash
# CRITICAL: Always sync at end of work session
bd sync

# Export/Import for backup and migration
bd export -o beads-backup-$(date +%Y%m%d).jsonl
bd import -i beads-backup.jsonl --orphan-handling resurrect

# Git hook management
bd hooks install  # Install git hooks for auto-sync
bd hooks status --json
bd hooks uninstall

# Database maintenance and health checks
bd doctor --fix
bd doctor --verbose --json

# Migration between versions
bd migrate --inspect --json
bd migrate --dry-run --json
bd migrate --cleanup --json

# System information
bd info --json
bd stats --json
bd version --json
```

### Common Patterns and Best Practices

**Session Management Workflow:**
```bash
# Start of session
bd prime  # Get AI-optimized context
bd info --whats-new --json  # Check for updates

# During session - regular work
# ... issue management commands ...

# End of session (MANDATORY)
bd sync
echo "Session sync complete. Database committed and pushed."

# Optional: Create backup
bd export -o session-backup-$(date +%Y%m%d-%H%M%S).jsonl
```

**Git Integration Workflow:**
```bash
# Initialize with git integration
bd init --branch beads-sync --quiet

# Install hooks (recommended for auto-sync)
bd hooks install

# Worktree awareness (automatic)
# When working in git worktrees, beads auto-uses embedded mode

# Conflict resolution after git merges
bd doctor --fix
```

**Backup Strategy:**
```bash
# Daily backup script
BACKUP_FILE="beads-backup-$(date +%Y%m%d).jsonl"
bd export -o $BACKUP_FILE
gzip $BACKUP_FILE
# Upload to backup storage...

# Restore from backup
gunzip beads-backup-20250409.jsonl.gz
bd import -i beads-backup-20250409.jsonl --orphan-handling resurrect
```

### Integration with Project Workflows

**NixOS CI/CD Integration:**
```bash
# In CI pipeline - sandbox mode for ephemeral environments
bd --sandbox list --json
bd --sandbox ready --json

# Export results from CI run
bd --sandbox export -o ci-results.jsonl

# Import into main database
bd import -i ci-results.jsonl --orphan-handling allow
```

**Kiro Spec Data Management:**
```bash
# Export Spec issues for review
bd export --label spec -o spec-review.jsonl

# Import updated spec
bd import -i updated-spec.jsonl --orphan-handling strict
```

### Potential Pitfalls and Troubleshooting

1. **Forgetting `bd sync`**: Risk of data loss
   - **Prevention**: Make `bd sync` last command in agent session
   - **Recovery**: Check if unsynced data exists with `bd info --json`

2. **Git merge conflicts** in beads data
   - **Detection**: `bd doctor` will report conflicts
   - **Resolution**: `bd doctor --fix` or manual conflict resolution

3. **Database corruption**
   - **Prevention**: Regular backups with `bd export`
   - **Recovery**: Restore from backup or use `bd doctor --fix`

4. **Hook failures**
   - **Diagnosis**: `bd hooks status --json`
   - **Fix**: Reinstall with `bd hooks install --force`

---

## Skill 4: Workflow Orchestration

### Purpose and Scope
Use formulas, molecules, gates, and wisps for complex, repeatable workflows. This skill enables automation of common project tasks.

### Essential Commands

```bash
# Formula management
bd pour nixos-module --var name="tailscale" --var description="VPN mesh" --json
bd pour --dry-run spec --var feature="auth" --json  # Preview

# Molecule management
bd mol list --json
bd mol show mol-abc123 --json
bd mol archive mol-abc123 --json  # Archive completed molecule

# Gate management
bd gate approve gate-xyz --approver "ai-agent" --json
bd gate skip gate-xyz --reason "Emergency deployment" --json
bd show gate-xyz --json  # Check gate status

# Wisp management (ephemeral)
bd wisp create quick-test --var test="integration" --json
bd wisp update wisp-abc.1 --claim --json
bd wisp close wisp-abc.1 --json
```

### Common Patterns and Best Practices

**Formula Lifecycle:**
```toml
# Example: .beads/formulas/nixos-module.toml
formula = "nixos-module"
description = "Create a NixOS module"
version = "1.0.0"
type = "workflow"

[vars]
name = { required = true, pattern = "^[a-z][a-z0-9-]*$" }
description = { required = true, default = "NixOS module" }

[[steps]]
id = "create-module"
title = "Create module {{.name}}"
type = "task"
description = "Create NixOS module {{.name}}"

[[steps]]
id = "add-options"
title = "Add configuration options"
type = "task"
description = "Add NixOS options for {{.name}}"
needs = ["create-module"]

[[steps]]
id = "document"
title = "Document module"
type = "task"
description = "Add documentation for {{.name}}"
needs = ["add-options"]
```

**Molecule Execution:**
```bash
# Create molecule from formula
MOL_ID=$(bd pour nixos-module --var name="tailscale" --json | jq -r '.id')

# Work through steps
bd update $MOL_ID.1 --claim --json  # Step 1: create-module
# ... implement ...
bd close $MOL_ID.1 --reason "Module structure created" --json

bd ready --json  # Now shows $MOL_ID.2 (add-options)
bd update $MOL_ID.2 --claim --json
# ... continue ...
```

**Gate Coordination:**
```bash
# Human approval gate
GATE_ID=$(bd show $MOL_ID.3 --json | jq -r '.gate')  # Get gate ID from step
bd gate approve $GATE_ID --approver "ai-agent" --json

# Timer gate (auto-progresses after time)
# Check if timer expired
bd show $GATE_ID --json | jq -r '.status'

# GitHub gate (waits for CI)
# Gate auto-closes when CI passes
```

### Integration with Project Workflows

**NixOS Module Creation Workflow:**
```bash
# Complete module creation workflow
bd pour nixos-module \
  --var name="postgresql-ha" \
  --var description="High-availability PostgreSQL cluster" \
  --json

# Results in molecule with steps:
# 1. create-module (task)
# 2. add-options (task) 
# 3. document (task)
# 4. test (gate - human approval)
# 5. merge (task)
```

**Kiro Spec Execution Workflow:**
```bash
# Spec as formula
bd pour spec \
  --var feature="multi-agent-routing" \
  --var phase="implementation" \
  --json

# Steps might include:
# 1. requirements-review (gate)
# 2. design-approval (gate)
# 3. implementation (task)
# 4. validation (task)
# 5. deployment (gate)
```

**CI/CD Pipeline as Formula:**
```toml
# .beads/formulas/nixos-test.toml
formula = "nixos-test"
description = "Test NixOS configuration"
version = "1.0.0"

[[steps]]
id = "build"
title = "Build configuration"
type = "task"

[[steps]]
id = "test-vm"
title = "Test in VM"
type = "task"
needs = ["build"]

[[steps]]
id = "deploy-approval"
title = "Deployment approval"
type = "gate"
gate_type = "human"
approvers = ["lead-engineer"]
needs = ["test-vm"]
```

### Potential Pitfalls and Troubleshooting

1. **Formula validation errors**
   - **Diagnosis**: `bd pour --dry-run` shows errors
   - **Fix**: Check TOML syntax and variable definitions

2. **Stuck gates**
   - **Check**: `bd show <gate-id> --json`
   - **Bypass**: `bd gate skip <gate-id> --reason "Emergency" --json`

3. **Molecule step dependencies wrong**
   - **Check**: `bd mol show <mol-id> --json` shows dependency graph
   - **Fix**: May need to recreate molecule with corrected formula

4. **Wisp data loss** (by design)
   - **Note**: Wisps are ephemeral and don't sync
   - **Workaround**: Export important wisp results with `bd wisp export`

---

## Skill 5: Multi-agent Coordination

### Purpose and Scope
Coordinate work between multiple AI agents using routing, pinning, and coordination patterns. This skill enables scalable multi-agent workflows.

### Essential Commands

```bash
# Routing configuration
bd route add "frontend/**" --destination "frontend-repo" --priority 2 --json
bd route list --json
bd route remove "frontend/**" --json

# Work assignment (pinning)
bd pin bd-a1b2 --for frontend-agent --start --json
bd pin bd-a1b2 --release --json  # Release when done
bd hook --json  # Show pinned work for current agent

# Agent coordination
bd audit --json  # Record agent interactions
bd reserve path/to/file --for agent-name --json  # File reservation
bd reserve --release path/to/file --json  # Release reservation

# Cross-repo dependencies
bd dep add bd-repo1-issue bd-repo2-issue --cross-repo --json
```

### Common Patterns and Best Practices

**Routing Configuration:**
```json
// .beads/routes.jsonl
{"route": "nixos/**", "destination": "hbohlen-systems", "priority": 1}
{"route": "home-manager/**", "destination": "hbohlen-systems", "priority": 2}
{"route": "docs/**", "destination": "hbohlen-systems", "priority": 3}
{"route": "frontend/**", "destination": "frontend-repo", "priority": 2, "agent": "frontend-agent"}
{"route": "backend/**", "destination": "backend-repo", "priority": 2, "agent": "backend-agent"}
```

**Agent Work Assignment:**
```bash
# Agent startup sequence
AGENT_NAME="nixos-agent"
bd prime --agent $AGENT_NAME

# Check for assigned work
PinnedWork=$(bd hook --json | jq -r '.[].id')
if [ -n "$PinnedWork" ]; then
  echo "Found pinned work: $PinnedWork"
  bd update $PinnedWork --claim --json
else
  # Find routable work
  AvailableWork=$(bd ready --route "nixos/**" --json | jq -r '.[0].id')
  if [ -n "$AvailableWork" ]; then
    bd pin $AvailableWork --for $AGENT_NAME --start --json
    bd update $AvailableWork --claim --json
  fi
fi
```

**Coordination Patterns:**

1. **Sequential Handoff**:
   ```bash
   # Agent A completes work
   bd close $ISSUE_A --reason "Implemented, ready for Agent B" --json
   
   # Creates gate for Agent B
   # Agent B checks for gates assigned to them
   bd ready --gate --json
   ```

2. **Parallel Work**:
   ```bash
   # Create epic with subtasks
   EPIC_ID=$(bd create "Performance optimization" -t epic --json | jq -r '.id')
   
   # Parallel subtasks (no dependencies between them)
   bd create "Optimize database queries" --parent $EPIC_ID --json
   bd create "Cache implementation" --parent $EPIC_ID --json
   bd create "Frontend bundler optimization" --parent $EPIC_ID --json
   
   # Multiple agents can work in parallel
   ```

3. **Fan-out/Fan-in**:
   ```bash
   # Agent 1: Creates multiple subtasks (fan-out)
   for SUBTASK in "task1" "task2" "task3"; do
     bd create "$SUBTASK" --parent $EPIC_ID --json
   done
   
   # Multiple agents work on subtasks in parallel
   # Agent 2: Waits for all subtasks, integrates (fan-in)
   bd create "Integration" --parent $EPIC_ID --json
   # Set dependencies: integration blocks all subtasks
   ```

### Integration with Project Workflows

**Project Agent Infrastructure:**
```bash
# Integration with tmux worktrees
# agent-menu already manages worktrees
# beads can integrate by checking current worktree

# Agent coordination through existing infrastructure
# 1. agent-menu creates worktree
# 2. beads checks worktree context
# 3. beads routes work to appropriate agent/worktree
# 4. Progress tracked through beads issues
```

**NixOS Multi-agent Testing:**
```bash
# Route NixOS testing work
bd route add "nixos-test/**" --destination "test-agent" --priority 1 --json

# Test agent picks up work
bd ready --route "nixos-test/**" --json
```

### Potential Pitfalls and Troubleshooting

1. **Routing conflicts**: Multiple routes match same issue
   - **Resolution**: Routes evaluated in order; first match wins
   - **Fix**: Order routes from specific to general

2. **Agent contention**: Multiple agents try to claim same work
   - **Prevention**: Use `bd pin --start` to formally assign
   - **Detection**: `bd hook` shows current pins

3. **Cross-repo dependency breaks**: Target repo unavailable
   - **Detection**: `bd doctor` reports cross-repo issues
   - **Workaround**: Use local issues with detailed references

4. **File reservation conflicts**
   - **Check**: `bd reserve --status path/to/file --json`
   - **Resolution**: Wait for release or negotiate with reserving agent

---

## Skill 6: Configuration & Advanced

### Purpose and Scope
Configure beads for project-specific needs and use advanced features. This skill optimizes beads for the hbohlen-systems environment.

### Essential Commands

```bash
# Configuration management
bd config get --json
bd config set database.path ".beads/db" --json
bd config set dolt.auto_commit "on" --json

# Backend management
bd backend list --json
bd backend switch dolt --json
bd backend status --json

# Performance and optimization
bd stats --json  # Database statistics
bd profile --json  # Performance profiling

# Advanced querying
bd query 'priority = 0 AND status = "open"' --json
bd query 'labels @> ["security"] AND updated_at > "2026-04-01"' --json

# Maintenance operations
bd vacuum --json  # Clean up database
bd reindex --json  # Rebuild indexes
```

### Common Patterns and Best Practices

**Project Configuration (config.toml):**
```toml
# .beads/config.toml
[database]
backend = "dolt"
path = ".beads/dolt"  # User prefers git-tracked

[dolt]
auto_commit = "on"
remote = "origin"
branch = "beads-sync"
commit_author = "AI Agent <agent@hbohlen-systems>"

[git]
worktree_aware = true
protected_branches = ["main", "master"]
hooks = true

[hooks]
pre_commit = ["bd sync"]
post_merge = ["bd sync --import"]
pre_push = ["bd sync"]

[agent]
name = "ai-agent"
sandbox = false
readonly = false
audit = true

[performance]
concurrent_nix_builds = 4
cache_warming = true
query_cache_size = "100MB"

[storage]
compression = "zstd"
auto_vacuum = "on"

# NixOS-specific
[nixos]
module_pattern = "**/nixos/**"
home_manager_pattern = "**/home-manager/**"
flake_pattern = "**/flake.nix"
```

**NixOS Optimization:**
```bash
# Configure for Nix build environment
bd config set performance.concurrent_nix_builds $(nproc) --json
bd config set storage.compression "zstd" --json

# Monitor performance
bd stats --json | jq '.performance'
bd profile --duration 30s --json  # Profile for 30 seconds
```

**Advanced Query Patterns:**
```bash
# Find security issues needing attention
bd query 'priority = 0 AND labels @> ["security"] AND status = "open"' --json

# Find stale issues (not updated in 7 days)
bd query 'updated_at < date("now", "-7 days") AND status = "open"' --json

# Find issues with specific dependency patterns
bd query 'EXISTS (SELECT 1 FROM dependencies WHERE type = "blocks")' --json

# Complex Spec queries
bd query 'labels @> ["spec"] AND created_at > date("now", "-30 days")' --json
```

### Integration with Project Workflows

**NixOS-Specific Configuration:**
```bash
# Set up for hbohlen-systems environment
bd config set nixos.module_path "./nixos" --json
bd config set nixos.home_manager_path "./home" --json
bd config set git.protected_branches "[\"main\"]" --json

# Configure audit trail for AI agents
bd config set agent.audit true --json
bd config set agent.name "$AGENT_NAME" --json
```

**Performance Monitoring:**
```bash
# Regular health checks
bd doctor --json | jq -r '.health.status'

# Database statistics
bd stats --json | jq '
  {
    total_issues: .issues.total,
    open_issues: .issues.open,
    avg_priority: .issues.avg_priority,
    db_size_mb: .database.size_mb
  }
'

# Performance profiling during heavy loads
bd profile --json > profile-$(date +%s).json
```

### Potential Pitfalls and Troubleshooting

1. **Configuration drift**: Different agents have different configs
   - **Prevention**: Commit `.beads/config.toml` to git
   - **Check**: `bd config get --json` and compare

2. **Performance degradation** with large database
   - **Diagnosis**: `bd stats --json` shows size and indexes
   - **Fix**: `bd vacuum --json` and `bd reindex --json`

3. **Backend issues** (Dolt problems)
   - **Diagnosis**: `bd backend status --json`
   - **Recovery**: `bd doctor --fix` or switch backend temporarily

4. **Query performance issues**
   - **Diagnosis**: `bd profile --json` during slow queries
   - **Fix**: Add indexes or simplify query patterns

---

## Summary and Quick Reference

### Skill Dependencies
```
Core Issue Management
    ↓
Dependency Management
    ↓
Sync & Data Management
    ↓
Workflow Orchestration ← Multi-agent Coordination
    ↓
Configuration & Advanced
```

### Critical Commands (Always Remember)
1. `bd ready --json` - Find unblocked work
2. `bd sync` - Sync at session end (MANDATORY)
3. `bd update <id> --claim --json` - Claim work
4. `bd close <id> --reason "..." --json` - Complete work
5. `bd create ... --deps discovered-from:<parent> --json` - Track discoveries

### Project Integration Checklist
- [ ] Beads initialized in project: `bd init --quiet`
- [ ] Git hooks installed: `bd hooks install`
- [ ] Configuration committed: `.beads/config.toml` in git
- [ ] NixOS patterns configured in routes
- [ ] Spec labels defined
- [ ] Agent coordination setup complete

### Troubleshooting Matrix
| Symptom | Likely Cause | First Action |
|---------|--------------|--------------|
| No ready work | All issues blocked | Check `bd blocked --json` |
| Sync fails | Git issues or conflicts | Run `bd doctor --fix` |
| JSON parse errors | Missing `--json` flag | Add `--json` to command |
| Permission errors | Database locked | Check if another agent is working |
| Slow performance | Large database | Run `bd vacuum --json` |

---
*Skill definitions for beads v0.63.3 in hbohlen-systems NixOS configuration repository. These skills enable AI agents to effectively use beads for issue tracking, dependency management, and workflow orchestration within the project's AI-DLC and Spec-driven development workflow.*