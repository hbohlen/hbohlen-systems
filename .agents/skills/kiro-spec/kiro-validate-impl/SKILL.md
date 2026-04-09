---
name: kiro-validate-impl
description: Validate that the implementation satisfies all requirements and design contracts after kiro-spec-impl completes. Checks acceptance criteria coverage, architecture boundary compliance, and interface contract adherence. Optional but recommended post-implementation.
tags: [kiro-spec, workflow, validation, implementation-review]
category: kiro-spec
metadata:
  version: "1.0"
  source: .kiro/settings/
---

# kiro-validate-impl

Validate that an implementation satisfies all requirements, design contracts, and acceptance criteria.

## Overview

Post-implementation review that checks:
1. All `tasks.md` tasks are completed (`- [x]`)
2. All acceptance criteria in `requirements.md` are satisfied
3. The implementation respects architecture boundaries from `design.md`
4. Interface contracts are honored

## When to Use

- After `/kiro-spec-impl` completes.
- As a quality gate before considering the feature done.
- Invoked as: `/kiro-validate-impl <feature-name>`

## Steps

### 1. Load Context

- Read `.kiro/specs/<feature-name>/requirements.md`
- Read `.kiro/specs/<feature-name>/design.md`
- Read `.kiro/specs/<feature-name>/tasks.md`
- Read `spec.json` to verify `phase = "implementation"`
- Read all `.kiro/steering/` files as project memory

### 2. Task Completion Check

- Count checked (`- [x]`) vs unchecked (`- [ ]`) tasks in `tasks.md`.
- If any non-optional unchecked tasks remain, report them and stop.
- Optional tasks (`- [ ]*`) may remain deferred — note them but do not block.

### 3. Requirements Coverage Verification

For each acceptance criterion in `requirements.md`:
- Identify the corresponding code that satisfies it.
- Verify the criterion is met by reading the implementation.
- Mark each criterion as: ✅ Satisfied / ⚠️ Partial / ❌ Missing

If any required criteria are ❌ Missing:
- Report them with the specific gap.
- Recommend returning to implementation before closing the spec.

### 4. Architecture Boundary Review

Check the implementation against `design.md`:
- Components respect their documented responsibility boundaries.
- Dependency direction follows the architectural layers.
- No cross-boundary coupling that wasn't documented.
- Interface contracts are implemented as specified (method signatures, inputs/outputs).

### 5. Code Quality Spot-Check

Against steering principles:
- Naming conventions are followed.
- No `any` types in TypeScript (if applicable).
- Error handling matches the documented strategy.
- Tests cover the areas identified in the testing strategy.

### 6. Output Validation Report

```markdown
## Implementation Validation Report — <feature-name>

### Task Completion
- Completed: N/M tasks
- Optional deferred: N tasks
- Status: ✅ Complete / ❌ Incomplete (list outstanding tasks)

### Requirements Coverage
| Requirement | Criterion | Status | Notes |
|-------------|-----------|--------|-------|
| 1.1 | When... | ✅ | |
| 1.2 | If... | ⚠️ | Partial — edge case not handled |

### Architecture Compliance
- [x] Boundary: <ComponentA> stays within its domain
- [x] Interface: <ServiceX> implements all required methods
- [ ] ❌ Gap: <describe issue>

### Summary
[Overall verdict: PASS / PASS WITH NOTES / FAIL]
[1–2 sentences on what's done and what (if anything) needs follow-up]
```

### 7. Update `spec.json`

On PASS:
- Update `phase` to `"complete"` (or `"validated"`).
- Update `updated_at` timestamp.

On FAIL:
- Do not update the phase.
- Return clear remediation steps to the user.

## Guardrails

- Do not declare a spec "complete" if any non-optional requirement is unmet.
- Be specific about gaps — vague "looks good" assessments are not acceptable.
- Optional deferred tasks (`- [ ]*`) must not block a PASS verdict.
- Architecture violations are always blocking, even if requirements appear met.

## See Also

- [`kiro-spec-impl`](../kiro-spec-impl/SKILL.md) — implementation phase
- [`kiro-spec-status`](../kiro-spec-status/SKILL.md) — check overall spec progress
