---
name: steering-custom
description: Create a custom steering file for a specialized domain (e.g., api-standards, authentication, database, testing, security, deployment, error-handling). Adds domain-specific project memory beyond the three core steering files.
tags: [spec, steering, project-memory, custom]
category: spec
metadata:
  version: "1.0"
  source: .agents/
---

# steering-custom

Create a custom domain-specific steering file under `.agents/steering/`.

## Overview

Custom steering files extend the three core files (`product.md`, `tech.md`, `structure.md`) with specialized project memory for domains that have recurring patterns, important constraints, or team-specific conventions.

All steering files—core and custom—are equally important and are loaded as project context.

## When to Use

- When a domain has significant patterns that would otherwise be repeated in every spec.
- Invoked as: `/steering-custom`
- Or: `/steering-custom <domain-name>` to target a specific file.

## Available Custom Domain Templates

| File | Domain |
|------|--------|
| `api-standards.md` | REST/GraphQL conventions, versioning, rate limits |
| `authentication.md` | Auth patterns, JWT, session management, authorization |
| `database.md` | Data access patterns, migrations, ORM conventions |
| `deployment.md` | CI/CD, environment configs, release process |
| `error-handling.md` | Error categories, logging, monitoring standards |
| `security.md` | Security controls, threat models, compliance |
| `testing.md` | Test strategies, coverage standards, tooling |

Templates are located at `templates/steering-custom/`.

## Steps

### 1. Choose or Confirm Domain

- If the user specified a domain, use it.
- If not, ask: "Which domain do you want to create custom steering for?"
  - Present the available options above.
  - Allow custom domain names not in the list.

### 2. Check for Existing File

- Check if `.agents/steering/<domain>.md` already exists.
- If yes, ask: "A steering file for `<domain>` already exists. Do you want to update it or start fresh?"

### 3. Investigate Relevant Code

Scan the codebase for domain-specific patterns:
- For `api-standards`: look for route definitions, middleware, response formats
- For `authentication`: look for auth guards, JWT usage, session handling
- For `database`: look for ORM usage, migration files, query patterns
- For `testing`: look for test framework, fixtures, coverage config
- Etc.

### 4. Generate the Custom Steering File

Using the appropriate template from `templates/steering-custom/`:
- Fill in sections based on actual patterns found in the codebase.
- Follow the same granularity principles as core steering files.
- Target 100–200 lines.
- Include concrete code examples showing patterns (not exhaustive implementations).
- Explain rationale where decisions were made deliberately.

### 5. Write to `.agents/steering/<domain>.md`

### 6. Confirm and Summarize

- Show the file created.
- Present 2–3 key patterns now documented.
- Confirm: "This file will be loaded as project memory for all future specs."

## Steering Principles

Follow the same principles as core steering (see `rules/steering-principles.md`):

### ✅ Document
- Conventions and patterns specific to this domain
- Rationale for key decisions
- Code examples illustrating the pattern
- Cross-references to relevant specs or external standards

### ❌ Avoid
- Exhaustive implementations
- Secrets, credentials, or internal service URLs
- Agent-specific tooling conventions

## Templates

- [`templates/steering-custom/api-standards.md`](../../templates/steering-custom/api-standards.md)
- [`templates/steering-custom/authentication.md`](../../templates/steering-custom/authentication.md)
- [`templates/steering-custom/database.md`](../../templates/steering-custom/database.md)
- [`templates/steering-custom/deployment.md`](../../templates/steering-custom/deployment.md)
- [`templates/steering-custom/error-handling.md`](../../templates/steering-custom/error-handling.md)
- [`templates/steering-custom/security.md`](../../templates/steering-custom/security.md)
- [`templates/steering-custom/testing.md`](../../templates/steering-custom/testing.md)
- [`rules/steering-principles.md`](../../rules/steering-principles.md)

## Guardrails

- Never duplicate information already in `product.md`, `tech.md`, or `structure.md`.
- Keep files focused on one domain per file.
- Custom steering files are additive — do not remove existing content unless it's incorrect.
- Add `updated_at` timestamp when modifying existing files.

## See Also

- [`steering`](../steering/SKILL.md) — core steering setup
- [`rules/steering-principles.md`](../../rules/steering-principles.md) — steering quality standards
