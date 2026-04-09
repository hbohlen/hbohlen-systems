---
name: mermaid-diagrams
description: Create and update Mermaid diagrams that reflect current repository architecture, workflows, and process flows for human-facing docs.
tags: [documentation, diagrams, mermaid, architecture, workflow]
category: diagrams
metadata:
  version: "1.0"
  source: .agents/
---

# mermaid-diagrams

Create clear, accurate Mermaid diagrams for this repository's documentation.

## When to Use

- The user asks for architecture or workflow diagrams
- A doc needs a visual of current system structure
- A process needs a step-by-step flowchart

## Inputs to Gather

1. **Purpose** of the diagram (architecture, workflow, sequence, state)
2. **Scope** (repo-wide, subsystem, one workflow)
3. **Target location**:
   - Durable architecture docs → `docs/architecture/`
   - One-time analysis/report → `docs/reports/`
   - Historical/superseded context → `docs/archive/`

## Authoring Steps

1. Read canonical sources first (`AGENTS.md`, `.agents/AGENTS.md`, `docs/CONVENTIONS.md`, and relevant feature docs).
2. Extract only current-state facts from source files.
3. Choose the simplest Mermaid diagram type that fits:
   - `flowchart` for process and folder relationships
   - `sequenceDiagram` for interaction/order of operations
   - `stateDiagram-v2` for lifecycle/state transitions
4. Draft with clear node labels and short edge text.
5. Keep diagrams maintainable:
   - avoid excessive nesting
   - avoid duplicating the same relationship in multiple places
   - split into multiple diagrams when one becomes crowded
6. Add a short context section above each diagram and brief usage notes below it.

## Quality Checklist

- Diagram matches current repository state (not aspirational unless explicitly labeled)
- Mermaid syntax is valid and fenced as:
  ````
  ```mermaid
  ...
  ```
  ````
- Terms and paths match canonical naming (e.g., `.agents/skills/spec/`)
- Diagram can be understood without external context

## Guardrails

- Do not invent components that are not present in the codebase/docs.
- Do not move canonical workflow ownership out of `.agents/skills/spec/`.
- Prefer adding a new report instead of rewriting unrelated historical docs.
