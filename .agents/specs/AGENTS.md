# AGENTS.md — `.agents/specs/` Policy

This file defines the spec lifecycle, artifact ownership, and naming conventions for specs in this directory.

---

## Spec lifecycle

```
initialized → requirements → design → tasks → implementation → complete
```

Each phase requires human approval before advancing (unless `-y` flag used intentionally).

| Phase command | Output |
|---------------|--------|
| `/spec-init "<desc>"` | `spec.json`, `requirements.md` (stub) |
| `/spec-requirements <feature>` | `requirements.md` (EARS format) |
| `/spec-validate-gap <feature>` | gap analysis section in `requirements.md` (optional) |
| `/spec-design <feature>` | `design.md`, `research.md` |
| `/spec-validate-design <feature>` | GO/NO-GO review (optional) |
| `/spec-tasks <feature>` | `tasks.md` |
| `/spec-implement <feature>` | code changes, task checkboxes updated |
| `/spec-validate-implementation <feature>` | validation report (optional) |

---

## Artifact ownership

| File | Owner | Notes |
|------|-------|-------|
| `spec.json` | agent-managed | tracks phase, approvals, readiness |
| `requirements.md` | human-approved | EARS-format acceptance criteria |
| `design.md` | human-approved | architecture and interfaces |
| `research.md` | agent-managed | discovery log, architecture notes |
| `tasks.md` | human-approved | numbered, traceable task list |

---

## Naming conventions

- Feature directories: `kebab-case` (e.g., `add-user-authentication`)
- No spaces, no uppercase, no special characters
- If a name conflicts, append a numeric suffix: `my-feature-2`
- Do not rename a spec directory after it has been approved — update `spec.json` instead

---

## Steering context

Before generating requirements, design, or tasks, read **all files** under `.agents/steering/` as project memory.
Do not proceed if steering is completely empty — run `/steering` first.

---

## Completed specs

Leave completed specs in place (do not delete). They serve as historical context.
If a spec is abandoned, set `phase: "abandoned"` in `spec.json`.
