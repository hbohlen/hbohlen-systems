# Architectural Decisions — Extracted from Archive

**Generated**: April 9, 2026 | Source: `archive/superpowers/specs/` and `archive/plans/`

This document extracts key architectural decisions from the project's historical exploration phases (2025–2026). Each decision is documented with:
- **What**: The decision itself
- **Why**: Rationale (from archive docs)
- **Where**: Current implementation home
- **Status**: Whether the decision is still active

---

## 1. Dendritic Architecture (Flake-Parts Pattern)

**Decision**: Use flake-parts to compose infrastructure as modular, peer-level "dendrites" rather than nested hierarchies.

**Why**: 
- Enables organic growth without forcing architectural constraints
- Each concern (devshell, NixOS configs, tests) is a sibling module, not nested layer
- New features don't require restructuring; they grow alongside existing modules
- Matches ADHD-friendly, non-linear thinking patterns

**Source**: `superpowers/specs/2025-03-30-dendritic-devshell-design.md`

**Current Home**: 
- `steering/tech.md` — "Dendritic Over Hierarchical" decision
- `steering/structure.md` — "Dendritic Growth" philosophy
- `parts/` — Implementation

**Status**: ✅ **ACTIVE** — Core architectural pattern

---

## 2. Hetzner Cloud as Primary Infrastructure Target

**Decision**: Host primary production infrastructure on Hetzner Cloud using Cloud VMs, not bare metal or other providers.

**Why**:
- Reliable, cost-effective VPS provider with good NixOS ecosystem support
- API-driven provisioning (hcloud CLI) enables automation
- European data residency option
- nixos-anywhere tooling is battle-tested for Hetzner

**Source**: `plans/2026-03-30-hetzner-nixos-deployment-v2-implementation-plan.md`

**Current Home**:
- `steering/tech.md` — "Hetzner-First Deployment" decision
- `hosts/hbohlen-01.nix` + hardware config — Implementation

**Status**: ✅ **ACTIVE** — Primary deployment platform

---

## 3. NixOS + Disko for Declarative Server Provisioning

**Decision**: Use NixOS (not Ubuntu/Debian) and Disko (not manual partitioning) for reproducible server provisioning.

**Why**:
- NixOS provides full declarative system management
- Disko enables declarative disk partitioning and filesystem layout
- nixos-anywhere handles remote installation without interactive access
- Combined: One command can completely redeploy a server from scratch

**Source**: `plans/2026-03-30-hetzner-nixos-deployment-v2-implementation-plan.md`

**Current Home**:
- `steering/tech.md` — "Core Technologies"
- `nixos/disko.nix` — Disk configuration
- `hosts/hbohlen-01.nix` — NixOS config

**Status**: ✅ **ACTIVE** — Core infrastructure pattern

---

## 4. Home Manager as Declarative User Environment

**Decision**: Use Home Manager to manage user dotfiles, shell config, and application settings declaratively, integrated into NixOS module system.

**Why**:
- Eliminates manual dotfile management; everything is versionable
- Natural integration with NixOS module system (avoids duplicated user/system config)
- Easy to compose per-user settings, share configs across machines
- Rollback and recovery built-in

**Source**: `superpowers/specs/` (dendritic, consolidation explorations)

**Current Home**:
- `steering/structure.md` — `/home/` directory pattern
- `home/default.nix` — Implementation
- `.agents/specs/clean-project` — Active consolidation spec

**Status**: ✅ **ACTIVE** — Active consolidation in progress

---

## 5. 1Password + Opnix for Secret Injection

**Decision**: Use 1Password (not git-crypt, not sops) as single source of truth for secrets; inject via opnix module at Nix evaluation time.

**Why**:
- 1Password is already trusted infrastructure (likely corporate standard)
- Opnix module handles OAuth service account rotation automatically
- Secrets never live in git, even encrypted
- Service account token only needed at evaluation time, not at runtime

**Source**: `superpowers/specs/2026-03-31-opnix-tailscale-bootstrap-design.md`

**Current Home**:
- `steering/tech.md` — "Secrets via 1Password + opnix" decision
- `secrets/` — Secret references (not plain text)
- `nixos/` modules — Opnix integration points

**Status**: ✅ **ACTIVE** — Implemented, needs documentation

**Next**: Create `steering-custom/secrets.md` to document patterns

---

## 6. Tailscale for Zero-Trust Networking

**Decision**: Use Tailscale (not manually configured WireGuard) for VPN access, DNS, and inter-machine routing.

**Why**:
- Zero-trust model without complex CA management
- Built-in DNS integration (can resolve custom domains within VPN)
- Mesh networking: machines talk peer-to-peer, not hub-and-spoke
- Funnel feature enables secure public access to selected services

**Source**: `superpowers/specs/2026-03-31-opencode-tailscale-web-design.md`

**Current Home**:
- `steering/tech.md` — VPN/Routing mention
- `nixos/tailscale.nix` — Configuration
- Implicit in deployment security model

**Status**: ✅ **ACTIVE** — Infrastructure pattern

**Next**: Create `steering-custom/networking.md` to document patterns

---

## 7. SSH Security Baseline

**Decision**: Implement consistent SSH hardening across all systems: no password auth, key-only, fail2ban protection, explicit key policies.

**Why**:
- Prevents brute-force attacks
- Consistent security posture across heterogeneous hosts
- Automated recovery and re-keying via NixOS declarative model
- Compliance with infrastructure security standards

**Source**: `superpowers/specs/2025-03-31-hetzner-server-hardening-design.md`

**Current Home**:
- `nixos/ssh.nix` — SSH daemon hardening
- `nixos/security.nix` — Firewall, fail2ban
- Home Manager SSH client config — Client setup

**Status**: ✅ **ACTIVE** — Infrastructure security baseline

**Next**: Create `steering-custom/security.md` to document standards

---

## 8. Spec-Driven Infrastructure Development

**Decision**: All significant infrastructure changes flow through a spec-driven workflow: requirements → design → tasks → implementation, with human approval gates.

**Why**:
- Documents architectural decisions and rationale
- Enables human review before implementation
- Creates traceable history of infrastructure changes
- Prevents ad-hoc, undocumented deployments

**Source**: Learned from OpenSpec phase; formalized in spec-driven workflow

**Current Home**:
- `.agents/specs/` — Active spec workflow
- `.agents/AGENTS.md` — Workflow documentation
- `.agents/steering/` — Project memory

**Status**: ✅ **ACTIVE** — Active development methodology

---

## 9. Spec Validation and Quality Gates

**Decision**: Include optional validation steps after each spec phase (gap analysis, design review, implementation validation) to catch issues early.

**Why**:
- Design flaws caught before task generation saves time
- Gap analysis prevents surprises (e.g., assuming code exists when it doesn't)
- Implementation validation ensures requirements are met
- Lowers risk of failed deployments or architectural misalignment

**Source**: Spec-driven workflow best practices

**Current Home**:
- `.agents/skills/spec/spec-validate-*.md` — Validation skills
- `.agents/AGENTS.md` — Optional validation steps documented

**Status**: ✅ **ACTIVE** — Available but not mandatory

---

## 10. Dendritic, Not Hierarchical, Skill Architecture

**Decision**: Skills grow as peer modules under `.agents/skills/<category>/`, not as nested hierarchies. New skills in existing categories; new categories only if truly distinct domain.

**Why**:
- Matches dendritic philosophy (organic growth)
- Prevents "misc" category or deep nesting
- Each skill is independently discoverable by pi
- Easy to add new skills without restructuring

**Source**: Learned from OpenSpec consolidation (Apr 8, 2026)

**Current Home**:
- `.agents/AGENTS.md` — Skill categories table
- `.agents/skills/` — Implementation

**Status**: ✅ **ACTIVE** — Architecture pattern

---

## 11. Archive as Append-Only History

**Decision**: Archive directory is append-only; nothing is deleted. Historical work is preserved for reference and decision justification.

**Why**:
- Allows future context lookup ("why did we choose X?")
- Prevents repeating failed experiments
- Provides traceable audit trail
- Supports ADHD-friendly organic exploration

**Source**: Project workflow philosophy

**Current Home**:
- `archive/` — Preserved work
- `archive/README.md` — Navigation guide
- `archive/DECISIONS.md` — This document

**Status**: ✅ **ACTIVE** — Archive policy

---

## 12. Steering Files as Source of Project Memory

**Decision**: Three core steering files (product.md, tech.md, structure.md) + optional custom steering files are the source of truth for project memory, loaded before every agent decision.

**Why**:
- Ensures agents operate from consistent project context
- Prevents architectural drift
- Makes implicit project knowledge explicit
- Enables new agents/tools to onboard quickly

**Source**: Spec-driven development best practice

**Current Home**:
- `.agents/steering/` — Steering files
- `.agents/AGENTS.md` — Steering preface ("read steering first")

**Status**: ✅ **ACTIVE** — Just implemented (Apr 9, 2026)

---

## Decisions Not Yet Documented in Steering

The following archive decisions should be captured in custom steering files:

| Decision | Recommendation | Urgency |
|----------|---|----------|
| 1Password + opnix patterns | Create `steering-custom/secrets.md` | High |
| SSH/Firewall/Fail2ban baseline | Create `steering-custom/security.md` | High |
| Hetzner deployment patterns (hcloud + nixos-anywhere + disko) | Create `steering-custom/deployment.md` | High |
| Tailscale DNS and routing patterns | Create `steering-custom/networking.md` | Medium |
| Home Manager consolidation patterns | Expand `steering/structure.md` or create `steering-custom/user-config.md` | Medium |

---

## Next Steps

1. ✅ Create steering files (product, tech, structure) — **DONE**
2. ✅ Create archive navigation (README, ANALYSIS) — **DONE**
3. 🔄 Create custom steering files (secrets, security, deployment, networking)
4. 🔄 Implement `clean-project` spec (consolidates Home Manager, removes deprecated services)
5. 🔄 Link archival decisions into active specs

---

**Maintained by**: Project Steering  
**Last Updated**: April 9, 2026  
**Related**: `archive/README.md`, `.agents/steering/`
