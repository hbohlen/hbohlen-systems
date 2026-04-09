---
name: kiro-spec-init
description: Initialize a new spec-driven feature. Creates the spec directory structure and populates spec.json and requirements.md with initial scaffolding. Use when starting any new feature or significant change.
tags: [kiro-spec, workflow, init, spec-driven]
category: kiro-spec
metadata:
  version: "1.0"
  source: .kiro/settings/
---

# kiro-spec-init

Initialize a new feature specification using Spec-Driven Development (SDD).

## Overview

Creates `.kiro/specs/<feature-name>/` with the initial scaffolding:
- `spec.json` — tracks phase, approvals, and readiness
- `requirements.md` — pre-populated with the feature description, ready for `/kiro-spec-requirements`

## When to Use

- Starting any new feature or significant change
- Invoked as: `/kiro-spec-init "<description>"` or `/kiro-spec-init "<feature-name>"`

## Steps

1. **Derive the feature name**
   - If the input is a description (e.g., "Add user authentication"), convert it to kebab-case (e.g., `add-user-authentication`).
   - If a kebab-case name is already provided, use it as-is.

2. **Check for an existing spec**
   - If `.kiro/specs/<feature-name>/` already exists, ask the user whether to continue the existing spec or start fresh.
   - Never silently overwrite an existing spec.

3. **Create the spec directory**
   ```
   .kiro/specs/<feature-name>/
   ```

4. **Create `spec.json`** using the template at `templates/specs/init.json`:
   - Replace `{{FEATURE_NAME}}` with the derived name.
   - Replace both `{{TIMESTAMP}}` values with the current ISO 8601 timestamp.
   - Set all `generated` and `approved` flags to `false`.
   - Set `ready_for_implementation` to `false`.
   - Set `phase` to `"initialized"`.

5. **Create `requirements.md`** using the template at `templates/specs/requirements-init.md`:
   - Replace `{{PROJECT_DESCRIPTION}}` with the original user input (description or name).

6. **Report success**
   - Show the created paths.
   - Prompt the user to run `/kiro-spec-requirements <feature-name>` to generate the full requirements.

## Templates

See companion files:
- [`templates/specs/init.json`](../../templates/specs/init.json)
- [`templates/specs/requirements-init.md`](../../templates/specs/requirements-init.md)

## Guardrails

- Never create a spec without a meaningful name or description.
- Do not proceed past initialization—this command only scaffolds the directory.
- The `spec.json` phase must start at `"initialized"`.
- All timestamps must be ISO 8601 (e.g., `2026-04-09T00:00:00Z`).

## See Also

- [`kiro-spec-requirements`](../kiro-spec-requirements/SKILL.md) — next step after init
- [`kiro-spec-status`](../kiro-spec-status/SKILL.md) — check progress at any time
