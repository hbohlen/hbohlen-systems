# Archive — Project History & Context

This directory preserves historical work and previous iterations (2025–2026).

**Archive is append-only**: Nothing is deleted. History informs future decisions.

---

## How to Use the Archive

### Starting a New Feature?
1. **Check** `.agents/steering/` for current project memory (product, tech, structure)
2. **Check** `.agents/specs/` for active work (requirements → design → tasks)
3. **Consult** archive if you need to understand **why** a decision was made

**Archive is NOT source-of-truth**. It's historical context and decision justification.

### Looking for a Design Decision?
→ See `DECISIONS.md` (extracted from archive exploration)

### Looking for a Runbook or Procedure?
→ See `superpowers/references/` (e.g., Hetzner redeploy runbook)

### Looking for How We Got Here?
→ See the category descriptions below

---

## Contents

### `/openspec/` — Deprecated OpenSpec Workflow

Contains the previous "OpenSpec" workflow phase (before spec-driven development).

**Key folders**:
- `changes/archive/` — 5 completed infrastructure changes (Apr 2026)
  - DevShell fixes, Tailscale domain resolution, OpenCode web service, tmux menu, agent skills consolidation
- `changes/consolidate-home-manager/` — Home Manager consolidation work
- `changes/repo-structure-refactor/` — Repository structure refactoring work
- `config.yaml` — Old OpenSpec configuration (no longer in use)
- `specs/` — Legacy templates (no longer in use)

**Status**: Historical; current workflow uses `.agents/specs/` and spec-driven commands.

---

### `/plans/` — Historical Implementation Plans

Contains pre-automation, manual implementation plans from 2025–2026.

**Documents**:
- `2025-03-30-dendritic-devshell-implementation.md` — Early devshell design exploration
- `2026-03-30-hetzner-nixos-deployment-v2-implementation-plan.md` — Hetzner deployment strategy

**Status**: Largely superseded by spec-driven workflow. Key decisions have been extracted to `DECISIONS.md` and steering files.

---

### `/superpowers/` — Design Explorations & Early Specifications

Contains design explorations and early specifications that informed the current architecture.

**Key themes**:
- **DevShell Architecture**: How devShells should be composed using flake-parts
- **Hetzner Deployment**: Multi-iteration deployment strategy (v1 → v2 → v3)
- **Security Hardening**: SSH, firewall, fail2ban baseline
- **Agent Integrations**: Pi NixOS suite, OpenCode web, Opnix bootstrap, Mnemosyne web UI
- **Tailscale**: Custom domain resolution, VPN integration patterns
- **Home Manager**: Consolidation and composition strategies

**Subfolders**:
- `specs/` — 12 design documents (design exploration, decision rationale)
- `plans/` — 8 implementation plans (pre-automation task lists)
- `references/` — Validated operational runbooks (e.g., Hetzner redeploy/upgrade)

**Status**: **Valuable historical context**. Not current source-of-truth, but informs architectural decisions.

---

## Key Decisions (Extracted)

See `DECISIONS.md` for extracted architectural decisions from the exploration phases above.

The decisions are also captured in:
- `.agents/steering/product.md` — Project purpose
- `.agents/steering/tech.md` — Technology stack and key decisions
- `.agents/steering/structure.md` — Directory organization
- `.agents/steering-custom/` — Domain-specific steering files

---

## Archiving New Work

When closing a spec or feature:

1. Create a folder in `archive/` with a clear name: `archive/<date>-<feature-name>/`
2. Move or copy the complete spec, design, and tasks
3. Add a `CLOSURE.md` explaining:
   - What was completed
   - Key decisions made
   - Links to any active follow-up work
   - Rationale for archival

**Example**:
```
archive/2026-04-09-clean-project/
  spec.json
  requirements.md
  design.md
  tasks.md
  CLOSURE.md  ← "Completed Apr 9, 2026. Home Manager consolidation done."
```

---

## Quick Reference

| Looking for | Location |
|-----------|----------|
| **Why dendritic?** | `superpowers/specs/2025-03-30-dendritic-devshell-design.md` |
| **Why Hetzner?** | `plans/2026-03-30-hetzner-nixos-deployment-v2-implementation-plan.md` |
| **Why opnix/1Password?** | `superpowers/specs/2026-03-31-opnix-tailscale-bootstrap-design.md` |
| **Hetzner redeploy runbook** | `superpowers/references/2026-03-31-hetzner-redeploy-upgrade-runbook.md` |
| **Security baseline** | `superpowers/specs/2025-03-31-hetzner-server-hardening-design.md` |
| **Tailscale integration** | `superpowers/specs/2026-03-31-opencode-tailscale-web-design.md` |
| **Completed changes (Apr 2026)** | `openspec/changes/archive/` |
| **Extracted decisions** | `DECISIONS.md` |

---

**Last updated**: April 9, 2026 | Archive analysis at `ANALYSIS.md`
