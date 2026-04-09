---
name: kiro-spec-requirements
description: Generate or refine the requirements document for an initialized spec. Produces EARS-format acceptance criteria organized into numbered requirements. Requires human approval before proceeding to design.
tags: [kiro-spec, workflow, requirements, EARS]
category: kiro-spec
metadata:
  version: "1.0"
  source: .kiro/settings/
---

# kiro-spec-requirements

Generate the requirements document for a feature spec using the EARS format.

## Overview

Produces `.kiro/specs/<feature-name>/requirements.md` containing numbered requirements with acceptance criteria in EARS syntax. Human review and approval are required before the spec can advance to the design phase.

## When to Use

- After `/kiro-spec-init` has been run.
- When requirements need to be regenerated or refined.
- Invoked as: `/kiro-spec-requirements <feature-name>`

## Steps

1. **Locate the spec**
   - Confirm `.kiro/specs/<feature-name>/spec.json` exists. If not, prompt the user to run `/kiro-spec-init` first.

2. **Read context**
   - Read `.kiro/specs/<feature-name>/requirements.md` (the project description from init).
   - Read all files under `.kiro/steering/` as project memory (product context, tech stack, conventions).

3. **Discover existing code** (if applicable)
   - If the feature modifies an existing system, scan relevant source files to understand current behavior.

4. **Generate requirements**
   Using the template at `templates/specs/requirements.md`:
   - Write an **Introduction** summarizing the feature goal and context.
   - Group requirements into numbered sections (`### Requirement 1: <Area>`, `### Requirement 2: <Area>`, …).
   - For each requirement:
     - State the **Objective** in user-story form: `As a <role>, I want <capability>, so that <benefit>`.
     - List **Acceptance Criteria** using EARS patterns (see `rules/ears-format.md`).
   - Every requirement heading **must** have a leading numeric ID.
   - Acceptance criteria items must be testable, use "shall" for mandatory behavior.
   - Write in the language configured in `spec.json.language`.

5. **Write the file**
   - Write the completed requirements to `.kiro/specs/<feature-name>/requirements.md`.

6. **Update `spec.json`**
   - Set `approvals.requirements.generated` to `true`.
   - Update `updated_at` timestamp.
   - Do NOT set `approved` to `true` — that requires explicit human confirmation.

7. **Request human review**
   - Present a brief summary of the requirements generated.
   - Ask the user to review and confirm: "Do you approve these requirements? (yes / request changes)"
   - On approval: set `approvals.requirements.approved` to `true` in `spec.json`, update `phase` to `"requirements"`.
   - On changes requested: iterate on the document before asking again.

## EARS Format Reference

See [`rules/ears-format.md`](../../rules/ears-format.md) for full EARS syntax patterns:

| Pattern | Structure |
|---------|-----------|
| Event-driven | `When [event], the [system] shall [response]` |
| State-driven | `While [precondition], the [system] shall [response]` |
| Unwanted behavior | `If [trigger], the [system] shall [response]` |
| Optional feature | `Where [feature is included], the [system] shall [response]` |
| Ubiquitous | `The [system] shall [response]` |

## Templates

- [`templates/specs/requirements.md`](../../templates/specs/requirements.md)
- [`templates/specs/requirements-init.md`](../../templates/specs/requirements-init.md)
- [`rules/ears-format.md`](../../rules/ears-format.md)

## Guardrails

- **All** requirement headings must have numeric IDs — alphabetic IDs (e.g., "Requirement A") are not allowed.
- Do not advance to design without `approvals.requirements.approved = true`.
- Requirements must be testable and use objective language ("shall", not "should").
- Never include implementation details (file paths, function names) in requirements.

## See Also

- [`kiro-validate-gap`](../kiro-validate-gap/SKILL.md) — optional gap analysis after requirements
- [`kiro-spec-design`](../kiro-spec-design/SKILL.md) — next step after requirements approval
- [`kiro-spec-status`](../kiro-spec-status/SKILL.md) — check progress
