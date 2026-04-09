---
name: kiro-spec-impl
description: Execute implementation tasks from an approved tasks.md. Works through tasks sequentially or targets specific task numbers. Updates task checkboxes as work progresses. Requires ready_for_implementation = true in spec.json.
tags: [kiro-spec, workflow, implementation, execution]
category: kiro-spec
metadata:
  version: "1.0"
  source: .kiro/settings/
---

# kiro-spec-impl

Execute implementation tasks from an approved spec.

## Overview

Implements the coding work defined in `tasks.md`, following the architecture specified in `design.md`. Works through tasks in sequence (or targets specific task numbers), marks checkboxes as tasks complete, and respects all design boundaries and requirement contracts.

## When to Use

- After `ready_for_implementation = true` in `spec.json`.
- Invoked as:
  - `/kiro-spec-impl <feature-name>` — implement all remaining tasks
  - `/kiro-spec-impl <feature-name> 1.1 1.2` — implement specific task numbers only

## Steps

### 1. Load Context

- Verify `spec.json` has `ready_for_implementation = true`. If not, stop and prompt the user.
- Read `.kiro/specs/<feature-name>/tasks.md` — the task list
- Read `.kiro/specs/<feature-name>/design.md` — architecture and interface contracts
- Read `.kiro/specs/<feature-name>/requirements.md` — acceptance criteria
- Read all `.kiro/steering/` files as project memory
- Read `research.md` if it exists

### 2. Identify Target Tasks

**Full implementation** (no task numbers specified):
- Find all unchecked tasks (`- [ ]`) in `tasks.md`.
- Start from the first unchecked task and proceed in order.

**Targeted implementation** (task numbers provided):
- Only implement the specified tasks (e.g., `1.1 1.2`).
- Verify prerequisites for each task are completed before starting.

### 3. Implement Each Task

For each task:

1. **Read** the task description and detail bullets carefully.
2. **Check** `_Requirements: N.M_` — re-read those acceptance criteria in `requirements.md`.
3. **Consult** the relevant component block in `design.md` for interface contracts.
4. **Implement** the code:
   - Follow the architecture pattern from `design.md`.
   - Honor all interface contracts exactly as specified.
   - Use naming conventions from `.kiro/steering/` files.
   - Do not cross architectural boundaries.
5. **Mark** the task checkbox as complete: `- [x]`
6. **Update** `spec.json` `updated_at` timestamp.

### 4. Parallel Tasks

Tasks marked with `(P)` can be implemented concurrently if the environment supports it. When running sequentially:
- Implement `(P)` tasks in order, ensuring each completes before the next.
- Note: the `(P)` marker indicates safe parallelism — it does not force concurrent execution.

### 5. Handle Issues

If a significant design gap or unexpected complexity is found during implementation:
- Stop the current task.
- Document the issue clearly.
- Recommend updating `design.md` or `tasks.md` before continuing.
- Do not improvise architecture changes — return to the design phase.

### 6. Progress Reporting

After each major task group completes:
- Report: tasks completed, tasks remaining, any issues encountered.
- Show the updated `tasks.md` checkpoint status.

### 7. Completion

When all target tasks are complete:
- Update `spec.json` `phase` to `"implementation"`.
- Confirm which acceptance criteria are now satisfied.
- Recommend running `/kiro-validate-impl <feature-name>` to verify correctness.

## Guardrails

- **Never** begin if `ready_for_implementation = false` or any required approval is missing.
- **Never** improvise architectural changes — update `design.md` first if the design is wrong.
- Always check acceptance criteria from `requirements.md` before marking a task complete.
- If a prerequisite task isn't done, do not skip ahead.
- Respect all interface contracts in `design.md` exactly — do not interpret or loosen them.

## See Also

- [`kiro-validate-impl`](../kiro-validate-impl/SKILL.md) — validation after implementation
- [`kiro-spec-status`](../kiro-spec-status/SKILL.md) — check progress
- [`kiro-spec-tasks`](../kiro-spec-tasks/SKILL.md) — if tasks need revision
