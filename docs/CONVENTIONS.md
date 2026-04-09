# Documentation and Agent Conventions

This file defines folder ownership and decision rules for both humans and agents navigating this repository.

---

## Folder ownership

### `.agents/` — canonical agent workflow artifacts

**Owns:**
- `skills/` — all canonical agent skills
- `steering/` — project-wide memory loaded by spec-driven commands
- `specs/` — active and completed feature specifications
- `templates/` — spec and steering templates used by skills
- `rules/` — authoring rules used by skills
- `inventories/` — migration maps and inventories

**Does not own:**
- Human-facing documentation (→ `docs/`)
- Tool-specific adapters (→ `.opencode/`, `.hermes/`, `.pi/`)

### `docs/` — human-facing durable documentation

**Owns:**
- `architecture/` — system-level design decisions and diagrams
- `runbooks/` — operational how-to guides
- `reference/` — reference material (APIs, schemas, glossaries)
- `reports/` — one-time agent-generated reports and audits
- `archive/` — superseded or historical documentation
- `beads/` — beads CLI knowledge base (reference)

**Does not own:**
- Active agent specs (→ `.agents/specs/`)
- Canonical skill files (→ `.agents/skills/`)
- Steering project memory (→ `.agents/steering/`)

---

## Canonical vs adapter

| Concept | Canonical location | Adapter locations |
|---------|-------------------|-------------------|
| Spec workflow | `.agents/skills/spec/` | `.opencode/commands/spec-*.md` |
| Beads workflow | `.agents/skills/beads/` | `.hermes/skills/beads/` |
| Devops skills | `.agents/skills/devops/` | `.hermes/skills/devops/` |
| Steering docs | `.agents/steering/` | — |
| Feature specs | `.agents/specs/` | — |

**Rule:** The canonical location is always the source of truth. Adapter files must delegate to or summarize the canonical skill — they must not duplicate or contradict it.

---

## When to move, archive, regenerate, or delete

| Situation | Action |
|-----------|--------|
| Doc is superseded by a new design | Move old doc to `docs/archive/` |
| Spec is complete or abandoned | Leave in `.agents/specs/`, set `spec.json` phase |
| Adapter duplicates canonical content | Slim the adapter to a thin delegation |
| Legacy path referenced in other files | Update references, then move/remove |
| Historical plan or runbook | Move to `docs/archive/` |
| Clear duplicate with no historical value | Delete (with commit message explaining why) |

---

## Steering vs specification

| Concept | Location | Purpose |
|---------|----------|---------|
| **Steering** | `.agents/steering/` | Project-wide memory (product, tech, structure) — guides all agent decisions |
| **Specs** | `.agents/specs/` | Feature-specific requirements, design, tasks — time-bounded per feature |

Steering is always current. Specs are per-feature and may be completed or abandoned.

---

## What agents should check before creating documentation

1. Does a canonical skill already cover this? → Reference it, don't duplicate.
2. Is this a feature spec? → Use `/spec-init` and put it in `.agents/specs/`.
3. Is this a durable human doc? → Put it in the appropriate `docs/` subdir.
4. Is this a one-time report or audit? → Put it in `docs/reports/`.
5. Is this superseding an existing doc? → Archive the old one first.
