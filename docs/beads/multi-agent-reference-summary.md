# Beads Multi-Agent and Reference Documentation Summary

This document summarizes the key features, configuration options, and integration patterns for Beads multi-agent coordination and reference documentation. Beads is an AI-friendly issue tracker using Dolt (version-controlled SQL database) as its backend, with deep Git integration and multi-agent coordination capabilities.

## Table of Contents

1. [Multi-Agent Features Overview](#1-multi-agent-features-overview)
2. [Routing and Coordination Patterns](#2-routing-and-coordination-patterns)
3. [Configuration (config.toml, Backend Setup)](#3-configuration-configtoml-backend-setup)
4. [Git Integration (Hooks, Worktrees, Branching)](#4-git-integration-hooks-worktrees-branching)
5. [Advanced Features and Best Practices](#5-advanced-features-and-best-practices)
6. [Integration with Project Agent Infrastructure](#6-integration-with-project-agent-infrastructure)
7. [NixOS-specific Configuration Considerations](#7-nixos-specific-configuration-considerations)
8. [References](#references)
9. [Conclusion](#conclusion)

## 1. Multi-Agent Features Overview

Beads supports coordination between multiple AI agents and repositories with the following features:

### Core Multi-Agent Capabilities
- **Routing**: Automatic issue routing to correct repositories based on pattern matching
- **Cross-repo dependencies**: Track dependencies across repository boundaries
- **Agent coordination**: Work assignment and handoff between agents
- **Conflict prevention**: File reservations and issue locking for concurrent access
- **Agent discovery**: Find available agents and check their status

### Architecture Pattern
```
┌─────────────────┐
│   Main Repo     │
│   (coordinator) │
└────────┬────────┘
         │ routes
    ┌────┴────┐
    │         │
┌───▼───┐ ┌───▼───┐
│Frontend│ │Backend│
│ Repo   │ │ Repo  │
└────────┘ └────────┘
```

### Getting Started Patterns
- **Single repo**: Standard beads workflow
- **Multi-repo**: Configure routes and cross-repo dependencies
- **Multi-agent**: Add work assignment and handoff protocols

## 2. Routing and Coordination Patterns

### Routing Configuration
Create `.beads/routes.jsonl` with pattern-based routing rules:

```json
{"pattern": "frontend/**", "target": "frontend-repo", "priority": 10}
{"pattern": "backend/**", "target": "backend-repo", "priority": 10}
{"pattern": "docs/**", "target": "docs-repo", "priority": 5}
{"pattern": "*", "target": "main-repo", "priority": 0}
```

**Route Fields:**
- `pattern`: Glob pattern matching issue title, labels, or explicit path prefix
- `target`: Target repository identifier
- `priority`: Higher values checked first (specific patterns should have higher priority)

**Pattern Examples:**
- `{"pattern": "frontend/*", "target": "frontend"}`
- `{"pattern": "*api*", "target": "backend"}`
- `{"pattern": "label:docs", "target": "docs-repo"}`

### Routing Commands
```bash
# Show routing table
bd routes list
bd routes list --json

# Test routing behavior
bd routes test "Fix frontend button"
bd routes test --label frontend

# Add/remove routes
bd routes add "frontend/**" --target frontend-repo --priority 10
bd routes remove "frontend/**"
```

### Auto-Routing
Issues are auto-routed based on title matching:
```bash
bd create "Fix frontend button alignment" -t bug
# Auto-routed to frontend-repo based on title match

# Manual override
bd create "Fix button" --repo backend-repo
```

### Agent Coordination Patterns

#### Work Assignment (Pinning)
```bash
# Pin issue to specific agent
bd pin bd-42 --for agent-1
bd pin bd-42 --for agent-1 --start  # Pin and start work

# Check pinned work
bd hook  # What's on my hook?
bd hook --agent agent-1  # Check another agent's work
bd hook --json  # JSON output for AI agents

# Unpin work
bd unpin bd-42
```

#### Handoff Patterns
1. **Sequential Handoff**: Agent A → Agent B
   ```bash
   # Agent A completes work, hands off
   bd close bd-42 --reason "Ready for review"
   bd pin bd-42 --for agent-b
   
   # Agent B picks up
   bd hook  # Sees bd-42
   bd update bd-42 --claim
   ```

2. **Parallel Work**: Multiple agents work independently
   ```bash
   # Coordinator assigns parallel work
   bd pin bd-42 --for agent-a --start
   bd pin bd-43 --for agent-b --start
   bd pin bd-44 --for agent-c --start
   
   # Monitor progress
   bd list --status in_progress --json
   ```

3. **Fan-Out / Fan-In**: Split work, then merge
   ```bash
   # Fan-out: Create subtasks
   bd create "Part A" --parent bd-epic
   bd create "Part B" --parent bd-epic
   bd create "Part C" --parent bd-epic
   
   # Assign to different agents
   bd pin bd-epic.1 --for agent-a
   bd pin bd-epic.2 --for agent-b
   bd pin bd-epic.3 --for agent-c
   
   # Fan-in: Wait for all parts
   bd dep add bd-merge bd-epic.1 bd-epic.2 bd-epic.3
   ```

### Agent Discovery

Find available agents and check their status:

```bash
# List known agents (if using agent registry)
bd agents list

# Check agent status
bd agents status agent-1

# JSON output for programmatic access
bd agents list --json
```

### Conflict Prevention
```bash
# File reservations (prevent concurrent edits)
bd reserve auth.go --for agent-1
bd reservations list  # Check current reservations
bd reserve --release auth.go  # Release when done

# Issue locking
bd lock bd-42 --for agent-1  # Exclusive work lock
bd unlock bd-42  # Release lock
```

### Communication Patterns
```bash
# Via comments
bd comment add bd-42 "Completed API, needs frontend integration"

# Via labels (status tracking)
bd update bd-42 --add-label "needs-review"
bd list --label-any needs-review  # Filter by label
```

### Cross-Repo Dependencies
```bash
# Track dependencies across repositories
bd dep add bd-42 external:backend-repo/bd-100

# View cross-repo dependencies
bd dep tree bd-42 --cross-repo

# Hydrate issues from related repos
bd hydrate  # Pull related issues
bd hydrate --dry-run  # Preview hydration
bd hydrate --from backend-repo  # Hydrate from specific repo
```

## 3. Configuration (config.toml, Backend Setup)

### Configuration Locations (Priority Order)
1. **Project config**: `.beads/config.toml` (highest priority)
2. **User config**: `~/.beads/config.toml`
3. **Environment variables**: `BEADS_*`
4. **Command-line flags**: (highest priority)

### Managing Configuration
```bash
# Get config value
bd config get import.orphan_handling

# Set config value
bd config set import.orphan_handling allow

# List all config
bd config list

# Reset to default
bd config reset import.orphan_handling
```

### Configuration Options

#### Database Configuration
```toml
[database]
path = ".beads/beads.db"     # Database file location
wal_mode = true              # Enable Write-Ahead Logging (performance)
cache_size = 10000           # SQLite cache size
```

#### ID Generation Options
```toml
[id]
prefix = "bd"                # Issue ID prefix (default: "bd")
hash_length = 4              # Hash length in IDs
```

**Issue ID Modes:**
- `hash` (default): Hash-based IDs like `bd-a3f2`, `bd-7f3a8` (collision-free across concurrent branches)
- `counter`: Sequential IDs like `bd-1`, `bd-2`, `bd-3` (human-friendly, single-writer workflows)

```bash
# Switch ID modes
bd config set issue_id_mode counter  # Sequential IDs
bd config set issue_id_mode hash     # Hash-based IDs (default)
```

#### Import/Export Configuration
```toml
[import]
orphan_handling = "allow"     # allow|resurrect|skip|strict
dedupe_on_import = false      # Run duplicate detection after import

[export]
path = ".beads/issues.jsonl"  # Default export file path
```

**Orphan Handling Modes:**
- `allow`: Import orphans without validation (default)
- `resurrect`: Restore deleted parents as tombstones
- `skip`: Skip orphaned children with warning
- `strict`: Fail if parent missing

#### Git Integration Configuration
```toml
[git]
auto_commit = true            # Auto-commit on sync
auto_push = true              # Auto-push on sync
commit_message = "bd sync"    # Default commit message
```

#### Hooks Configuration
```toml
[hooks]
pre_commit = true             # Enable pre-commit hook
post_merge = true             # Enable post-merge hook
pre_push = true               # Enable pre-push hook
```

#### Deletions Configuration
```toml
[deletions]
retention_days = 30           # Keep deletion records for N days
prune_on_sync = true          # Auto-prune old records
```

### Environment Variables
| Variable | Description |
|----------|-------------|
| `BEADS_DB` | Database path |
| `BEADS_LOG_LEVEL` | Log level (debug, info, warn, error) |
| `BEADS_CONFIG` | Config file path |

### Example Configuration File
`.beads/config.toml`:
```toml
[id]
prefix = "myproject"
hash_length = 6

[import]
orphan_handling = "resurrect"
dedupe_on_import = true

[git]
auto_commit = true
auto_push = true

[deletions]
retention_days = 90

[database]
wal_mode = true
cache_size = 10000
```

## 4. Git Integration (Hooks, Worktrees, Branching)

### File Structure
```
.beads/
├── config.toml        # Project config (git-tracked)
├── metadata.json      # Backend metadata (git-tracked)
└── dolt/              # Dolt database and server data (gitignored)
```

### Git Hooks
```bash
# Install hooks (pre-commit, post-merge, pre-push)
bd hooks install

# Check hook status
bd hooks status

# Uninstall hooks
bd hooks uninstall
```

**Installed Hooks:**
- **pre-commit**: Triggers Dolt commit
- **post-merge**: Triggers Dolt sync after pull
- **pre-push**: Ensures Dolt sync before push

### Conflict Resolution
Dolt handles merge conflicts at the database level:
```bash
# Check for and fix conflicts
bd doctor --fix
```

### Protected Branches
For protected main branches (e.g., GitHub protected branches):
```bash
bd init --branch beads-sync
```
Creates separate `beads-sync` branch for issue tracking, avoiding direct commits to main.

### Git Worktrees
Beads works seamlessly in git worktrees using embedded mode:
```bash
# In worktree — just run commands directly
bd create "Task"
bd list
```

### Branch Workflows

#### Feature Branch Workflow
```bash
git checkout -b feature-x
bd create "Feature X" -t feature
# Work on feature...
bd sync
git push
```

#### Fork Workflow
```bash
# In fork repository
bd init --contributor
# Work in separate planning repo...
bd sync
```

#### Team Workflow
```bash
# Team members share Dolt database
bd init --team
# All members share the Dolt database
bd sync  # Pulls latest changes via Dolt replication
```

#### Duplicate Detection
After merging branches:
```bash
bd duplicates --auto-merge
```

## 5. Advanced Features and Best Practices

### Issue Management Operations

#### Issue Rename
Rename issues while preserving all references:
```bash
bd rename bd-42 bd-new-id
bd rename bd-42 bd-new-id --dry-run  # Preview changes
```
Updates dependencies, references in other issues, comments, and descriptions.

#### Issue Merge
Merge duplicate issues:
```bash
bd merge bd-42 bd-43 --into bd-41
bd merge bd-42 bd-43 --into bd-41 --dry-run
```
Merges dependencies, updates text references, and closes source issues with merge reason.

### Database Management

#### Database Compaction
Reduce database size by compacting old issues:
```bash
# View compaction statistics
bd admin compact --stats

# Preview candidates (30+ days closed)
bd admin compact --analyze --json

# Apply agent-generated summary
bd admin compact --apply --id bd-42 --summary summary.txt

# Immediate deletion (CAUTION!)
bd cleanup --force
```

**When to compact:**
- Database > 10MB with old closed issues
- After major milestones
- Before archiving project phase

#### Restore from History
View deleted or compacted issues from git:
```bash
bd restore bd-42 --show
bd restore bd-42 --to-file issue.json
```

#### Database Inspection
```bash
# Schema information
bd info --schema --json

# Raw database query (advanced)
sqlite3 .beads/beads.db "SELECT * FROM issues LIMIT 5"
```

### Event System
Subscribe to beads events:
```bash
# View recent events
bd events list --since 1h

# Watch events in real-time
bd events watch
```

**Event Types:**
- `issue.created`, `issue.updated`, `issue.closed`
- `dependency.added`, `dependency.removed`
- `sync.completed`, `sync.failed`

### Batch Operations

#### Create Multiple Issues
```bash
cat issues.jsonl | bd import -i -
```

#### Update Multiple Issues
```bash
bd list --status open --priority 4 --json | \
  jq -r '.[].id' | \
  xargs -I {} bd update {} --priority 3
```

#### Close Multiple Issues
```bash
bd list --label "sprint-1" --status open --json | \
  jq -r '.[].id' | \
  xargs -I {} bd close {} --reason "Sprint complete"
```

### Performance Tuning

#### Large Databases
```bash
# Enable WAL mode for better concurrency
bd config set database.wal_mode true

# Increase cache size
bd config set database.cache_size 10000
```

#### Many Concurrent Agents
Beads uses Dolt server mode to handle concurrent access:
```bash
# Start Dolt server
bd dolt start

# Check server health
bd doctor
```

#### CI/CD Optimization
In CI/CD environments, beads uses embedded mode by default:
```bash
# Just run commands directly
bd list
```

### Best Practices for Multi-Agent Coordination

1. **Clear Ownership**: Always pin work to specific agents using `bd pin`
2. **Document Handoffs**: Use comments to explain context during handoffs
3. **Status Labels**: Use labels like `needs-review`, `blocked`, `ready` for workflow tracking
4. **Conflict Prevention**: Use file reservations (`bd reserve`) for shared files
5. **Regular Monitoring**: Use `bd list --status in_progress --json` to monitor agent progress
6. **Route Specificity**: Use specific patterns in routing config; avoid overly broad matches
7. **Priority Order**: Ensure specific patterns have higher priority than catch-all patterns
8. **Default Fallback**: Always include `{"pattern": "*", "target": "main-repo", "priority": 0}` as fallback
9. **Session Management**: Always run `bd sync` at session end before switching branches
10. **Pre-work Sync**: Pull latest changes with `bd sync` before starting work

## 6. Integration with Project Agent Infrastructure

### Integration with Existing Agent Systems

#### AI Agent Interface
Beads is designed for AI agent use with these features:
- **JSON output**: All commands support `--json` flag for programmatic access
- **Hash-based IDs**: Prevent merge collisions in multi-agent workflows
- **Dependency graph**: `blocks`, `parent-child`, `related`, `discovered-from` relationships
- **Stealth mode**: Works without git (`--stealth` flag)

#### Essential Commands for AI Agents
```bash
# Always use --json for programmatic access
bd list --json
bd create "Title" --json
bd show bd-42 --json
bd ready --json
bd blocked --json

# Working on issues
bd update bd-42 --claim --json
bd close bd-42 --reason "Fixed" --json

# Dependencies
bd dep add bd-child bd-parent
bd dep tree bd-42

# Sync at session end (CRITICAL)
bd sync
```

#### Integration with tmux Worktrees
The project uses tmux worktrees for agent isolation. Beads integrates seamlessly:
- **Embedded mode**: Automatically used in worktrees
- **No server required**: Each worktree can run beads independently
- **Cross-worktree coordination**: Use multi-agent routing and pinning

#### Integration with Kiro Spec-Driven Development
Map Kiro spec workflow to beads issue lifecycle:
- **Spec creation** → `bd create` with type "spec"
- **Task generation** → `bd create` with type "task"
- **Implementation** → `bd update --claim`
- **Completion** → `bd close --reason "Implemented"`

Example workflow:
```bash
# Phase 1: Specification
bd create "HBO-74: Beads Multi-Agent Documentation" --type spec --priority 2
bd dep add bd-new-spec bd-parent-epic

# Phase 2: Task generation
bd create "Research multi-agent routing" --type task --parent bd-spec-id
bd create "Write documentation summary" --type task --parent bd-spec-id

# Phase 3: Implementation
bd update bd-task-id --claim
# Work on task...
bd close bd-task-id --reason "Completed"

# Phase 4: Validation
bd create "Review documentation" --type task --label "validation"
```

#### Agent Menu Integration
Potential integration points with agent-menu systems:
- `bd ready` output as task queue for agent selection
- `bd hook --agent <agent-name>` for agent-specific work assignment
- `bd pin` commands for manual work allocation through menu interface

### Workflow Primitives: Formulas, Molecules, Gates, Wisps

#### Molecules
A **molecule** is a persistent instance of a formula — a work graph with steps and dependencies.

**Lifecycle:** Formula → `bd pour` → Molecule → work steps → Completed → Archived

**Key commands:**
```bash
# Create molecule from formula
bd pour <formula> [--var key=value]

# List/view molecules
bd mol list
bd mol show <molecule-id>

# Work on molecule steps
bd ready  # Shows steps with completed dependencies
bd update <id> --claim  # Start a step
bd close <id>  # Complete a step
bd pin <id> --start  # Assign to agent
```

#### Formulas
Declarative workflow templates in TOML or JSON, stored in:
- `.beads/formulas/` (project-specific)
- `~/.beads/formulas/` (user-specific)
- Built-in formulas

**Structure:**
```toml
formula = "deploy-workflow"
description = "Standard deployment workflow"
version = "1.0"
type = "workflow"  # workflow/expansion/aspect

[vars]
environment = { required = true, enum = ["staging", "production"] }
region = { default = "us-east-1" }

[[steps]]
id = "build"
type = "task"
title = "Build application"

[[steps]]
id = "deploy"
type = "task"
title = "Deploy to {{environment}}"
needs = ["build"]  # Dependencies
```

**Step types:** `task` (default), `human` (requires human action), `gate` (async coordination)

#### Gates
Async coordination primitives that block step progression until conditions are met.

**Gate types:**
- **Human gate**: Wait for human approval (`approvers`, `require_all`)
- **Timer gate**: Wait for duration (`30m`, `2h`, `24h`, `7d`)
- **GitHub gate**: Wait for CI/PR events (`check_suite` success, `pull_request` merged)

**Gate operations:**
```bash
# Check gate state
bd show <gate-id>

# Manual approval
bd gate approve <id> --approver <name>

# Emergency bypass
bd gate skip <id> --reason <reason>
```

**Patterns:**
- Approval flows: staging → QA sign-off → production
- Scheduled releases using timer gates
- CI-gated deploys using GitHub gates

## 7. NixOS-specific Configuration Considerations

### Current NixOS Integration
The project already has Beads integrated via Nix flake:

```nix
# In parts/devshell.nix
packages = [
  ast-grep
  tmux
  llm-agents-packages.beads  # Beads from llm-agents overlay
];

# In home/default.nix
home.packages = [
  llm-agents-packages.beads
];
```

**Version:** Beads v0.63.3 via `llm-agents.nix` flake input

### NixOS-specific Configuration Recommendations

#### Database Storage Location
For NixOS deployments, consider these database location options:

1. **Git-tracked (current preference)**: `.beads/` committed to repository
   - Pros: Issue history in git commits, easy backup
   - Cons: Can bloat repository size with SQL database files

2. **Gitignored**: `.beads/dolt/` directory in `.gitignore`
   - Pros: Keeps repository clean, Dolt has built-in versioning
   - Cons: Separate backup strategy needed for issue database

Recommendation for NixOS: Use gitignored approach with regular `bd export` backups.

#### Configuration for NixOS Modules
Create NixOS-specific issue types and labels:
```bash
# NixOS-specific issue types
bd create "Add nixos module for service" --type feature --label "nixos-module"
bd create "Update flake inputs" --type task --label "flake-update"
bd create "Home-manager configuration" --type task --label "home-manager"

# Priority mapping for NixOS
# 0: Critical (system broken)
# 1: Urgent (security, major bug)
# 2: High (feature, important fix)
# 3: Normal (enhancement)
# 4: Low (backlog, nice-to-have)
```

#### Integration with NixOS Development Workflow

**Building/testing issues:**
```bash
# Link issue to build/test commands
bd comment add bd-42 "Test with: nix build .#nixosConfigurations.hostName"
bd comment add bd-42 "Deploy with: sudo nixos-rebuild switch --flake .#hostName"
```

**Dependency tracking for NixOS modules:**
```bash
# Track dependencies between NixOS modules
bd dep add bd-module-a bd-module-b --type blocks
bd dep add bd-module-c bd-service-d --type related
```

#### Multi-machine Coordination for NixOS
For managing multiple NixOS hosts:

```json
// .beads/routes.jsonl
{"pattern": "host:server-*", "target": "server-configs", "priority": 10}
{"pattern": "host:workstation-*", "target": "workstation-configs", "priority": 10}
{"pattern": "*nixos*", "target": "nixos-common", "priority": 5}
{"pattern": "*", "target": "main-config", "priority": 0}
```

#### Security Considerations for NixOS
1. **Database permissions**: Ensure `.beads/` directory has appropriate permissions
2. **Secret management**: Do not store secrets in issue descriptions
3. **Backup strategy**: Regular `bd export` to secured location
4. **Access control**: Use `bd pin` and `bd lock` for sensitive configuration changes

#### Performance Optimization for NixOS
```toml
# .beads/config.toml for NixOS environments
[database]
wal_mode = true           # Essential for concurrent nix builds
cache_size = 20000        # Larger cache for complex dependency graphs

[git]
auto_commit = true        # Auto-commit after nixos-rebuild
auto_push = false         # Manual push for deployment control

[import]
orphan_handling = "skip"  # Skip orphans in CI environments
```

### Migration from Linear to Beads
For teams migrating from Linear to Beads on NixOS:

1. **Export Linear issues** to JSON format
2. **Import to Beads** with `bd import --file linear-export.json`
3. **Configure routing** for team members
4. **Train agents** on Beads CLI commands
5. **Parallel run** both systems during transition

### Monitoring and Maintenance
```bash
# Regular health checks
bd doctor  # Database health
bd hooks status  # Git hooks status
bd dolt status  # Dolt server status

# Database maintenance
bd admin compact --stats  # Check database size
bd sync --dry-run  # Test sync before actual sync

# Backup procedure
bd export --file beads-backup-$(date +%Y%m%d).jsonl
```

## References

### Documentation URLs
1. **Multi-Agent Coordination**: https://gastownhall.github.io/beads/multi-agent
2. **Multi-Repo Routing**: https://gastownhall.github.io/beads/multi-agent/routing
3. **Agent Coordination**: https://gastownhall.github.io/beads/multi-agent/coordination
4. **Configuration Reference**: https://gastownhall.github.io/beads/reference/configuration
5. **Git Integration**: https://gastownhall.github.io/beads/reference/git-integration
6. **Advanced Features**: https://gastownhall.github.io/beads/reference/advanced

### Research Plans
- `/.kilo/worktrees/fluoridated-meteorology/.kilo/plans/1775734885067-shiny-panda.md` - Beads Integration for AI Agent Issue Tracking
- `/.kilo/worktrees/fluoridated-meteorology/.kilo/plans/1775736706346-proud-planet.md` - Beads Research Summary

### Project Integration
- **Beads in Nix flake**: `llm-agents-packages.beads` (v0.63.3)
- **DevShell integration**: `parts/devshell.nix` and `home/default.nix`
- **Kiro spec integration**: Mapping between `.kiro/specs/` workflow and beads issue lifecycle

## Conclusion

Beads provides a robust, AI-native issue tracking solution with excellent multi-agent coordination capabilities. Its deep Git integration, version-controlled SQL backend (Dolt), and flexible configuration make it well-suited for NixOS environments and agent-based development workflows.

Key advantages for the hbohlen-systems project:
1. **Already integrated** via Nix flake (`llm-agents-packages.beads`)
2. **Multi-agent ready** with routing, pinning, and coordination features
3. **Git-native workflow** compatible with existing tmux worktrees
4. **JSON API** perfect for AI agent programmatic access
5. **Dependency tracking** for complex NixOS module relationships
6. **Formulas and molecules** for reusable workflow patterns

The integration with Kiro spec-driven development provides a powerful combination for structured AI-assisted development on NixOS systems.