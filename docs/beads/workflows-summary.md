# Beads Workflows Summary

## 1. Introduction to Beads Workflows

Beads provides powerful workflow primitives for complex, multi-step processes using a molecular chemistry metaphor:

| Phase | Storage | Synced | Use Case |
|-------|---------|--------|----------|
| **Proto** (solid) | Built-in | N/A | Reusable templates (Formulas) |
| **Mol** (liquid) | `.beads/` | Yes | Persistent work (Molecules) |
| **Wisp** (vapor) | `.beads-wisp/` | No | Ephemeral operations |

**Note:** Beads is already available in the hbohlen-systems devShell via `nix develop .#ai --command bd --help`.

### Table of Contents
1. [Introduction to Beads Workflows](#1-introduction-to-beads-workflows)
2. [Formulas (Declarative Workflow Templates)](#2-formulas-declarative-workflow-templates)
3. [Molecules (Work Graph Instances)](#3-molecules-work-graph-instances)
4. [Gates (Async Coordination Primitives)](#4-gates-async-coordination-primitives)
5. [Wisps (Ephemeral Issues)](#5-wisps-ephemeral-issues)
6. [AI Agent Workflow Patterns](#6-ai-agent-workflow-patterns)
7. [Integration Points](#7-integration-points)
8. [References](#8-references)
9. [Summary](#summary)


### Core Concepts
- **Formulas**: Declarative workflow templates in TOML/JSON
- **Molecules**: Work graph instances with parent-child relationships
- **Gates**: Async coordination primitives (human, timer, GitHub)
- **Wisps**: Ephemeral workflows that don't sync to git

### Key Workflow Commands
- `bd pour <formula>` - Instantiate formula as molecule
- `bd mol list` - List molecules
- `bd wisp create <formula>` - Create ephemeral wisp
- `bd pin <id> --start` - Pin work to agent
- `bd hook` - Show pinned work

### Simple Example
```bash
# Create a release workflow
bd pour release --var version=1.0.0

# View the molecule
bd mol show release-1.0.0

# Work through steps
bd update release-1.0.0.1 --claim
bd close release-1.0.0.1

# Next step becomes ready...
bd ready
```

## 2. Formulas (Declarative Workflow Templates)

Formulas are declarative workflow templates written in TOML (preferred) or JSON that define reusable patterns for work.

### Formula Format (TOML)
```toml
formula = "feature-workflow"
description = "Standard feature development workflow"
version = 1
type = "workflow"

[vars.feature_name]
description = "Name of the feature"
required = true

[[steps]]
id = "design"
title = "Design {{feature_name}}"
type = "human"
description = "Create design document"

[[steps]]
id = "implement"
title = "Implement {{feature_name}}"
needs = ["design"]

[[steps]]
id = "review"
title = "Code review"
needs = ["implement"]
type = "human"

[[steps]]
id = "merge"
title = "Merge to main"
needs = ["review"]
```

### Formula Types
| Type | Description |
|------|-------------|
| `workflow` | Standard step sequence |
| `expansion` | Template for expansion operator |
| `aspect` | Cross-cutting concerns (inject steps) |

### Variables
Define variables with defaults and constraints:
```toml
[vars.version]
description = "Release version"
required = true
pattern = "^\\d+\\.\\d+\\.\\d+$"

[vars.environment]
description = "Target environment"
default = "staging"
enum = ["staging", "production"]
```

### Step Types
| Type | Description |
|------|-------------|
| `task` | Normal work step (default) |
| `human` | Requires human action/intervention |
| `gate` | Async coordination point |

### Dependencies

**Sequential:**
```toml
[[steps]]
id = "step1"
title = "First step"

[[steps]]
id = "step2"
title = "Second step"
needs = ["step1"]  # step2 depends on step1
```

**Parallel then Join (Fan-in):**
```toml
[[steps]]
id = "test-unit"
title = "Unit tests"

[[steps]]
id = "test-integration"
title = "Integration tests"

[[steps]]
id = "deploy"
title = "Deploy"
needs = ["test-unit", "test-integration"]  # Waits for both
```

### Aspects (Cross-cutting Concerns)
Apply transformations to matching steps via glob patterns:
```toml
formula = "security-scan"
type = "aspect"

[[advice]]
target = "*.deploy"  # Match all deploy steps

[advice.before]
id = "security-scan-{step.id}"
title = "Security scan before {step.title}"
```

### Formula Locations (Search Order)
1. `.beads/formulas/` (project-level)
2. `~/.beads/formulas/` (user-level)
3. Built-in formulas

### Using Formulas
```bash
# List available formulas
bd mol list

# Pour formula into molecule
bd pour <formula-name> --var key=value

# Preview what would be created
bd pour <formula-name> --dry-run
```

### Example: Release Formula
```toml
formula = "release"
description = "Standard release workflow"
version = 1

[vars.version]
required = true
pattern = "^\\d+\\.\\d+\\.\\d+$"

[[steps]]
id = "bump-version"
title = "Bump version to {{version}}"

[[steps]]
id = "changelog"
title = "Update CHANGELOG"
needs = ["bump-version"]

[[steps]]
id = "test"
title = "Run full test suite"
needs = ["changelog"]

[[steps]]
id = "build"
title = "Build release artifacts"
needs = ["test"]

[[steps]]
id = "tag"
title = "Create git tag v{{version}}"
needs = ["build"]

[[steps]]
id = "publish"
title = "Publish release"
needs = ["tag"]
type = "human"
```

## 3. Molecules (Work Graph Instances)

A **molecule** is a persistent instance of a formula — a work graph with steps and dependencies that maps to issues with parent-child relationships.

### Creating Molecules
```bash
# Pour a formula into a molecule
bd pour release --var version=1.0.0

# Creates:
# - Parent issue: bd-xyz (molecule root)
# - Child issues: bd-xyz.1, bd-xyz.2, etc. (steps)
```

### Listing and Viewing Molecules
```bash
# List molecules
bd mol list
bd mol list --json

# View molecule details
bd mol show <molecule-id>
bd dep tree <molecule-id>  # Shows full hierarchy
```

### Step Dependencies
Steps have `needs` dependencies that control execution order:
- `bd ready` only shows steps with completed dependencies
- `bd blocked` shows blocked steps

### Progressing Through Steps
```bash
# Start a step
bd update bd-xyz.1 --claim

# Complete a step
bd close bd-xyz.1 --reason "Done"

# Check what's ready next
bd ready
```

### Molecule Lifecycle
```
Formula (template)
    ↓ bd pour
Molecule (instance)
    ↓ work steps
Completed Molecule
    ↓ optional cleanup
Archived
```

### Advanced Features

**Bond Points:** Formulas can define bond points for composition:
```toml
[compose]
[[compose.bond_points]]
id = "entry"
step = "design"
position = "before"
```

**Hooks:** Execute actions on step completion:
```toml
[[steps]]
id = "build"
title = "Build project"
[steps.on_complete]
run = "make build"
```

**Pinning Work:** Assign molecules to agents:
```bash
# Pin to current agent
bd pin bd-xyz --start

# Check what's pinned
bd hook
```

### Example Workflow
```bash
# 1. Create molecule from formula
bd pour feature-workflow --var name="dark-mode"

# 2. View structure
bd dep tree bd-xyz

# 3. Start first step
bd update bd-xyz.1 --claim

# 4. Complete and progress
bd close bd-xyz.1
bd ready  # Shows next steps

# 5. Continue until complete
```

## 4. Gates (Async Coordination Primitives)

Gates block step progression until a condition is met, enabling human-in-the-loop and event-driven workflow coordination.

### Gate Types

**Human Gate:** Wait for human approval
```toml
[[steps]]
id = "deploy-approval"
title = "Approval for production deploy"
type = "human"
[steps.gate]
type = "human"
approvers = ["team-lead", "security"]
require_all = false  # Any approver can approve
```

**Timer Gate:** Wait for a duration
```toml
[[steps]]
id = "cooldown"
title = "Wait for cooldown period"
[steps.gate]
type = "timer"
duration = "24h"  # 30m, 2h, 24h, 7d
```

**GitHub Gate:** Wait for GitHub events
```toml
[[steps]]
id = "wait-for-ci"
title = "Wait for CI to pass"
[steps.gate]
type = "github"
event = "check_suite"
status = "success"
```

### Gate States
| State | Description |
|-------|-------------|
| `pending` | Waiting for condition |
| `open` | Condition met, can proceed |
| `closed` | Step completed |

### Gate Operations
```bash
# Check gate status
bd show bd-xyz.3
bd show bd-xyz.3 --json | jq '.gate'

# Manual approval (human gates)
bd gate approve bd-xyz.3 --approver "team-lead"

# Skip gate (emergency)
bd gate skip bd-xyz.3 --reason "Emergency deploy"
```

### waits-for Dependency
Creates fan-in patterns where a step waits for multiple predecessors:
```toml
[[steps]]
id = "test-a"
title = "Test suite A"

[[steps]]
id = "test-b"
title = "Test suite B"

[[steps]]
id = "integration"
title = "Integration tests"
waits_for = ["test-a", "test-b"]  # Fan-in: waits for all
```

### Example: Approval Flow
```toml
formula = "production-deploy"

[[steps]]
id = "build"
title = "Build production artifacts"

[[steps]]
id = "staging"
title = "Deploy to staging"
needs = ["build"]

[[steps]]
id = "qa-approval"
title = "QA sign-off"
needs = ["staging"]
type = "human"
[steps.gate]
type = "human"
approvers = ["qa-team"]

[[steps]]
id = "production"
title = "Deploy to production"
needs = ["qa-approval"]
```

### Best Practices
- **Use human gates for critical decisions** - Don't auto-approve production deployments
- **Add timeouts to timer gates** - Prevent indefinite blocking
- **Document gate requirements** - Make approvers and conditions clear
- **Use CI gates for quality control** - Block on test failures

## 5. Wisps (Ephemeral Issues)

Wisps are "vapor phase" molecules — ephemeral workflows that don't sync to git, perfect for temporary operations.

### Key Characteristics
- Stored in `.beads-wisp/` (gitignored)
- Don't sync with git
- Auto-expire after completion
- Ideal for local experiments, CI/CD pipelines, scratch workflows

### Creating Wisps
```bash
# Create wisp from formula
bd wisp create quick-check --var target=auth-module
```

### Wisp Commands
```bash
# List wisps
bd wisp list
bd wisp list --json

# Show wisp details
bd wisp show <wisp-id>

# Delete wisp
bd wisp delete <wisp-id>

# Delete all completed wisps
bd wisp cleanup
bd wisp cleanup --all
bd wisp cleanup --completed
```

### Wisp vs Molecule Comparison
| Aspect | Molecule | Wisp |
|--------|----------|------|
| Storage | `.beads/` | `.beads-wisp/` |
| Git sync | Yes | No |
| Persistence | Permanent | Ephemeral |
| Use case | Tracked work | Temporary ops |

### Phase Control
```bash
# Force liquid (persistent molecule)
bd mol bond <formula> <target> --pour

# Force vapor (ephemeral wisp)
bd mol bond <formula> <target> --wisp
```

### Auto-Expiration
Wisps can auto-expire:
```toml
[wisp]
expires_after = "24h"  # Auto-delete after 24 hours
```

### Example: Quick Check Workflow
```toml
# .beads/formulas/quick-check.formula.toml
formula = "quick-check"
description = "Quick local checks"

[[steps]]
id = "lint"
title = "Run linter"

[[steps]]
id = "test"
title = "Run tests"
needs = ["lint"]

[[steps]]
id = "build"
title = "Build project"
needs = ["test"]
```

```bash
# Use as wisp
bd wisp create quick-check
# Work through steps...
bd wisp cleanup  # Remove when done
```

### Best Practices
- **Use wisps for local-only work** - Don't pollute git history
- **Clean up regularly** - Use `bd wisp cleanup`
- **Use molecules for tracked work** - Wisps are ephemeral
- **Consider CI/CD wisps** - Perfect for pipeline steps

## 6. AI Agent Workflow Patterns

### Agent-Friendly Features
- **JSON output** - All commands support `--json` for programmatic access
- **Hash-based IDs** - `bd-a1b2c3` format prevents merge collisions
- **Dependency graph** - `blocks`, `parent-child`, `related`, `discovered-from`
- **Multi-agent coordination** - Routes and cross-repo dependencies
- **Workflow primitives** - Formulas, molecules, gates, wisps

### Essential Commands for Agents
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

# Sync at session end
bd sync
```

### Agent Workflow Patterns

**Pattern 1: Structured Task Execution**
```bash
# Create workflow for complex task
bd pour nixos-module-workflow --var module=nginx

# Agent claims and completes steps
bd update bd-xyz.1 --claim
# ... work ...
bd close bd-xyz.1

# Continue with next ready step
bd ready
```

**Pattern 2: Human-in-the-Loop Coordination**
```bash
# Create workflow with human approval gate
bd pour production-deploy --var version=1.2.3

# Agent completes technical steps
bd update bd-xyz.1 --claim
bd close bd-xyz.1

# Wait for human approval (gate)
# Human runs: bd gate approve bd-xyz.3 --approver "admin"

# Agent continues after gate opens
bd update bd-xyz.4 --claim
```

**Pattern 3: Ephemeral Agent Coordination**
```bash
# Create wisp for temporary coordination
bd wisp create agent-coordination

# Multiple agents work on wisp steps
# No git sync overhead
bd wisp cleanup --completed  # Clean up when done
```

**Pattern 4: Kiro Spec Integration**
```bash
# Map Kiro spec phases to beads workflow
bd pour kiro-spec-workflow --var feature=authentication

# Spec creation → bd create with type "spec"
# Task generation → bd create with type "task"
# Implementation → bd update --claim
# Completion → bd close
```

### Pinning Work to Agents
```bash
# Pin molecule to agent
bd pin bd-xyz --start

# Show pinned work
bd hook

# Release pin when done
bd pin bd-xyz --complete
```

### Session Management
```bash
# Start session
bd prime  # Load context

# During session
bd ready  # Find unblocked work
bd update <id> --claim  # Claim work
bd close <id> --reason "Completed"  # Complete work

# End session
bd sync  # Always run before ending
```

## 7. Integration Points

### NixOS Configuration Workflows

**Formula: `nixos-module-creation`**
```toml
formula = "nixos-module-creation"
description = "Create a new NixOS module"

[vars.module_name]
description = "Name of the module"
required = true

[[steps]]
id = "module-structure"
title = "Create module directory structure for {{module_name}}"

[[steps]]
id = "implementation"
title = "Implement {{module_name}} module logic"
needs = ["module-structure"]

[[steps]]
id = "tests"
title = "Write tests for {{module_name}}"
needs = ["implementation"]

[[steps]]
id = "documentation"
title = "Add documentation"
needs = ["tests"]

[[steps]]
id = "integration"
title = "Integrate into flake.nix"
needs = ["documentation"]
type = "human"
```

**Formula: `flake-update`**
```toml
formula = "flake-update"
description = "Update Nix flake inputs"

[[steps]]
id = "check-updates"
title = "Check for flake updates"

[[steps]]
id = "update-inputs"
title = "Update flake inputs"
needs = ["check-updates"]

[[steps]]
id = "test-build"
title = "Test build with updated inputs"
needs = ["update-inputs"]

[[steps]]
id = "commit-changes"
title = "Commit flake.lock changes"
needs = ["test-build"]
```

### Kiro Spec Workflow Mapping

| Kiro Phase | Beads Equivalent |
|------------|------------------|
| Specification | `bd create --type spec` |
| Requirements | Formula step: "requirements" |
| Design | Formula step: "design" (human gate) |
| Tasks | `bd create --type task` (children) |
| Implementation | `bd update --claim` |
| Validation | Formula step: "validation" |
| Completion | `bd close` |

**Formula: `kiro-spec-workflow`**
```toml
formula = "kiro-spec-workflow"
description = "Kiro-style spec-driven development workflow"

[vars.feature]
description = "Feature name"
required = true

[[steps]]
id = "spec-creation"
title = "Create spec for {{feature}}"
type = "human"

[[steps]]
id = "requirements"
title = "Define requirements"
needs = ["spec-creation"]

[[steps]]
id = "design"
title = "Create design"
needs = ["requirements"]
type = "human"

[[steps]]
id = "task-generation"
title = "Generate implementation tasks"
needs = ["design"]

[[steps]]
id = "implementation"
title = "Implement {{feature}}"
needs = ["task-generation"]

[[steps]]
id = "validation"
title = "Validate implementation"
needs = ["implementation"]
type = "human"

[[steps]]
id = "documentation"
title = "Update documentation"
needs = ["validation"]
```

### Project-Specific Workflows

**Formula: `hbohlen-systems-module`**
```toml
formula = "hbohlen-systems-module"
description = "Standard workflow for hbohlen-systems NixOS modules"

[vars.module]
description = "Module name (e.g., 'nginx', 'postgres')"
required = true

[vars.host]
description = "Target host"
default = "all"

[[steps]]
id = "module-scaffold"
title = "Scaffold {{module}} module in hbohlen-systems"

[[steps]]
id = "implementation"
title = "Implement {{module}} configuration"
needs = ["module-scaffold"]

[[steps]]
id = "host-integration"
title = "Integrate into {{host}} configuration"
needs = ["implementation"]

[[steps]]
id = "testing"
title = "Test on target host"
needs = ["host-integration"]

[[steps]]
id = "documentation"
title = "Update AGENTS.md with module details"
needs = ["testing"]
```

**Formula: `agent-skill-creation`**
```toml
formula = "agent-skill-creation"
description = "Create a new AI agent skill"

[vars.skill_name]
description = "Skill name"
required = true

[vars.agent]
description = "Target agent"
enum = ["opencode", "pi", "hermes"]

[[steps]]
id = "skill-structure"
title = "Create skill directory structure in .agents/skills/{{skill_name}}"

[[steps]]
id = "implementation"
title = "Implement {{skill_name}} skill logic"
needs = ["skill-structure"]

[[steps]]
id = "testing"
title = "Test skill with {{agent}}"
needs = ["implementation"]

[[steps]]
id = "documentation"
title = "Add skill documentation"
needs = ["testing"]

[[steps]]
id = "integration"
title = "Integrate skill into agent workflow"
needs = ["documentation"]
```

### Git Integration Best Practices
- **Git hooks**: `bd hooks install` sets up pre-commit, post-merge, pre-push hooks
- **Protected branches**: `bd init --branch beads-sync` creates separate sync branch
- **Worktree support**: Beads auto-uses embedded mode in worktrees
- **Conflict resolution**: `bd doctor --fix` checks and resolves conflicts
- **Duplicate detection**: `bd duplicates --auto-merge` after branch merges

### Session Workflow for hbohlen-systems
```bash
# Start development session
nix develop .#ai --command fish
bd prime  # Load beads context

# During session
bd ready  # Find unblocked work
bd update bd-xyz --claim  # Claim work
# ... implement NixOS module, Kiro spec, etc.
bd close bd-xyz --reason "Implemented"  # Complete

# Check progress
bd mol list  # View active workflows
bd stats  # See completion stats

# End session
bd sync  # Critical: sync before ending
```

### Multi-Agent Coordination
- **Route assignment**: Use `bd pin` to assign molecules to specific agents
- **Cross-repo dependencies**: Link issues across repositories
- **Shared formulas**: Store common formulas in `.beads/formulas/`
- **Wisps for coordination**: Use ephemeral wisps for temporary multi-agent tasks

---

## 8. References

### Official Documentation
- [Beads Workflows Documentation](https://gastownhall.github.io/beads/workflows) - Overview of workflow concepts and chemistry metaphor
- [Molecules Documentation](https://gastownhall.github.io/beads/workflows/molecules) - Work graph instances and lifecycle
- [Formulas Documentation](https://gastownhall.github.io/beads/workflows/formulas) - Declarative workflow templates in TOML/JSON
- [Gates Documentation](https://gastownhall.github.io/beads/workflows/gates) - Async coordination primitives (human, timer, GitHub)
- [Wisps Documentation](https://gastownhall.github.io/beads/workflows/wisps) - Ephemeral workflows and phase control

### Project Resources
- **Beads in devShell**: `nix develop .#ai --command bd --help`
- **Existing research**: `.kilo/worktrees/fluoridated-meteorology/.kilo/plans/*.md`
- **Core CLI Summary**: `docs/beads/core-cli-summary.md`
- **Kiro spec-driven development**: `.kiro/specs/` workflow integration
- **AGENTS.md**: Project AI workflow guidelines

### Key Concepts Recap
- **Chemistry metaphor**: Proto (formulas) → Mol (molecules) → Wisp (wisps)
- **Formulas**: Declarative templates for repeatable workflows
- **Molecules**: Persistent work graphs with step dependencies  
- **Gates**: Async coordination points (human approval, timers, events)
- **Wisps**: Ephemeral workflows for temporary operations
- **Phase control**: `bd mol bond` for liquid/vapor phase transitions

## Summary

Beads workflows provide a powerful, AI-friendly framework for structured task execution in the hbohlen-systems project. By leveraging formulas, molecules, gates, and wisps, agents can:

1. **Automate repetitive tasks** with declarative workflow templates
2. **Coordinate complex processes** with async gates and dependencies
3. **Track progress** through persistent molecules with git sync
4. **Execute ephemeral operations** without polluting git history
5. **Integrate with existing workflows** (NixOS modules, Kiro specs)

The chemistry metaphor (proto→mol→wisp) provides intuitive phase control, while deep Git integration ensures workflow state is properly versioned and synchronized across sessions.

**Key Takeaway**: Beads transforms ad-hoc agent work into structured, repeatable processes that can be tracked, coordinated, and optimized over time.