# Spec Workflow Migration Report

**Date:** 2026-04-09  
**Type:** Structural refactor — no functional changes

---

## Summary

Consolidated the spec-driven development workflow from `.kiro/` into `.agents/`, removed the `kiro-` naming prefix, established canonical folder policy, and cleaned up adapter duplication.

---

## 1. Renamed skills/commands

All `kiro-` prefixes dropped; skill category renamed from `kiro-spec` to `spec`.

| Old name | New name | Path |
|----------|----------|------|
| `kiro-spec-init` | `spec-init` | `.agents/skills/spec/spec-init/` |
| `kiro-spec-requirements` | `spec-requirements` | `.agents/skills/spec/spec-requirements/` |
| `kiro-spec-design` | `spec-design` | `.agents/skills/spec/spec-design/` |
| `kiro-spec-tasks` | `spec-tasks` | `.agents/skills/spec/spec-tasks/` |
| `kiro-spec-impl` | `spec-implement` | `.agents/skills/spec/spec-implement/` |
| `kiro-spec-status` | `spec-status` | `.agents/skills/spec/spec-status/` |
| `kiro-validate-gap` | `spec-validate-gap` | `.agents/skills/spec/spec-validate-gap/` |
| `kiro-validate-design` | `spec-validate-design` | `.agents/skills/spec/spec-validate-design/` |
| `kiro-validate-impl` | `spec-validate-implementation` | `.agents/skills/spec/spec-validate-implementation/` |
| `kiro-steering` | `steering` | `.agents/skills/spec/steering/` |
| `kiro-steering-custom` | `steering-custom` | `.agents/skills/spec/steering-custom/` |

---

## 2. Moved paths

| Old path | New path | Notes |
|----------|----------|-------|
| `.kiro/specs/` | `.agents/specs/` | Active and completed feature specs |
| `.kiro/steering/` | `.agents/steering/` | Project-wide memory files |
| `.kiro/settings/rules/` | `.agents/rules/` | Authoring rules (EARS, design, etc.) |
| `.kiro/settings/templates/` | `.agents/templates/` | Spec and steering templates |
| `.kiro/` | *(removed)* | Entire directory removed after migration |

---

## 3. Updated AGENTS files

| File | Action | Notes |
|------|--------|-------|
| `AGENTS.md` (root) | Rewritten | Concise router — points to `.agents/AGENTS.md` and `docs/AGENTS.md` |
| `.agents/AGENTS.md` | Rewritten | Full workflow rules, new command names, folder policy |
| `docs/AGENTS.md` | Created | `docs/` folder policy for agents |
| `.agents/specs/AGENTS.md` | Created | Spec lifecycle, artifact ownership, naming conventions |
| `docs/CONVENTIONS.md` | Created | Folder ownership rules and agent decision guidance |

---

## 4. Adapter updates

| File | Action |
|------|--------|
| `.opencode/commands/kiro-spec-init.md` → `spec-init.md` | Renamed + path refs updated |
| `.opencode/commands/kiro-spec-requirements.md` → `spec-requirements.md` | Renamed + path refs updated |
| `.opencode/commands/kiro-spec-design.md` → `spec-design.md` | Renamed + path refs updated |
| `.opencode/commands/kiro-spec-tasks.md` → `spec-tasks.md` | Renamed + path refs updated |
| `.opencode/commands/kiro-spec-impl.md` → `spec-implement.md` | Renamed + path refs updated |
| `.opencode/commands/kiro-spec-status.md` → `spec-status.md` | Renamed + path refs updated |
| `.opencode/commands/kiro-validate-gap.md` → `spec-validate-gap.md` | Renamed + path refs updated |
| `.opencode/commands/kiro-validate-design.md` → `spec-validate-design.md` | Renamed + path refs updated |
| `.opencode/commands/kiro-validate-impl.md` → `spec-validate-implementation.md` | Renamed + path refs updated |
| `.opencode/commands/kiro-steering.md` → `steering.md` | Renamed + path refs updated |
| `.opencode/commands/kiro-steering-custom.md` → `steering-custom.md` | Renamed + path refs updated |
| `.agents/workflows/kiro.md` | Removed — replaced by `spec.md` |
| `.agents/workflows/spec.md` | Created |
| `.opencode/skills/` | Unchanged — unique opencode-specific skills, no duplicates |
| `.pi/prompts/` | Unchanged — opsx-only prompts, no kiro references |
| `.hermes/skills/` | Unchanged — hermes adapters, separate concern |

---

## 5. Legacy `.agents/skills/kiro-spec/`

The old `.agents/skills/kiro-spec/` directory is **retained** as a legacy reference to preserve history. It is no longer the canonical source — all canonical content is now under `.agents/skills/spec/`.

> **Recommendation:** Once all agents and tooling have confirmed they are using the new paths, `.agents/skills/kiro-spec/` can be archived or removed in a follow-up PR.

---

## 6. Remaining legacy areas

| Area | Status | Notes |
|------|--------|-------|
| `.agents/skills/kiro-spec/` | legacy, kept | Old skill directory — retained for history |
| `docs/plans/` | legacy paths | Historical plans, candidate for `docs/archive/` in follow-up |
| `docs/superpowers/` | legacy paths | Historical docs, candidate for `docs/archive/` in follow-up |
| `docs/beads/` | active reference | Beads knowledge base — stays in `docs/` as reference material |

---

## 7. Unresolved ambiguity

- **`.agents/steering/`** is now created as the canonical path for steering documents, but no steering files exist yet. Run `/steering` to bootstrap them.
- **`docs/plans/` and `docs/superpowers/`** contain historical docs that predate this folder policy. A follow-up cleanup should move them to `docs/archive/`.
