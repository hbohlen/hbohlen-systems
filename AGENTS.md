# AI-DLC and Spec-Driven Development

Kiro-style Spec Driven Development implementation on AI-DLC (AI Development Life Cycle)

## Project Context

### Paths
- Steering: `.kiro/steering/`
- Specs: `.kiro/specs/`

### Steering vs Specification

**Steering** (`.kiro/steering/`) - Guide AI with project-wide rules and context
**Specs** (`.kiro/specs/`) - Formalize development process for individual features

### Active Specifications
- Check `.kiro/specs/` for active specifications
- Use `/kiro-spec-status [feature-name]` to check progress

## Development Guidelines
- Think in English, generate responses in English. All Markdown content written to project files (e.g., requirements.md, design.md, tasks.md, research.md, validation reports) MUST be written in the target language configured for this specification (see spec.json.language).

## Minimal Workflow
- Phase 0 (optional): `/kiro-steering`, `/kiro-steering-custom`
- Phase 1 (Specification):
  - `/kiro-spec-init "description"`
  - `/kiro-spec-requirements {feature}`
  - `/kiro-validate-gap {feature}` (optional: for existing codebase)
  - `/kiro-spec-design {feature} [-y]`
  - `/kiro-validate-design {feature}` (optional: design review)
  - `/kiro-spec-tasks {feature} [-y]`
- Phase 2 (Implementation): `/kiro-spec-impl {feature} [tasks]`
  - `/kiro-validate-impl {feature}` (optional: after implementation)
- Progress check: `/kiro-spec-status {feature}` (use anytime)

## Development Rules
- 3-phase approval workflow: Requirements → Design → Tasks → Implementation
- Human review required each phase; use `-y` only for intentional fast-track
- Keep steering current and verify alignment with `/kiro-spec-status`
- Follow the user's instructions precisely, and within that scope act autonomously: gather the necessary context and complete the requested work end-to-end in this run, asking questions only when essential information is missing or the instructions are critically ambiguous.

## Issue Tracking with Beads

This project uses **beads (`bd`)** for AI-native issue tracking. Beads is a git-backed issue tracker designed for AI-supervised coding workflows, using Dolt (version-controlled SQL database) as its backend.

### Quick Reference

| Command | Purpose | AI Agent Usage |
|---------|---------|---------------|
| `bd ready --json` | Find unblocked work | **Start here** - always check before starting work |
| `bd create "Title" --type task --json` | Create new issue | Include `--description` for context, use `--deps discovered-from:<parent>` for discovered work |
| `bd show bd-42 --json` | View issue details | Parse JSON to understand requirements |
| `bd update bd-42 --claim --json` | Start working on issue | Signal active work on this issue |
| `bd close bd-42 --reason "Completed" --json` | Complete issue | Always provide detailed reason |
| `bd sync` | Sync database changes | **CRITICAL** - always run at end of work session |
| `bd list --status open --json` | List open issues | Filter by priority, type, or labels |
| `bd blocked --json` | Check blocked issues | Understand why work isn't ready |
| `bd dep tree bd-42 --json` | View dependencies | Understand issue relationships |
| `bd prime` | Get workflow context | Run at start of session for AI-optimized context |

### Essential Workflow for AI Agents

1. **Start of session:**
   ```bash
   nix develop .#ai
   bd prime
   bd ready --json
   ```

2. **During work:**
   ```bash
   # Claim work
   ISSUE_ID=$(bd ready --json | jq -r '.[0].id')
   bd update $ISSUE_ID --claim --json
   
   # Track discovered work
   bd create "Found issue" -t bug --deps discovered-from:$ISSUE_ID --json
   
   # Update progress
   bd update $ISSUE_ID --add-label "in-progress" --json
   ```

3. **End of session (MANDATORY):**
   ```bash
   bd close $ISSUE_ID --reason "Implemented with tests" --json
   bd sync  # CRITICAL: Always sync before ending session
   ```

### AI Agent Best Practices

1. **Always use `--json` flag** for programmatic access and parsing
2. **Always run `bd sync`** at end of work session (data preservation)
3. **Start with `bd ready`** to find unblocked work before starting
4. **Track discoveries** with `--deps discovered-from:<parent>` when finding new work
5. **Use appropriate issue types**: `task` (implementation), `feature` (new functionality), `bug` (defects), `epic` (large features), `chore` (maintenance)
6. **Set realistic priorities**: 0 (critical), 1 (high), 2 (normal), 3 (low), 4 (backlog)
7. **Apply 2-4 relevant labels** for filtering (NixOS-specific labels below)

### Integration with Kiro Specs

**Mapping Kiro workflow to beads:**
```
Kiro Phase           → Beads Command
─────────────────────────────────────────────
Spec creation        → bd create "Feature: X" -t epic --label "kiro-spec"
Requirements         → bd create "Requirements" -t task --parent <epic>
Design               → bd create "Design" -t task --parent <epic>
Task generation      → bd create "Implement Y" -t task --parent <epic>
Implementation       → bd update <task> --claim --json
Validation           → bd create "Validate" -t task --parent <epic>
Completion           → bd close <task> --reason "Kiro spec implemented"
```

**Label conventions for Kiro:**
- `kiro-spec`, `kiro-requirements`, `kiro-design`, `kiro-tasks`, `kiro-implementation`
- `kiro-validation`, `kiro-phase1`, `kiro-phase2`, `kiro-phase3`

### NixOS-Specific Patterns

**Issue types for NixOS workflows:**
- `nixos-module`: New NixOS module development
- `home-manager`: Home-manager configuration
- `flake-update`: Flake input updates
- `devshell`: DevShell configuration changes

**Suggested labels:**
- `nixos`, `home-manager`, `flake`, `devshell`, `ci-nix`
- `security`, `performance`, `refactor`, `documentation`

**Example NixOS module issue:**
```bash
bd create "Create NixOS module for tailscale" \
  -t task -p 2 \
  --description "Implement tailscale.nix module with auth key management" \
  --label "nixos-module,security,networking" \
  --json
```

### Beads vs Linear Comparison

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

### Advanced Features

**Workflow Orchestration:**
- **Formulas**: Declarative workflow templates for repeatable tasks
- **Molecules**: Persistent work graphs with step dependencies
- **Gates**: Async coordination (human approval, timers, GitHub events)
- **Wisps**: Ephemeral workflows that don't sync to git

**Multi-Agent Coordination:**
- **Routing**: Pattern-based issue routing across repositories
- **Pinning**: Assign work to specific agents
- **File reservations**: Prevent concurrent edits
- **Cross-repo dependencies**: Track dependencies across repository boundaries

### Skills and Resources

**Skill files location:**
- `.agents/skills/beads/` (for opencode/pi agents)
- `.hermes/skills/beads/` (for hermes-agent)

**Available skills:**
1. **Core Issue Management** - Basic issue lifecycle
2. **Dependency Management** - Issue relationships and ready work
3. **Sync & Data Management** - Database synchronization (CRITICAL)
4. **Workflow Orchestration** - Formulas, molecules, gates, wisps
5. **Multi-agent Coordination** - Routing, pinning, coordination
6. **Configuration & Advanced** - Project-specific configuration

**Documentation:**
- `docs/beads/` - Comprehensive beads documentation
- `docs/beads/beads-knowledge-base.md` - Complete reference
- `docs/beads/skill-definitions.md` - Detailed skill definitions

### Common Pitfalls to Avoid

1. **Forgetting to `bd sync`** at session end (risk of data loss)
2. **Not using `--json` flag** for AI agent workflows
3. **Creating circular dependencies** (check with `bd dep cycles`)
4. **Over-labeling issues** (2-4 labels typical)
5. **Working on blocked issues** (always check `bd ready` first)
6. **Insufficient descriptions** (always provide context for future agents)

### Setup and Configuration

Beads is already available in the devShell:
```bash
# Access beads through devShell
nix develop .#ai --command bd --help

# Initialize beads in project
bd init --quiet
bd hooks install  # Recommended for auto-sync

# Check installation health
bd doctor --fix
```

**Configuration file**: `.beads/config.toml` (committed to git)
**Database**: `.beads/dolt/` (Dolt version-controlled SQL database)

## Steering Configuration
- Load entire `.kiro/steering/` as project memory
- Default files: `product.md`, `tech.md`, `structure.md`
- Custom files are supported (managed via `/kiro-steering-custom`)

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
