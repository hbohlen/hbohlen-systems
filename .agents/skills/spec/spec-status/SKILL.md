---
name: spec-status
description: Show the current status of a feature spec — phases completed, approvals obtained, tasks done, and next recommended action. Use at any point in the workflow to check progress.
tags: [spec, workflow, status, progress]
category: spec
metadata:
  version: "1.0"
  source: .agents/
---

# spec-status

Report the current status of a feature spec at any point in the workflow.

## Overview

Reads `spec.json` and the spec's artifact files to produce a concise progress report covering: what phase the spec is in, which approvals are obtained, how many tasks are complete, and what the recommended next action is.

## When to Use

- At any point in the spec-driven workflow.
- To check what's been done and what comes next.
- Invoked as: `/spec-status <feature-name>`

## Steps

### 1. Locate the Spec

- Check `.agents/specs/<feature-name>/spec.json`.
- If not found, report: "No spec found for `<feature-name>`. Run `/spec-init` to start."

### 2. Read Spec State

From `spec.json`, extract:
- `feature_name`
- `phase`
- `created_at`, `updated_at`
- `language`
- `approvals.requirements.{generated, approved}`
- `approvals.design.{generated, approved}`
- `approvals.tasks.{generated, approved}`
- `ready_for_implementation`

### 3. Check Artifact Status

For each artifact, check if the file exists and (where applicable) its size/content:
- `requirements.md` — exists? has content beyond the scaffolding?
- `design.md` — exists?
- `tasks.md` — exists? count `- [x]` vs `- [ ]` checkboxes.
- `research.md` — exists? (informational)

### 4. Produce Status Report

```markdown
## Spec Status: <feature-name>

**Phase**: <phase>
**Language**: <language>
**Created**: <created_at>
**Updated**: <updated_at>

### Approvals
| Phase | Generated | Approved |
|-------|-----------|----------|
| Requirements | ✅ / ❌ | ✅ / ❌ |
| Design | ✅ / ❌ | ✅ / ❌ |
| Tasks | ✅ / ❌ | ✅ / ❌ |

**Ready for Implementation**: Yes / No

### Task Progress (if tasks.md exists)
- Completed: N / M tasks (N%)
- Optional deferred: N tasks

### Artifacts
- requirements.md: ✅ present / ❌ missing
- design.md: ✅ present / ❌ missing
- tasks.md: ✅ present / ❌ missing
- research.md: ✅ present / ❌ missing (optional)

### Next Action
> [Recommended next command and what it does]
```

### 5. Next Action Recommendation

Based on current state, recommend the next step:

| Condition | Recommendation |
|-----------|----------------|
| Phase = initialized, requirements not generated | Run `/spec-requirements <feature-name>` |
| Requirements generated, not approved | Review requirements.md and approve |
| Requirements approved, design not generated | Run `/spec-design <feature-name>` |
| Design generated, not approved | Optional: run `/spec-validate-design <feature-name>`, then approve |
| Design approved, tasks not generated | Run `/spec-tasks <feature-name>` |
| Tasks generated, not approved | Review tasks.md and approve |
| ready_for_implementation = true, tasks incomplete | Run `/spec-implement <feature-name>` |
| All tasks complete | Run `/spec-validate-implementation <feature-name>` |
| Phase = complete | 🎉 Spec complete! |

## Guardrails

- This command is read-only — it never modifies `spec.json` or any artifact.
- Always list all specs under `.agents/specs/` if no feature name is provided:
  ```
  Available specs:
  - <feature-1>: phase=design, tasks 3/8 complete
  - <feature-2>: phase=initialized
  ```

## See Also

- [`spec-init`](../spec-init/SKILL.md) — start a new spec
- [`spec-implement`](../spec-implement/SKILL.md) — implementation phase
- [`spec-validate-implementation`](../spec-validate-implementation/SKILL.md) — post-implementation check
