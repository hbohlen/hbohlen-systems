---
name: steering
description: Create or refresh the core steering files (product.md, tech.md, structure.md) under .agents/steering/. Steering files are project memory that guide all agent decisions. Run at project start or when the project context has significantly changed.
tags: [spec, steering, project-memory]
category: spec
metadata:
  version: "1.0"
  source: .agents/
---

# steering

Create or refresh the core steering files that serve as project-wide memory.

## Overview

Steering files live at `.agents/steering/` and are loaded as project context by every spec-driven command. They guide naming conventions, architecture decisions, and technology choices without duplicating exhaustive specifications.

The three core files are:
- `product.md` — purpose, users, value proposition
- `tech.md` — key frameworks, standards, conventions
- `structure.md` — organization patterns, naming rules

## When to Use

- At the start of a new project (before first spec).
- When the project has evolved significantly (major tech changes, restructuring).
- Invoked as: `/steering`

## Steps

### 1. Investigate the Project (if not greenfield)

Before writing anything, scan the codebase to understand:
- What the project does and who uses it
- Key technologies, frameworks, and versions
- Directory organization and naming patterns
- Architectural patterns and constraints
- Existing conventions (import style, error handling, etc.)

### 2. Create or Update `product.md`

Using template at `templates/steering/product.md`:

```markdown
# Product Overview
[Brief description of what this product does and who it serves]

## Core Capabilities
[3-5 key capabilities — not exhaustive features]

## Target Use Cases
[Primary scenarios this product addresses]

## Value Proposition
[What makes this product unique or valuable]
```

**Do NOT include:**
- Exhaustive feature lists
- Every API endpoint
- Deployment instructions

### 3. Create or Update `tech.md`

Using template at `templates/steering/tech.md`:

```markdown
# Technology Stack
## Architecture
[High-level design approach]

## Core Technologies
- Language: [e.g., TypeScript]
- Framework: [e.g., React, Next.js]
- Runtime: [e.g., Node.js 20+]

## Key Libraries
[Only major libraries that influence development patterns]

## Development Standards
### Type Safety / Code Quality / Testing
[Key standards and tools]

## Development Environment
[Required tools, common commands]

## Key Technical Decisions
[Important architectural choices and rationale]
```

### 4. Create or Update `structure.md`

Using template at `templates/steering/structure.md`:

```markdown
# Project Structure
## Organization Philosophy
[Feature-first, layered, domain-driven, etc.]

## Directory Patterns
[Key patterns — not a complete file tree]

## Naming Conventions
[Files, components, functions]

## Import Organization
[Path aliases, absolute vs relative patterns]

## Code Organization Principles
[Dependency rules, layering]
```

### 5. Verify and Summarize

After writing the files:
- Confirm all three files are present under `.agents/steering/`.
- Present a brief summary of the key decisions captured.
- Ask if anything is missing or needs correction.

## Steering Principles (from `rules/steering-principles.md`)

### Golden Rule
> "If new code follows existing patterns, steering shouldn't need updating."

### ✅ Document
- Organizational patterns (feature-first, layered)
- Naming conventions (PascalCase rules)
- Import strategies (absolute vs relative)
- Architectural decisions (state management)
- Technology standards (key frameworks)

### ❌ Avoid
- Complete file listings
- Every component description
- All dependencies
- Implementation details
- Agent-specific tooling directories (e.g., `.cursor/`, `.gemini/`, `.claude/`)
- Detailed documentation of `.agents/` metadata directories

## Templates

- [`templates/steering/product.md`](../../templates/steering/product.md)
- [`templates/steering/tech.md`](../../templates/steering/tech.md)
- [`templates/steering/structure.md`](../../templates/steering/structure.md)
- [`rules/steering-principles.md`](../../rules/steering-principles.md)

## Guardrails

- Target 100–200 lines per steering file.
- Never include secrets, API keys, credentials, or internal IPs.
- Steering files are additive by default — preserve existing user sections.
- Add `updated_at` timestamp and a brief note on what changed when updating.

## See Also

- [`steering-custom`](../steering-custom/SKILL.md) — create domain-specific steering files
- [`rules/steering-principles.md`](../../rules/steering-principles.md) — full steering guidelines
