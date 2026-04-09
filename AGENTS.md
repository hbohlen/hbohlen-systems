# AGENTS.md — Repository Router

This file is a **router**. Follow the links below for the canonical source of each topic.

---

## Canonical agent workflow

→ **[`.agents/AGENTS.md`](.agents/AGENTS.md)** — full workflow rules, skill categories, folder policy

Key facts:
- `.agents/` is the canonical home for all agent workflow artifacts
- `.agents/skills/` is the canonical skill library (pi discovers this natively)
- `.agents/specs/` holds active feature specs
- `.agents/steering/` holds project-wide memory files

---

## Spec-driven development (quick reference)

```
/steering                       # bootstrap project memory
/spec-init "feature description" # start a new spec
/spec-requirements <feature>    # generate requirements
/spec-design <feature>          # generate design
/spec-tasks <feature>           # generate tasks
/spec-implement <feature>       # implement
/spec-status [feature]          # check progress
```

Full command table: see [`.agents/AGENTS.md`](.agents/AGENTS.md)

---

## Documentation

→ **[`docs/AGENTS.md`](docs/AGENTS.md)** — what belongs in `docs/`, archive policy, human-facing doc rules

---

## Issue tracking (Beads)

Skill: `.agents/skills/beads/`

```bash
bd ready --json          # find unblocked work
bd update <id> --claim   # claim an issue
bd sync                  # ALWAYS run at session end
```

---

## Legacy / adapter areas (non-canonical)

| Path | Status | Notes |
|------|--------|-------|
| `.opencode/commands/` | adapter | thin wrappers over `.agents/skills/spec/` |
| `.pi/prompts/` | adapter | opsx prompts only |
| `.hermes/skills/` | adapter | hermes-specific, not canonical |
| `.kiro/` | **removed** | migrated to `.agents/` — see `docs/reports/spec-workflow-migration.md` |

---

## Session completion (mandatory)

1. File issues for remaining work (`bd create ...`)
2. Run quality gates if code changed
3. Close finished issues (`bd close <id> --reason "..."`)
4. Sync and push:
   ```bash
   git pull --rebase && bd sync && git push
   ```
