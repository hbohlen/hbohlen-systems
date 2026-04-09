# AGENTS.md — `docs/` Policy

This file defines what belongs in `docs/`, how documentation is organized, and how agents should interact with it.

---

## Allowed structure under `docs/`

| Path | Purpose |
|------|---------|
| `AGENTS.md` | This file — documentation policy |
| `CONVENTIONS.md` | Folder ownership rules and decision guidance |
| `architecture/` | Durable architecture decisions and system diagrams |
| `runbooks/` | Operational runbooks for common tasks |
| `reference/` | Reference documentation (API docs, schemas, glossaries) |
| `reports/` | Agent-generated reports, migration summaries, audits |
| `archive/` | Superseded or historical docs (keep, don't delete) |

**Do not put the following in `docs/`:**
- Active agent specs → `.agents/specs/`
- Canonical skill files → `.agents/skills/`
- Steering project memory → `.agents/steering/`
- Build artifacts, secrets, NixOS config

---

## Active vs archive

**Active docs** (`architecture/`, `runbooks/`, `reference/`):
- Reflect the current state of the system
- Should be updated when the system changes
- Agents may update these as part of implementation tasks

**Archive** (`archive/`):
- Historical designs, superseded plans, migration context
- Never delete — move here instead
- Agents should not update archived docs (create a new doc instead)

**Reports** (`reports/`):
- Agent-generated one-time summaries (migration reports, audits)
- Date-stamped preferred for disambiguation
- Not maintained over time — create a new report instead of updating

---

## Legacy paths (being consolidated)

| Path | Status | Notes |
|------|--------|-------|
| `docs/beads/` | active reference | beads CLI knowledge base and skills |
| `docs/plans/` | → move to `docs/archive/` | historical implementation plans |
| `docs/superpowers/` | → move to `docs/archive/` | historical superpowers docs |

---

## Instructions for agents

- **Do not** create active specs or canonical skills in `docs/`
- **Do** put one-time migration reports in `docs/reports/`
- **Do** move superseded docs to `docs/archive/` rather than deleting
- **Do** update `docs/CONVENTIONS.md` if folder policy changes
- When in doubt: active operational doc → appropriate subdir; historical → `archive/`
