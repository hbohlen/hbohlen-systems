---
name: kiro-spec-tasks
description: Generate the implementation task list from an approved design. Produces tasks.md with numbered, parallel-aware tasks mapped to requirement IDs. Requires human approval before implementation. Use -y flag to fast-track.
tags: [kiro-spec, workflow, tasks, implementation-planning]
category: kiro-spec
metadata:
  version: "1.0"
  source: .kiro/settings/
---

# kiro-spec-tasks

Generate the implementation task list from an approved design document.

## Overview

Produces `.kiro/specs/<feature-name>/tasks.md` — a structured, numbered task list with requirement traceability, parallel execution markers, and sub-task breakdowns. Human approval is required before implementation begins.

Use `-y` flag to fast-track and skip the approval prompt (use intentionally).

## When to Use

- After `approvals.design.approved = true` in `spec.json`.
- Invoked as: `/kiro-spec-tasks <feature-name>` or `/kiro-spec-tasks <feature-name> -y`

## Steps

### 1. Load Context

- Read `.kiro/specs/<feature-name>/design.md` (approved design)
- Read `.kiro/specs/<feature-name>/requirements.md` (requirements with numeric IDs)
- Read all `.kiro/steering/` files as project memory

### 2. Analyze for Parallelism

Following `rules/tasks-parallel-analysis.md`, identify tasks that can safely run concurrently:
- No data dependency on pending tasks
- No shared file or resource conflicts
- No prerequisite review/approval from another task
- All required environment/setup is satisfied

Mark parallel-capable tasks with `(P)` immediately after the numeric identifier.

### 3. Generate `tasks.md`

Using the template at `templates/specs/tasks.md` and following `rules/tasks-generation.md`:

**Task hierarchy (max 2 levels):**
- Level 1: Major tasks (`1.`, `2.`, `3.` …) — sequential, auto-incrementing
- Level 2: Sub-tasks (`1.1`, `1.2`, `2.1` …) — reset per major task

**Each sub-task must include:**
- Natural-language description of the capability/outcome (not file paths or function names)
- 3–10 detail bullet items
- `_Requirements: N.M, N.M_` — only numeric IDs, no descriptive text

**Task ordering rules:**
- Always end with integration tasks to wire components together
- Validate core functionality early in the sequence
- Respect architecture boundaries from `design.md`
- Honor interface contracts documented in `design.md`

**Checkbox format:**
```markdown
- [ ] 1. Major task description
- [ ] 1.1 Sub-task description
  - Detail item 1
  - Detail item 2
  - _Requirements: 1.1, 1.2_

- [ ] 1.2 (P) Parallel sub-task
  - Detail items...
  - _Requirements: 1.3_
```

**Scope rules (code-only):**
- ✅ Include: implementation, unit tests, integration tests, technical setup
- ❌ Exclude: deployment tasks, documentation tasks, user testing, business activities

**Optional test coverage:**
Use `- [ ]*` checkbox form for deferrable test work tied to acceptance criteria.

### 4. Validate Requirements Coverage

- Cross-reference every requirement ID from `requirements.md` with task mappings.
- **All requirements must be covered.** If gaps found, return to requirements or design phase.
- Document any intentionally deferred requirements with rationale.

### 5. Update `spec.json`

- Set `approvals.tasks.generated` to `true`.
- Update `updated_at` timestamp.

### 6. Request Human Review (unless `-y` flag used)

- Present a summary: number of major tasks, total sub-tasks, parallel tasks identified.
- Ask: "Do you approve this task list? (yes / request changes)"
- On approval:
  - Set `approvals.tasks.approved` to `true`
  - Set `ready_for_implementation` to `true`
  - Update `phase` to `"tasks"`
- On changes requested: iterate before re-asking.

**With `-y` flag**: skip the approval prompt and auto-approve.

## Task Anti-Patterns to Avoid

- ❌ Describing file paths or function names in task descriptions
- ❌ Tasks that skip architectural boundaries from `design.md`
- ❌ Forcing arbitrary task counts — let logical grouping determine structure
- ❌ Major task numbers that repeat (e.g., two `1.` tasks)
- ❌ Nesting deeper than 2 levels (no `1.1.1`)
- ❌ Requirements without numeric IDs — fix `requirements.md` before generating tasks

## Templates

- [`templates/specs/tasks.md`](../../templates/specs/tasks.md)
- [`rules/tasks-generation.md`](../../rules/tasks-generation.md)
- [`rules/tasks-parallel-analysis.md`](../../rules/tasks-parallel-analysis.md)

## Guardrails

- Do not start implementation before `ready_for_implementation = true`.
- Every requirement must map to at least one task — no orphaned requirements.
- `(P)` markers must only be applied after verifying all three parallelism conditions.
- Sequential mode (`--sequential` flag): omit all `(P)` markers.

## See Also

- [`kiro-spec-impl`](../kiro-spec-impl/SKILL.md) — next step after tasks approval
- [`kiro-validate-impl`](../kiro-validate-impl/SKILL.md) — post-implementation validation
- [`kiro-spec-status`](../kiro-spec-status/SKILL.md) — check progress
