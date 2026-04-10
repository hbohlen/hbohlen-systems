# Beads Documentation and Reference

This directory contains reference documentation and test utilities for Beads, the git-backed issue tracker that powers the hbohlen-systems development workflow.

## Canonical Skills

**For daily beads operations**, use the canonical agent skills:

- **[`beads-workflow`](.agents/skills/beads/beads-workflow/SKILL.md)** — Daily operations (find work, claim issues, close tasks, sync)
  - Essential for: Session workflows, issue management, work tracking
  - Commands: `bd ready`, `bd create`, `bd update`, `bd close`, `bd sync`

- **[`dolt-operations`](.agents/skills/beads/dolt-operations/SKILL.md)** — Direct Dolt database operations
  - Essential for: Schema inspection, SQL queries, data migration, conflict resolution
  - Commands: `dolt sql`, `dolt diff`, `dolt schema`, database operations

## Reference Documentation

This directory contains comprehensive reference material for human readers:

### Core Documents

- **`beads-knowledge-base.md`** — Comprehensive guide covering:
  - Architecture and core concepts
  - Essential commands reference
  - Workflow system (Formulas, Molecules, Gates, Wisps)
  - Multi-agent coordination patterns
  - Configuration and setup
  - NixOS integration
  - 8 skill domains definition

### Complementary Skill References

The `.agents/skills/beads/` directory contains detailed reference documentation organized by topic:

- **`core.md`** — Basic issue lifecycle (creation, viewing, updating, closing)
- **`config.md`** — Beads configuration and NixOS setup
- **`sync.md`** — Database synchronization and data integrity
- **`workflows.md`** — Formulas, Molecules, Gates, Wisps for complex workflows
- **`dependencies.md`** — Dependency management and ready work identification
- **`multi-agent.md`** — Multi-agent coordination and routing patterns

## Test Utilities

### Testing Scripts

- **`test-beads-basic.sh`** — Basic functionality test without external dependencies
  - Tests: Issue creation, listing, closing, dependency management
  - Run: `bash docs/beads/test-beads-basic.sh`
  
- **`test-beads.sh`** — Full feature test suite with jq processing
  - Tests: All beads commands with JSON output parsing
  - Run: `bash docs/beads/test-beads.sh`

### Running Tests

```bash
# Basic test (minimal dependencies)
nix develop .#ai --command bash docs/beads/test-beads-basic.sh

# Full test (requires jq)
nix develop .#ai --command bash docs/beads/test-beads.sh
```

## Quick Navigation

| Need | Go To |
|------|-------|
| How do I start a work session? | [`beads-workflow`](.agents/skills/beads/beads-workflow/SKILL.md) |
| How do I find ready work? | [`beads-workflow` → Finding Work](.agents/skills/beads/beads-workflow/SKILL.md#finding-work) |
| How do I query the database? | [`dolt-operations` → Querying Issue Data](.agents/skills/beads/dolt-operations/SKILL.md#querying-issue-data) |
| What's the full architecture? | `beads-knowledge-base.md` |
| How do dependencies work? | `.agents/skills/beads/dependencies.md` |
| How do I set up beads for NixOS? | `.agents/skills/beads/config.md` |
| What are Formulas and Molecules? | `.agents/skills/beads/workflows.md` |
| How do I coordinate multiple agents? | `.agents/skills/beads/multi-agent.md` |

## Key Principle

> **Always use `--json` for programmatic access** by agents.

Example:
```bash
bd ready --json        # ✅ Good: parseable output
bd list --status open  # ❌ Bad: human-readable format
```

## Session Workflow at a Glance

```bash
# Start: Find ready work
bd ready --json | jq -r '.[0].id'

# Middle: Work on issue
bd update <issue> --claim --json
# ... implement ...

# End: Close and sync
bd close <issue> --reason "..." --json
bd sync  # CRITICAL: Always sync at session end
```

## For AI Agents

When working through `.agents/skills/`:

1. **Start**: Use `/beads-workflow` for daily operations and session management
2. **Discover**: Use `/dolt-operations` for complex queries or database troubleshooting
3. **Reference**: Check this directory's companion files for detailed domain knowledge

## For Humans

- **Getting started**: Read `beads-knowledge-base.md` sections 1-3
- **Advanced workflows**: Read `beads-knowledge-base.md` sections 7-8 and skill docs
- **Troubleshooting**: See Troubleshooting sections in skill docs
- **Architecture deep-dive**: Read skill reference docs in `.agents/skills/beads/`

---

**Last updated**: April 2026
**Beads version**: v0.63.3 (via `llm-agents.nix` flake input)
**Location**: Part of hbohlen-systems development infrastructure
