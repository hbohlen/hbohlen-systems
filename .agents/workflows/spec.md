---
description: spec-driven development workflow
---

# Spec-Driven Development Workflow

This is the canonical workflow for feature development in the project, utilizing the `.agents/skills/spec/**` skills. Agents must follow these sequential steps to safely design and implement new features.

## Workflow Steps

1. **Initialize the Spec**
   Start by scaffolding the track record for the new feature:
   [`/spec-init`](../skills/spec/spec-init/SKILL.md) `"<description>"` 
   *(Note: This creates the initial `.agents/specs/<feature-name>/` structure)*

2. **Generate Requirements**
   Author formal EARS requirements for the initialized spec:
   [`/spec-requirements`](../skills/spec/spec-requirements/SKILL.md) `<feature-name>`

3. **(Optional) Gap Analysis**
   Compare requirements with existing code to find gaps before design:
   [`/spec-validate-gap`](../skills/spec/spec-validate-gap/SKILL.md) `<feature-name>`

4. **Technical Design**
   Generate the technical design based on the requirements:
   [`/spec-design`](../skills/spec/spec-design/SKILL.md) `<feature-name> [-y]`

   *(Optional) Quality Check:* [`/spec-validate-design`](../skills/spec/spec-validate-design/SKILL.md) `<feature-name>`

5. **Generate Implementation Tasks**
   Produce the final task list needed to execute the approved design:
   [`/spec-tasks`](../skills/spec/spec-tasks/SKILL.md) `<feature-name> [-y]`

6. **Execution**
   Systematically implement the feature step-by-step using the task list:
   [`/spec-implement`](../skills/spec/spec-implement/SKILL.md) `<feature-name> [tasks]`
   
   *(Optional) Quality Check:* [`/spec-validate-implementation`](../skills/spec/spec-validate-implementation/SKILL.md) `<feature-name>`

---

## Status and Steering

- **Check Progress:** Run [`/spec-status`](../skills/spec/spec-status/SKILL.md) `[feature-name]` at any point to see the current status of the spec.
- **Ensure Project Context:** Make sure the project memory files are available and up to date by running [`/steering`](../skills/spec/steering/SKILL.md), or use [`/steering-custom`](../skills/spec/steering-custom/SKILL.md) for domain-specific context.

All canonical workflows and specs must live natively under the `.agents/` directory!
