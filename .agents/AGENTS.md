# Agent Instructions — `.agents/`

`.agents/` is the canonical home for agent workflow artifacts in this repository.
**pi** discovers `.agents/skills/` natively via recursive directory traversal.

> **Before starting any work**: Read `.agents/steering/` (product.md, tech.md, structure.md). These files are project memory that guide all agent decisions, architectural choices, and development standards.

---

## Allowed structure under `.agents/`

| Path | Purpose |
|------|---------|
| `AGENTS.md` | This file — workflow rules and folder policy |
| `skills/` | All canonical agent skills, grouped by category |
| `steering/` | Project-wide memory files loaded by spec-driven commands |
| `specs/` | Active and completed feature specifications |
| `templates/` | Spec and steering templates used by skills |
| `rules/` | Authoring rules used by skills (EARS, design principles, etc.) |
| `inventories/` | Migration maps and cross-cutting inventories |

**Nothing else belongs at the top level of `.agents/`.**

---

## Skill categories

| Category | Path | Purpose |
|----------|------|---------|
| `spec` | `.agents/skills/spec/` | Spec-driven development workflow (canonical) |
| `devops` | `.agents/skills/devops/` | Server hardening, deployment safety, infrastructure |
| `nix` | `.agents/skills/nix/` | NixOS, Nix flakes, devshells, remote installs |
| `opnix` | `.agents/skills/opnix/` | 1Password secret injection into NixOS/Home Manager |
| `openspec` | `.agents/skills/openspec/` | OpenSpec workflow (propose, explore, apply, archive) |
| `beads` | `.agents/skills/beads/` | Beads issue tracker system (workflows and core logic, not individual skills) |
| `personal` | `.agents/skills/personal/` | Personal workflow and productivity |
| `diagrams` | `.agents/skills/diagrams/` | Mermaid diagram authoring for architecture and workflows |

> **Note on Beads**: The beads category contains system documentation (workflows, core logic, config) rather than individual SKILL.md-based tasks. Use beads skills via `bd` command-line tool, not `/skill` invocation.

---

## Spec-driven workflow commands

The spec-driven workflow lives at `.agents/skills/spec/`. Commands (generic names, no `kiro-` prefix):

| Command | Purpose |
|---------|---------|
| `/steering` | Bootstrap or refresh project steering files |
| `/steering-custom` | Add a domain-specific custom steering file |
| `/spec-init "<desc>"` | Initialize a new feature spec |
| `/spec-requirements <feature>` | Generate EARS requirements |
| `/spec-validate-gap <feature>` | Gap analysis against existing code (optional) |
| `/spec-design <feature> [-y]` | Generate technical design |
| `/spec-validate-design <feature>` | Design quality review (optional) |
| `/spec-tasks <feature> [-y]` | Generate implementation task list |
| `/spec-implement <feature> [tasks]` | Execute implementation tasks |
| `/spec-validate-implementation <feature>` | Post-implementation validation (optional) |
| `/spec-status [feature]` | Check spec progress |

### Canonical paths

| Concept | Path |
|---------|------|
| Steering documents | `.agents/steering/` |
| Active specs | `.agents/specs/` |
| Spec/steering templates | `.agents/templates/` |
| Authoring rules | `.agents/rules/` |

---

## Adding a skill

1. Create: `.agents/skills/<category>/<skill-name>/`
2. Create `SKILL.md` with required frontmatter: `name`, `description`; optional: `tags`, `category`, `metadata`
3. The `name` field must match the directory name exactly
4. Reference companion files from `SKILL.md` using relative paths

---

## Archive Structure

The `/archive/` directory preserves historical work and previous iterations. It is **append-only**; nothing is deleted.

| Path | Purpose |
|------|---------|
| `/archive/openspec/` | Deprecated OpenSpec experiments and iterations |
| `/archive/plans/` | Previous project plans and planning documents |
| `/archive/superpowers/` | Experimental agent integrations and capabilities |

**Convention**: Archive entries are timestamped or versioned. When archiving, include a `README.md` explaining what was archived and why. Archive informs future decisions.

## Tool compatibility

- **pi**: Discovers `.agents/skills/` natively — no adapter needed
- **OpenCode**: Thin adapters in `.opencode/commands/` delegate to `.agents/skills/spec/**` skills
- **Hermes**: Uses `.hermes/skills/` — separate adapter layer, not canonical

---

## What does NOT belong in `.agents/`

- **Human-facing documentation** → `docs/` (see `/docs/AGENTS.md` for guidelines)
- **Hermes-specific adapters** → `.hermes/`
- **OpenCode-specific adapters** → `.opencode/`
- **Build artifacts, NixOS config, secrets** → their respective top-level directories
- **Agent-specific tool integrations** (e.g., `.cursor/`, `.gemini/`, `.claude/`) → Use `.agents/steering/` and `.agents/rules/` instead; all agent context lives in `.agents/`

---

## Alignment with Project Steering

All workflows under `.agents/` follow the project's **dendritic architecture** and **spec-driven development philosophy** (see `.agents/steering/`):

- **Dendritic**: Skills grow as peer modules, not nested hierarchies. New skills are added to existing categories, not under new categories.
- **Spec-Driven**: Significant infrastructure changes flow through `.agents/specs/` workflow (requirements → design → tasks → implementation).
- **Project Memory**: Steering files (product.md, tech.md, structure.md) are loaded before every spec command and inform all decisions.

When creating new skills or modifying existing ones, ensure alignment with:
1. The project's **purpose** (product.md)
2. The **technology stack** and development standards (tech.md)
3. The **directory organization** and naming conventions (structure.md)
