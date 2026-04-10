# Beads Knowledge Base for hbohlen-systems

## Introduction

**Beads** (`bd`) is a git-backed, AI-native issue tracker designed for AI-supervised coding workflows. It uses **Dolt** (a version-controlled SQL database) as its backend, enabling collaboration via Dolt-native replication while maintaining local-first operation. This knowledge base synthesizes documentation from official sources and provides project-specific guidance for using beads in the `hbohlen-systems` NixOS configuration repository.

### Project Context
- **Beads is already installed** in the devShell: accessible via `nix develop .#ai --command bd --help`
- **Version**: v0.63.3 via `llm-agents.nix` flake input
- **Existing research**: `.kilo/worktrees/fluoridated-meteorology/.kilo/plans/*.md`
- **Integration**: Part of the AI-DLC and Spec-driven development workflow

### Why Beads for AI Workflows?
- **Hash-based IDs** (e.g., `bd-a1b2`) prevent collisions when multiple agents work concurrently
- **JSON-first output** with `--json` flag for programmatic access by AI agents
- **Dependency-aware execution** - `bd ready` shows only unblocked work
- **Declarative workflows** with Formulas, Molecules, and Gates for complex coordination
- **Self-hosted & NixOS-native** - No SaaS dependencies, integrated via nixpkgs

## Table of Contents

1. [Architecture and Core Concepts](#1-architecture-and-core-concepts)
2. [Essential Commands and Usage](#2-essential-commands-and-usage)
3. [Workflow System](#3-workflow-system)
4. [Multi-Agent Coordination](#4-multi-agent-coordination)
5. [Configuration and Setup](#5-configuration-and-setup)
6. [AI Agent Best Practices](#6-ai-agent-best-practices)
7. [Integration with hbohlen-systems](#7-integration-with-hbohlen-systems)
8. [Skill Domains Definition](#8-skill-domains-definition)

## 1. Architecture and Core Concepts

### Database Architecture
```
Dolt DB (.beads/dolt/, gitignored)
    ↕ dolt commit
Local Dolt history
    ↕ dolt push/pull
Remote Dolt repository (shared across machines)
```

### Core Components
- **Database**: Dolt (version-controlled SQL database) in `.beads/dolt/` (gitignored by default)
- **Config**: `.beads/config.toml` (git-tracked)
- **Metadata**: `.beads/metadata.json` (git-tracked)
- **Formulas**: `.beads/formulas/` (project) → `~/.beads/formulas/` (user) → built-in

### Issue Model
Every issue has:
- **ID**: Hash-based (e.g., `bd-a1b2`) or hierarchical (e.g., `bd-a1b2.1` for epic subtasks)
- **Type**: `bug`, `feature`, `task`, `epic`, `chore`
- **Priority**: 0 (critical) to 4 (backlog)
- **Status**: `open`, `in_progress`, `closed`
- **Labels**: Flexible tagging system
- **Dependencies**: Blocking and non-blocking relationships

### Dependency Types
| Type | Description | Ready Queue Impact |
|------|-------------|-------------------|
| `blocks` | Hard dependency (X blocks Y) | Yes - blocked items not ready |
| `parent-child` | Epic/subtask hierarchy | No |
| `discovered-from` | Tracks origin of discovery during work | No |
| `related` | Soft relationship | No |

## 2. Essential Commands and Usage

### Quick Start
```bash
# Initialize beads in project (use --quiet for AI agents to avoid prompts)
bd init --quiet

# Install git hooks (recommended)
bd hooks install

# Check installation health
bd doctor --fix
```

### Core Issue Management
```bash
# Always use --json for programmatic access by AI agents
bd list --json
bd create "Title" -t task -p 1 --description "Details" --json
bd show bd-42 --json
bd update bd-42 --claim --json
bd close bd-42 --reason "Completed" --json
```

### Dependency Management
```bash
# Add dependencies
bd dep add bd-2 bd-1  # bd-2 depends on bd-1

# View dependencies
bd dep tree bd-42 --depth 3

# Find ready and blocked work
bd ready --json
bd blocked --json
```

### Sync and Data Management
```bash
# Full sync cycle (CRITICAL - always run at end of work session)
bd sync

# Export/Import for backup/migration
bd export -o backup.jsonl
bd import -i backup.jsonl --orphan-handling resurrect
```

## 3. Workflow System

### Chemistry Metaphor
| Phase | Storage | Synced | Use Case |
|-------|---------|--------|----------|
| **Proto** (solid) | Built-in | N/A | Reusable templates (Formulas) |
| **Mol** (liquid) | `.beads/` | Yes | Persistent work (Molecules) |
| **Wisp** (vapor) | `.beads-wisp/` | No | Ephemeral operations |

### Formulas
Declarative workflow templates in TOML or JSON format:
```toml
formula = "release"
description = "Software release workflow"
version = "1.0.0"
type = "workflow"

[vars]
version = { required = true, default = "1.0.0" }
environment = { enum = ["staging", "production"], default = "staging" }

[[steps]]
id = "tag-release"
title = "Tag release {{.version}}"
type = "task"
description = "Create git tag for release {{.version}}"

[[steps]]
id = "deploy-staging"
title = "Deploy to {{.environment}}"
type = "task"
description = "Deploy version {{.version}} to {{.environment}}"
needs = ["tag-release"]
```

### Molecules
Persistent instances of formulas with step dependencies:
```bash
# Instantiate a formula as a molecule
bd pour release --var version=1.0.0 --var environment=production

# List molecules
bd mol list --json

# Show molecule details
bd mol show mol-abc --json

# Work through steps
bd update mol-abc.1 --claim  # Start first step
bd close mol-abc.1           # Complete first step
```

### Gates
Async coordination primitives that block step progression:

**Gate Types:**
- **Human gate**: Wait for human approval (`approvers`, `require_all`)
- **Timer gate**: Wait for duration (`30m`, `2h`, `24h`, `7d`)
- **GitHub gate**: Wait for CI/PR events (`check_suite` success, `pull_request` merged)

**Gate Operations:**
```bash
# Check gate state
bd show gate-123 --json

# Manual approval
bd gate approve gate-123 --approver "alice"

# Emergency bypass
bd gate skip gate-456 --reason "Emergency bypass"
```

### Wisps
Ephemeral workflows that don't sync to git:
```bash
# Create ephemeral wisp
bd wisp create quick-test --var name="test"

# Work on wisp (stored in .beads-wisp/, not synced)
bd wisp update wisp-abc.1 --claim
bd wisp close wisp-abc.1
```

## 4. Multi-Agent Coordination

### Routing System
Pattern-based issue routing across repositories using `.beads/routes.jsonl`:
```json
{
  "route": "frontend/**",
  "destination": "frontend-repo",
  "priority": 2,
  "agent": "frontend-agent"
}
```

### Work Assignment
```bash
# Pin work to specific agent
bd pin bd-42 --for frontend-agent --start

# Show pinned work
bd hook

# Release pin when done
bd pin bd-42 --release
```

### Coordination Patterns
1. **Sequential handoff**: Agent A → Gate → Agent B
2. **Parallel work**: Multiple agents work on independent subtasks
3. **Fan-out/fan-in**: One agent creates subtasks, another integrates results
4. **Review flow**: Implement → Human gate → Deploy

### Conflict Prevention
- **File reservations**: `bd reserve path/to/file` to prevent concurrent edits
- **Issue locking**: Automatic locking when agent claims work
- **Dependency tracking**: Cross-repo dependency awareness

## 5. Configuration and Setup

### Configuration File (config.toml)
```toml
[database]
backend = "dolt"
path = ".beads/dolt"

[dolt]
auto_commit = "on"
remote = "origin"
branch = "beads-sync"

[hooks]
pre_commit = ["bd sync"]
post_merge = ["bd sync --import"]

[git]
worktree_aware = true
protected_branches = ["main", "master"]

[agent]
name = "ai-agent"
sandbox = false
readonly = false
```

### Git Integration
- **Hooks**: `bd hooks install` installs pre-commit, post-merge, pre-push hooks
- **Worktrees**: Beads auto-detects worktrees and uses embedded mode
- **Protected branches**: `bd init --branch beads-sync` creates separate sync branch
- **Conflict resolution**: `bd doctor --fix` after git merges

### NixOS-Specific Configuration
Beads is integrated via the project's Nix flake:
```nix
# In parts/devshell.nix:
llm-agents-packages.beads
```

**Recommended configuration for NixOS environments:**
```toml
[performance]
concurrent_nix_builds = 4
cache_warming = true

[storage]
# User prefers database committed to git (not gitignored)
git_track_database = true
```

## 6. AI Agent Best Practices

### JSON-First Workflow
```bash
# Always use --json for programmatic access
bd list --json | jq -r '.[] | select(.priority == 1) | .id'

# Create issues with full context
bd create "Implement feature X" -t feature \
  --description "Detailed requirements..." \
  --deps discovered-from:bd-42 \
  --json
```

### Session Management Workflow
```bash
# Start of session
bd prime  # Get AI-optimized workflow context
bd ready --json  # Check available work

# During session
ISSUE_ID=$(bd ready --json | jq -r '.[0].id')
bd update $ISSUE_ID --claim --json
# ... implement changes ...
bd close $ISSUE_ID --reason "Implemented feature X" --json

# End of session (CRITICAL)
bd sync  # Always sync before ending session
```

### Safety and Sandbox Features
```bash
# Read-only mode for inspection
bd list --json --readonly

# Sandbox mode for testing
bd create "Test" --json --sandbox

# No-database mode for ephemeral environments
bd --no-db list --json
```

### Discovery Tracking
When discovering new work during implementation:
```bash
bd create "Found SQL injection vulnerability" -t bug -p 0 \
  --description "Vulnerability in auth.go:45, needs immediate attention" \
  --deps discovered-from:bd-42 \
  --json
```

## 7. Integration with hbohlen-systems

### NixOS Module Development
**Issue types for NixOS workflows:**
- `nixos-module`: New NixOS module development
- `home-manager`: Home-manager configuration
- `flake-update`: Flake input updates
- `devshell`: DevShell configuration changes

**Suggested labels:**
- `nixos`, `home-manager`, `flake`, `devshell`, `ci-nix`
- `security`, `performance`, `refactor`, `documentation`

### Kiro Spec-Driven Development Integration

**Mapping Kiro workflow to beads:**
```
Kiro Phase           → Beads Command
─────────────────────────────────────────────
Spec creation        → bd create "Feature: X" -t epic --label "spec"
Requirements         → bd create "Requirements" -t task --parent <epic>
Design               → bd create "Design" -t task --parent <epic>
Task generation      → bd create "Implement Y" -t task --parent <epic>
Implementation       → bd update <task> --claim --json
Validation           → bd create "Validate" -t task --parent <epic>
Completion           → bd close <task> --reason "Spec implemented"
```

**Label conventions for Kiro:**
- `spec`, `spec-requirements`, `spec-design`, `spec-tasks`, `spec-implementation`
- `spec-validation`, `spec-phase1`, `spec-phase2`, `spec-phase3`

### Project-Specific Workflow Examples

**Create NixOS Module:**
```bash
bd pour nixos-module --var name="my-module" --var description="New NixOS module"
```

**Update Flake Inputs:**
```bash
bd pour flake-update --var input="nixpkgs" --var target="unstable"
```

**Run Kiro Spec Workflow:**
```bash
bd pour spec --var feature="new-feature" --var phase="requirements"
```

## 8. Skill Domains Definition

### Skill 1: Core Issue Management
**Purpose**: Basic issue lifecycle management for AI agents

**Essential Commands** (always with `--json`):
- `bd create`, `bd list`, `bd show`, `bd update`, `bd close`, `bd search`

**Integration Points**:
- Spec creation and task generation
- NixOS module issue tracking
- Daily agent workflow initiation

### Skill 2: Dependency Management
**Purpose**: Manage issue dependencies and find ready work

**Essential Commands**:
- `bd dep add/remove/tree`, `bd ready`, `bd blocked`, `bd dep cycles`

**Best Practices**:
- Always check `bd ready` before starting work
- Use `discovered-from` for work discovered during implementation
- Avoid circular dependencies (check with `bd dep cycles`)

### Skill 3: Sync & Data Management
**Purpose**: Database synchronization and data integrity

**Essential Commands**:
- `bd sync` (CRITICAL), `bd export`, `bd import`, `bd hooks`, `bd doctor`

**Integration Points**:
- Session start/end workflow
- Git hook integration
- Backup and migration procedures

### Skill 4: Workflow Orchestration
**Purpose**: Use formulas, molecules, gates, and wisps for complex workflows

**Essential Commands**:
- `bd pour`, `bd mol list/show`, `bd gate approve/skip`, `bd wisp create`

**Project Integration**:
- NixOS module creation workflows
- Spec execution workflows
- Multi-phase project coordination

### Skill 5: Multi-agent Coordination
**Purpose**: Coordinate work between multiple AI agents

**Essential Commands**:
- `bd pin`, `bd hook`, `bd reserve`, `bd audit`

**Integration Points**:
- Tmux worktree coordination
- Agent-menu system integration
- Cross-repo dependency tracking

### Skill 6: Configuration & Advanced
**Purpose**: Configure beads for project-specific needs

**Essential Commands**:
- `bd config`, `bd info`, `bd stats`, `bd migrate`, `bd backend`

**NixOS Considerations**:
- Database storage location (git-tracked per user preference)
- Performance optimization for concurrent nix builds
- Integration with existing agent infrastructure

## Summary

Beads provides a comprehensive, AI-native issue tracking system that integrates seamlessly with the `hbohlen-systems` NixOS configuration repository. Key advantages for this project include:

1. **Self-hosted & NixOS-native**: No SaaS dependencies, integrated via nixpkgs
2. **AI-optimized workflows**: JSON-first output, hash-based IDs, dependency awareness
3. **Workflow automation**: Formulas, molecules, and gates for complex coordination
4. **Multi-agent ready**: Built-in routing, pinning, and coordination features
5. **Git integration**: Deep hooks, worktree, and branch awareness

### Quick Reference for AI Agents
1. **Always use `--json`** for programmatic access
2. **Always run `bd sync`** at end of work session (data preservation)
3. **Start with `bd ready`** to find unblocked work
4. **Track discoveries** with `--deps discovered-from:<parent>`
5. **Use formulas** for repetitive project workflows (NixOS modules, Specs)

### Comparison: Beads vs Linear for hbohlen-systems
| Aspect | Beads | Linear |
|--------|-------|--------|
| Self-hosted | ✅ (Dolt local/remote) | ❌ |
| NixOS integration | ✅ Via nixpkgs/llm-agents | ❌ No nixpkgs |
| AI agent native | ✅ JSON, hash IDs, deps | ⚠️ API-based |
| Git-free usage | ✅ `--sandbox` mode | ❌ |
| Offline capable | ✅ (embedded Dolt) | ❌ |
| Setup complexity | Low (already in flake) | Medium (SaaS) |
| Collaboration | Dolt push/pull | Built-in |
| Cost | Free (open source) | Paid subscription |

---

*This knowledge base synthesizes beads documentation for the hbohlen-systems NixOS configuration repository. Beads v0.63.3 is available via `nix develop .#ai --command bd --help`. Last updated: April 2026*