# Agent Instructions — `.agents/`

`.agents/` is the canonical home for agent workflow artifacts in this repository.
**pi** discovers `.agents/skills/` natively via recursive directory traversal.

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
| `beads` | `.agents/skills/beads/` | Beads issue tracker workflow |
| `personal` | `.agents/skills/personal/` | Personal workflow and productivity |

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

## Tool compatibility

- **pi**: Discovers `.agents/skills/` natively — no adapter needed
- **OpenCode**: Thin adapters in `.opencode/commands/` delegate to `.agents/skills/spec/**` skills
- **Hermes**: Uses `.hermes/skills/` — separate adapter layer, not canonical

---

## What does NOT belong in `.agents/`

- Human-facing documentation → `docs/`
- Hermes-specific adapters → `.hermes/`
- OpenCode-specific adapters → `.opencode/`
- Build artifacts, secrets, NixOS config → their respective top-level dirs
