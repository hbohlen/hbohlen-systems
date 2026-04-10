# Archive Analysis — hbohlen-systems

**Generated:** April 9, 2026

## Overview

The `/archive/` directory contains historical work from 2025–2026 organized into three subdirectories. This analysis categorizes what's there, identifies still-relevant context, and recommends consolidation strategy.

---

## Archive Structure Inventory

### 1. `/archive/openspec/` — Completed OpenSpec Changes

**Purpose**: Deprecated OpenSpec workflow iterations and completed infrastructure changes.

**Contents**:
- `changes/archive/` — 5 completed changes (dated April 2026)
  - `2026-04-01-fix-devshell-and-gno-serve` (COMPLETED)
  - `2026-04-03-resolve-custom-domains-over-tailscale` (COMPLETED)
  - `2026-04-06-run-opencode-web-as-user` (COMPLETED)
  - `2026-04-06-tmux-agent-menu` (COMPLETED)
  - `2026-04-08-agents-skills-consolidation` (COMPLETED)

- `changes/consolidate-home-manager/` — Recent work (proposal, design, tasks)
- `changes/repo-structure-refactor/` — Recent work (proposal, design, tasks)

- `config.yaml` — OpenSpec configuration (superseded by `.agents/specs/`)
- `specs/` — Legacy OpenSpec spec templates (no longer in use)

**Status**: This structure reflects an earlier workflow phase. Current canonical workflow uses `.agents/specs/` with spec-driven commands instead of OpenSpec.

**Recommendation**: Archive is informative but superseded. Could consolidate by:
1. Extracting any decision context from completed changes
2. Summarizing closure rationale
3. Merging active changes into `.agents/specs/` if still relevant

---

### 2. `/archive/plans/` — Historical Implementation Plans

**Contents**:
- `2025-03-30-dendritic-devshell-implementation.md` (12 KB)
- `2026-03-30-hetzner-nixos-deployment-v2-implementation-plan.md` (24 KB)

**Timeline**: Plans from March–April 2025 and March–April 2026.

**Themes**:
- Dendritic devshell architecture exploration
- Hetzner deployment strategy refinement (v1 → v2 iterations)
- Manual task-by-task implementation guides (pre-automation)

**Status**: Largely superseded by spec-driven workflow; v2 deployment plan echoes current `.agents/specs/clean-project` goals.

**Recommendation**: 
1. Extract key decisions (e.g., "why dendritic" justification)
2. Create a `DECISIONS.md` summary
3. Purge or relocate redundant content

---

### 3. `/archive/superpowers/` — Design Explorations & Early Specs

**Contents**:
- `plans/` — 8 implementation plans (2025–2026)
- `specs/` — 12 design documents (2025–2026)
- `references/` — 1 runbook (Hetzner redeploy/upgrade)

**Themes**:
- **DevShell**: Dendritic implementation, tool composition
- **Hetzner Deployment**: Multi-version iterations (v1, v2, v3 implied)
- **SSH Server Hardening**: Security baseline
- **Agent Integrations**: Pi NixOS suite, OpenCode web, Opnix bootstrap, Mnemosyne web UI
- **Tailscale**: Custom domain resolution, VPN integration
- **Home Manager**: Consolidation strategies

**Timeline**: March 2025 – August 2026 (latest is mnemosyne phase 1)

**Status**: These are **valuable design explorations** that informed current architecture. Some decisions are reflected in steering files; others remain as context.

**Recommendation**: 
1. Extract **proven decisions** into `steering/` or new custom steering files
2. Keep **decision justifications** for future reference
3. Archive **deprecated exploration** (e.g., old hetzner v1 designs)
4. Consolidate **agent integration references** (opnix, opencode patterns)

---

## Active Specifications (`.agents/specs/`)

Current workflow uses spec-driven development. Active specs:

1. **`beads-integration`** (Apr 8, 2026)
   - Phase: Initialized + requirements generated
   - Status: Pending design approval

2. **`clean-project`** (Apr 9, 2026)
   - Phase: **READY FOR IMPLEMENTATION** ✅
   - Supercedes archive plans; reflects current refactoring goals
   - Scope: Remove gno/caddy, integrate home-manager, optimize devshells

3. **`documentation-refactoring`** (Apr 9, 2026)
   - Phase: Requirements generated
   - Status: Pending design approval
   - Mirrors `.agents/AGENTS.md` alignment work

4. **`pkm-system-infrastructure`** (Apr 8, 2026)
   - Phase: Requirements generated
   - Status: Pending design approval

---

## Decision Map — Archive → Steering

Key decisions embedded in archive should be extracted:

| Decision | Archive Location | Current Home | Next Step |
|----------|------------------|--------------|-----------|
| Dendritic architecture rationale | `superpowers/specs/2025-03-30-dendritic-devshell-design.md` | `steering/tech.md` ✅ | Keep |
| Flake-parts composition pattern | `superpowers/specs/*dendritic*` | `steering/tech.md` ✅ | Keep |
| Hetzner as primary target | `plans/*hetzner*` | Implicit in code | Create `steering-custom/deployment.md` |
| 1Password + opnix approach | `superpowers/specs/*opnix*` | Code only | Create `steering-custom/secrets.md` |
| Home Manager consolidation | `archive/openspec/changes/consolidate-home-manager` | `steering/structure.md` + spec `clean-project` | Implement via spec |
| Security baseline (SSH, fail2ban) | `superpowers/specs/*hardening*` | Code only | Create `steering-custom/security.md` |
| Tailscale integration | `superpowers/specs/*tailscale*` | Code only | Create `steering-custom/networking.md` |

---

## Consolidation Strategy (Recommended)

### Phase 1: Extract Decision Context (This Week)

1. **Create custom steering files** to capture domain-specific decisions:
   - `steering-custom/secrets.md` — 1Password + opnix integration strategy
   - `steering-custom/security.md` — SSH, firewall, fail2ban standards
   - `steering-custom/deployment.md` — Hetzner + nixos-anywhere + disko patterns
   - `steering-custom/networking.md` — Tailscale routing and DNS resolution

2. **Update existing steering** if needed:
   - Note Hetzner decision in `tech.md` key decisions section (already done ✅)

### Phase 2: Categorize Archive (This Week)

1. **Keep** (Still Informative, readonly):
   - `superpowers/specs/` — Design explorations (reference)
   - `superpowers/references/` — Operational runbooks
   - `archive/openspec/changes/archive/` — Completed changes (history)

2. **Consolidate** (If still in progress):
   - Review `archive/openspec/changes/consolidate-home-manager/` 
   - Review `archive/openspec/changes/repo-structure-refactor/`
   - Move to `.agents/specs/` if active; leave for historical reference if complete

3. **Purge or Summarize** (Outdated):
   - `archive/plans/` — Extract key insights to DECISIONS.md
   - Deprecated design variants (v1, v2 iterations) — Keep latest only, annotate superseded

### Phase 3: Create Archive Navigation

Add `archive/README.md` to explain the archive structure and how to use it for context.

Add `archive/DECISIONS.md` to extract key architectural decisions from historical exploration.

---

## Quick Wins (Immediate Actions)

1. ✅ Steering files created (`product.md`, `tech.md`, `structure.md`)
2. ✅ `.agents/AGENTS.md` updated with steering link and archive documentation
3. 🔄 **Create custom steering files** (secrets, security, deployment, networking)
4. 🔄 **Extract archive decisions** → create `archive/DECISIONS.md`
5. 🔄 **Create `archive/README.md`** with navigation guide

---

## Timeline for Archive Work

- **Today**: Create custom steering files; generate archive navigation docs
- **Tomorrow**: Implement `clean-project` spec (which supercedes much archive content)
- **This week**: Consolidate completed OpenSpec changes if still needed
- **Later**: As new specs complete, archive them with clear closure rationale

---

## Conclusion

The archive is **healthy and informative**. It shows organic project growth with clear decision traces. The goal is not to purge it, but to make it **discoverable** and **context-aware** for future work.

Current steering files successfully capture the project's current state. Archive now serves as historical reference and decision justification source, not as source-of-truth.
