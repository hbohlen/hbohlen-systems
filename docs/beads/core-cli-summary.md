# Beads Core & CLI Documentation Summary

## 0. Setup and Initialization

### Project Setup
```bash
# Initialize beads in project (use --quiet for AI agents to avoid prompts)
bd init --quiet

# Install git hooks (recommended)
bd hooks install

# Check installation health
bd doctor --fix
```

### Quick Start Example
```bash
# 1. Initialize (if not already done)
bd init --quiet

# 2. Create your first issues
bd create "Set up database" -p 1 -t task
bd create "Create API" -p 2 -t feature
bd create "Add authentication" -p 2 -t feature

# 3. Add dependencies
bd dep add bd-2 bd-1  # API depends on database
bd dep add bd-3 bd-2  # Auth depends on API

# 4. Find ready work
bd ready  # Shows only bd-1 (database)

# 5. Work the queue
bd update bd-1 --claim
# ... implement ...
bd close bd-1 --reason "Database setup complete"

# 6. Check ready work again
bd ready  # Now shows bd-2 (API)
```

### Database Configuration
By default, beads uses Dolt (version-controlled SQL database):
- Database: `.beads/dolt/` (gitignored)
- Config: `.beads/config.toml` (git-tracked)
- Metadata: `.beads/metadata.json` (git-tracked)

### Integration with NixOS devShell
Beads is already available in the `hbohlen-systems` devShell:
```bash
# Access beads through devShell
nix develop .#ai --command bd --help

# Or enter devShell first
nix develop .#ai
bd --help
```

## 1. Introduction/Overview

**Beads** (`bd`) is a git-backed, AI-native issue tracker designed for AI-supervised coding workflows. It uses **Dolt** (a version-controlled SQL database) as its backend, enabling collaboration via Dolt-native replication while maintaining local-first operation.

### Why Beads for AI Workflows?
- **Hash-based IDs** (e.g., `bd-a1b2`) prevent collisions when multiple agents work concurrently
- **JSON-first output** with `--json` flag for programmatic access by AI agents
- **Dependency-aware execution** - `bd ready` shows only unblocked work
- **Declarative workflows** with Formulas, Molecules, and Gates for complex coordination
- **Deep Git integration** with hooks, worktrees, and branch-aware workflows



## 2. Key Concepts

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

### Architecture
```
Dolt DB (.beads/dolt/, gitignored)
    ↕ dolt commit
Local Dolt history
    ↕ dolt push/pull
Remote Dolt repository (shared across machines)
```

The database uses Dolt's version-controlled SQL database with built-in replication for multi-writer access.

### Advanced Concepts
- **Formulas**: Declarative workflow templates (TOML/JSON) for repeatable patterns
- **Molecules**: Persistent instances of formulas - work graphs with steps and dependencies
- **Gates**: Async coordination primitives (human approval, timers, GitHub events)
- **Aspects**: Cross-cutting concerns that inject steps into matching workflows

## 3. Essential Commands

### Core Issue Management

```bash
# Create issues
bd create "Title" -t task -p 1 --description "Details"
bd create "Epic" -t epic --parent bd-42  # Hierarchical IDs

# List and search
bd list --status open --priority 1 --type bug --json
bd search "authentication" --status open

# Show details
bd show bd-42 --json
bd show bd-42 --full  # Includes comments

# Update issues
bd update bd-42 --claim  # Start work
bd update bd-42 --priority 0 --add-label urgent
bd update bd-42 --title "Updated" --description "New details"

# Close issues
bd close bd-42 --reason "Fixed in PR #123"
bd reopen bd-42  # Reopen closed issue
```

### Dependency Management

```bash
# Add dependencies
bd dep add bd-2 bd-1  # bd-2 depends on bd-1
bd dep add bd-2 bd-1 --type related  # Soft relationship

# Remove dependencies
bd dep remove bd-2 bd-1

# View dependencies
bd dep tree bd-42 --depth 3
bd dep cycles  # Detect circular dependencies

# Ready and blocked work
bd ready --priority 1 --type task --json
bd blocked --json

# Hierarchical issues (epics)
bd create "Auth System" -t epic -p 1  # Returns bd-a3f8e9
bd create "Design login UI" --parent bd-a3f8e9  # Auto-numbers: bd-a3f8e9.1
```

### Labels and Comments

```bash
# Label management
bd create "Task" -l "backend,urgent"
bd update bd-42 --add-label "security,needs-review"
bd update bd-42 --remove-label urgent
bd label list --json

# Filter by labels
bd list --label-any urgent,critical  # OR filter
bd list --label-all backend,security  # AND filter

# Comment management
bd comment add bd-42 "Working on this now"
bd comment list bd-42 --json
```

### Sync and Data Management

```bash
# Full sync cycle (Dolt commit + push)
bd sync  # ALWAYS run at end of work session

# Export/Import for backup/migration
bd export -o backup.jsonl
bd import -i backup.jsonl --orphan-handling resurrect

# Database maintenance
bd migrate --inspect --json
bd hooks install  # Install git hooks for auto-sync
bd doctor --fix  # Check and fix installation

# System information
bd info --whats-new
bd stats --json
```

### Advanced Workflow Commands

```bash
# Formulas and Molecules
bd pour auth-system-formula --var environment=production
bd mol list --json
bd mol show mol-abc --json

# Gate management
bd gate approve gate-123 --approver "alice"
bd gate skip gate-456 --reason "Emergency bypass"

# Agent coordination
bd pin bd-42 --start  # Assign work to agent
bd audit --json  # Record agent interactions
```

## 4. AI Agent Best Practices

### Quick Reference Table for AI Agents

| Command | Purpose | AI Agent Usage |
|---------|---------|---------------|
| `bd ready --json` | Find unblocked work | **Start here** - always check for ready work before starting |
| `bd create "Title" --type task --json` | Create new issue | Include `--description` for context, use `--deps discovered-from:<parent>` for discovered work |
| `bd show bd-42 --json` | View issue details | Parse JSON to understand issue context and requirements |
| `bd update bd-42 --claim --json` | Start working on issue | Signal that you're actively working on this issue |
| `bd close bd-42 --reason "Completed" --json` | Complete issue | Always provide a reason for closure |
| `bd sync` | Sync database changes | **CRITICAL** - always run at end of work session |
| `bd list --status open --json` | List open issues | Filter by priority, type, or labels as needed |
| `bd blocked --json` | Check blocked issues | Understand why work isn't ready |
| `bd dep tree bd-42 --json` | View dependencies | Understand issue context and relationships |
| `bd prime` | Get workflow context | Run at start of session for AI-optimized context |


### Always Use `--json` Flag
```bash
# Programmatic access for AI agents
bd list --json
bd create "Task" -t task --json
bd show bd-42 --json
bd ready --json
bd blocked --json
bd update bd-42 --claim --json
bd close bd-42 --reason "Completed" --json
```

### Workflow Patterns for AI Agents

**Discovery Workflow:**
```bash
# When discovering new work during implementation
bd create "Found SQL injection" -t bug -p 0 \
  --description "Vulnerability in auth.go:45" \
  --deps discovered-from:bd-42 --json
```

**Dependency-Aware Execution:**
```bash
# Check for ready work before starting
READY_ISSUES=$(bd ready --json | jq -r '.[].id')
if [ -n "$READY_ISSUES" ]; then
  bd update $FIRST_ISSUE --claim --json
fi
```

**Session Management:**
```bash
# Start of session
bd prime  # Output AI-optimized workflow context
bd ready --json  # Check available work

# During session
bd update bd-42 --claim --json  # Claim work
# ... implement changes ...
bd close bd-42 --reason "Implemented" --json  # Complete work

# End of session (CRITICAL)
bd sync  # Always sync before ending session
```

### Configuration for AI Editors

```bash
# Setup Claude Code integration
bd setup claude

# Hooks configuration for auto-sync
{
  "hooks": {
    "SessionStart": ["bd prime"],
    "PreCompact": ["bd sync"]
  }
}
```

### Sandbox and Safety Features
```bash
# Read-only mode for worker sandboxes
bd list --json --readonly

# Disable auto-sync for testing
bd create "Test" --json --sandbox

# Force direct storage mode
bd list --json --no-daemon
```

### Git-Free Usage for AI Agents
Beads supports git-free operation for AI agents working in ephemeral environments or when git integration isn't needed:

```bash
# Sandbox mode - operate without git integration, disables daemon and auto-sync
bd --sandbox create "Task" -t task --json
bd --sandbox list --json

# No-database mode - load from JSONL files only
bd --no-db list --json
bd --no-db create "Quick task" --json

# Ephemeral worktrees and CI environments
# Beads auto-detects worktrees and uses embedded mode
nix develop .#ai --command bd create "CI task" --json
```

**When to use git-free mode:**
- **CI/CD pipelines**: No persistent database needed
- **Ephemeral containers**: Stateless execution environments  
- **Quick prototyping**: Temporary issue tracking without git history
- **Agent sandboxes**: Isolated testing environments

**Git-free workflow example:**
```bash
# Start session in sandbox mode
bd --sandbox prime

# Create and work on issues
bd --sandbox create "Analyze code" -t task --json
bd --sandbox update bd-xxx --claim --json
# ... work ...
bd --sandbox close bd-xxx --reason "Done" --json

# Export results if needed
bd --sandbox export -o results.jsonl
```

**Note**: In git-free mode, issues are stored in-memory or temporary files and won't persist across sessions. Use regular `bd sync` for persistent issue tracking.

## 5. Integration Points

### NixOS Integration
Beads is available via the `llm-agents.nix` flake input (v0.63.3):
```nix
# In parts/devshell.nix, already included in devShells.ai packages:
llm-agents-packages.beads
```

**NixOS-specific patterns:**
- Issue types for: `nixos-module`, `home-manager`, `flake-update`, `devshell`
- Labels: `nixos`, `home-manager`, `flake`, `devshell`, `ci-nix`
- Formulas for common NixOS workflows

### Kiro Spec-Driven Development Integration

**Mapping Kiro workflow to beads:**
1. **Spec creation** → `bd create "Feature: X" -t epic --description "Kiro spec" --label "kiro-spec"`
2. **Task generation** → `bd create "Implement Y" -t task --parent bd-epic --label "kiro-task"`
3. **Implementation** → `bd update bd-task --claim --json`
4. **Completion** → `bd close bd-task --reason "Kiro spec implemented"`

**Suggested label conventions for Kiro:**
- `kiro-spec`, `kiro-task`, `kiro-validation`, `kiro-phase1`, `kiro-phase2`
- Dependency type: `discovered-from` for tasks discovered during spec analysis

### Project Workflow Integration

**Daily Agent Workflow:**
```bash
# 1. Enter devShell
nix develop .#ai

# 2. Check ready work
bd ready --json

# 3. Claim and work on issue
bd update bd-42 --claim --json
# ... implement ...

# 4. Close and sync
bd close bd-42 --reason "Completed" --json
bd sync
```

**Git Workflow Integration:**
- Install hooks: `bd hooks install`
- Protected branches: `bd init --branch beads-sync` creates separate sync branch
- Worktree support: Beads auto-uses embedded mode in worktrees
- Conflict resolution: `bd doctor --fix` after git merges

### Comparison: Beads vs Linear for AI Workflows

| Aspect | Beads | Linear |
|--------|-------|--------|
| Self-hosted | ✅ (Dolt local/remote) | ❌ |
| NixOS integration | ✅ Via nixpkgs/llm-agents | ❌ No nixpkgs |
| AI agent native | ✅ JSON, hash IDs, deps | ⚠️ API-based |
| Git-free usage | ✅ `--stealth` mode | ❌ |
| Offline capable | ✅ (embedded Dolt) | ❌ |
| Setup complexity | Low (already in flake) | Medium (SaaS signup) |
| Collaboration | Dolt push/pull | Built-in |
| Cost | Free (open source) | Paid subscription |

## 6. References and Links

### Official Documentation
- [Beads Documentation](https://gastownhall.github.io/beads/)
- [Quick Start Guide](https://gastownhall.github.io/beads/getting-started/quickstart)
- [Core Concepts](https://gastownhall.github.io/beads/core-concepts)
- [Issues & Dependencies](https://gastownhall.github.io/beads/core-concepts/issues)
- [CLI Reference: Essential](https://gastownhall.github.io/beads/cli-reference/essential)
- [CLI Reference: Issues](https://gastownhall.github.io/beads/cli-reference/issues)
- [CLI Reference: Dependencies](https://gastownhall.github.io/beads/cli-reference/dependencies)
- [CLI Reference: Labels](https://gastownhall.github.io/beads/cli-reference/labels)
- [CLI Reference: Sync](https://gastownhall.github.io/beads/cli-reference/sync)

### Project Resources
- Existing research: `.kilo/worktrees/fluoridated-meteorology/.kilo/plans/*.md`
- Beads in devShell: `nix develop .#ai --command bd --help`
- AGENTS.md: Project AI workflow guidelines
- Kiro specs: `.kiro/specs/` for spec-driven development

### Key Takeaways for AI Agents
1. **Always use `--json`** for programmatic access
2. **Always run `bd sync`** at end of work session
3. Use `bd ready` to find unblocked work
4. Track discovered work with `--deps discovered-from:<parent>`
5. Hierarchical IDs for epics: `bd-a3f8e9.1`, `bd-a3f8e9.2`
6. Dolt handles sync - no manual git operations needed for issue data

### Common Pitfalls to Avoid
- Forgetting to `bd sync` at session end (data loss risk)
- Not using `--json` for AI agent workflows
- Creating circular dependencies (check with `bd dep cycles`)
- Over-labeling issues (2-4 labels typical)
- Working on blocked issues (always check `bd ready` first)

---

*This document summarizes beads v0.63.3 as integrated in the hbohlen-systems NixOS configuration repository. Last updated based on documentation from February 2026.*

