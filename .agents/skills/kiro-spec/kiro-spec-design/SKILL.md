---
name: kiro-spec-design
description: Generate the technical design document for a feature with approved requirements. Produces design.md covering architecture, components, interfaces, data models, and testing strategy. Requires human approval before proceeding to tasks. Use -y flag to skip approval prompt for fast-track.
tags: [kiro-spec, workflow, design, architecture]
category: kiro-spec
metadata:
  version: "1.0"
  source: .kiro/settings/
---

# kiro-spec-design

Generate the technical design document for a spec-driven feature.

## Overview

Produces `.kiro/specs/<feature-name>/design.md` covering architecture, components, interfaces, data models, error handling, and testing strategy. Optionally generates `research.md` for detailed investigation notes. Requires human approval before the spec advances to task generation.

Use `-y` flag to fast-track and skip the approval prompt (use intentionally).

## When to Use

- After `approvals.requirements.approved = true` in `spec.json`.
- Invoked as: `/kiro-spec-design <feature-name>` or `/kiro-spec-design <feature-name> -y`

## Steps

### 1. Load Context

- Read `.kiro/specs/<feature-name>/requirements.md` (approved requirements).
- Read all files under `.kiro/steering/` as project memory.
- Read gap analysis output if available (gap-analysis.md or section in requirements.md).

### 2. Choose Discovery Mode

**Full Discovery** (default for new or complex features):
- Follow `rules/design-discovery-full.md`:
  - Map requirements to technical needs
  - Analyze existing codebase for patterns, boundaries, integration points
  - Research external dependencies and APIs
  - Evaluate architecture patterns (MVC, Hexagonal, Event-driven, etc.)
  - Perform risk assessment
- Capture investigation findings in `research.md` using the template at `templates/specs/research.md`.

**Light Discovery** (for simple extensions):
- Follow `rules/design-discovery-light.md`:
  - Identify extension points and modification scope
  - Verify dependency compatibility
  - Quick technology check for new libraries only
  - Brief integration risk assessment
- Escalate to Full Discovery if significant complexity is found.

### 3. Generate `design.md`

Using the template at `templates/specs/design.md` and following `rules/design-principles.md`:

**Required sections:**
- **Overview** (2–3 paragraphs: Purpose, Users, Impact)
  - Goals and Non-Goals
- **Architecture** — pattern selection, boundary map, technology stack table
- **Components and Interfaces** — summary table + per-component detail blocks for new boundaries
- **Data Models** — domain model, logical model, data contracts
- **Error Handling** — error categories and recovery strategies
- **Testing Strategy** — unit, integration, E2E coverage areas

**Conditional sections:**
- **System Flows** — sequence/state/data-flow diagrams (skip for simple CRUD)
- **Requirements Traceability** — table mapping requirement IDs to design elements
- **Supporting References** — lengthy definitions or vendor schemas

**Key rules from design principles:**
- Use `N.M` numeric requirement IDs (e.g., `2.1, 2.3`) — never alphabetic.
- All Mermaid diagrams must be plain/pure — no custom styling.
- Never use `any` in TypeScript interface definitions.
- design.md must be self-contained for reviewers; push investigation details to research.md.
- Do not repeat diagram content verbatim in prose.
- Detail density: full blocks for new boundaries; summary-only for presentational components.

### 4. Generate `research.md` (if full discovery was performed)

Using the template at `templates/specs/research.md`:
- Document research log, architecture pattern evaluation, and design decisions.
- Record rejected alternatives and trade-offs.

### 5. Update `spec.json`

- Set `approvals.design.generated` to `true`.
- Update `updated_at` timestamp.

### 6. Request Human Review (unless `-y` flag used)

- Present a brief summary of the design.
- Ask: "Do you approve this design? (yes / request changes)"
- On approval: set `approvals.design.approved = true`, update `phase` to `"design"`.
- On changes requested: iterate before re-asking.

**With `-y` flag**: skip the approval prompt and auto-approve.

## Diagram Rules

- **Architecture diagram**: Required when 3+ components or external systems interact.
- **Sequence diagram**: Required for multi-step interactions.
- **State/flow diagram**: Required for complex business flows.
- **ER diagram**: Required for non-trivial data models.
- Pure Mermaid only — no `@`, `()`, `[]` in node IDs or labels.

See `rules/design-principles.md` for the full set of authoring guidelines and anti-patterns.

## Templates

- [`templates/specs/design.md`](../../templates/specs/design.md)
- [`templates/specs/research.md`](../../templates/specs/research.md)
- [`rules/design-principles.md`](../../rules/design-principles.md)
- [`rules/design-discovery-full.md`](../../rules/design-discovery-full.md)
- [`rules/design-discovery-light.md`](../../rules/design-discovery-light.md)

## Guardrails

- Do not generate tasks before design is approved.
- Keep design.md under ~1000 lines — approaching that limit signals excessive complexity.
- Never leak implementation details (file paths, function bodies) into design.md.
- All requirements must be traceable to design components before proceeding.
- Re-run requirements traceability whenever requirements or components change.

## See Also

- [`kiro-validate-design`](../kiro-validate-design/SKILL.md) — optional design quality review
- [`kiro-spec-tasks`](../kiro-spec-tasks/SKILL.md) — next step after design approval
- [`kiro-spec-status`](../kiro-spec-status/SKILL.md) — check progress
