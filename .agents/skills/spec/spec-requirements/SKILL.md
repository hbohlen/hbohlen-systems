---
name: spec-requirements
description: Generate or refine the requirements document for an initialized spec. Produces EARS-format acceptance criteria organized into numbered requirements. Requires human approval before proceeding to design.
tags: [spec, workflow, requirements, EARS]
category: spec
metadata:
  version: "1.0"
  source: .agents/
---

# spec-requirements

Generate or refine the requirements document for a spec-driven feature.

## Overview

Produces `.agents/specs/<feature-name>/requirements.md` containing numbered requirements with acceptance criteria in EARS syntax. Human review and approval are required before the spec can advance to the design phase.

## When to Use

- After `/spec-init` has been run.
- Invoked as: `/spec-requirements <feature-name>`

## Steps

1. **Validate preconditions**
   - Confirm `.agents/specs/<feature-name>/spec.json` exists. If not, prompt the user to run `/spec-init` first.
   - Read `.agents/specs/<feature-name>/requirements.md` (the project description from init).
   - Read all files under `.agents/steering/` as project memory (product context, tech stack, conventions).

2. **Generate requirements**
   - Follow the EARS format rules in `rules/ears-format.md`.
   - Produce numbered, verifiable requirements (e.g., 1.1, 1.2, 2.1).
   - Use the template at `.agents/templates/specs/requirements.md`.

3. **Write to file**
   - Write the completed requirements to `.agents/specs/<feature-name>/requirements.md`.

4. **Update `spec.json`**
   - Set `approvals.requirements.generated` to `true`.
   - Update `updated_at` timestamp.

5. **Request Human Review**
   - Present a summary of requirements.
   - Ask: "Do you approve these requirements? (yes / request changes)"
   - On approval: set `approvals.requirements.approved = true`, update `phase` to `"requirements"`.
   - On changes requested: iterate before re-asking.

## Templates

- [`.agents/templates/specs/requirements.md`](../../templates/specs/requirements.md)
- [`rules/ears-format.md`](../rules/ears-format.md)

## Guardrails

- All requirements must have numeric IDs (1.1, 1.2, etc.).
- Never proceed to design until requirements are approved.
- Steering context must be loaded before generating requirements.

## See Also

- [`spec-validate-gap`](../spec-validate-gap/SKILL.md) — optional gap analysis after requirements
- [`spec-design`](../spec-design/SKILL.md) — next step after requirements approval
- [`spec-status`](../spec-status/SKILL.md) — check progress
