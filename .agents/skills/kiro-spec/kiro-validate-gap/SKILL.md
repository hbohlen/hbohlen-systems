---
name: kiro-validate-gap
description: Analyze the gap between requirements and the existing codebase to determine implementation strategy. Produces a gap analysis report covering what exists, what's missing, and recommended approach (Extend / New / Hybrid). Optional but recommended for features modifying existing systems.
tags: [kiro-spec, workflow, gap-analysis, validation]
category: kiro-spec
metadata:
  version: "1.0"
  source: .kiro/settings/
---

# kiro-validate-gap

Perform a gap analysis between approved requirements and the existing codebase.

## Overview

Investigates the current system and identifies what already exists, what's missing, and which implementation strategy (extend, create new, or hybrid) best fits the feature. Output is captured in a gap analysis report or appended to `requirements.md`.

## When to Use

- After requirements are approved, before design.
- When the feature modifies or extends an existing system.
- Skip for greenfield projects with no existing code to analyze.
- Invoked as: `/kiro-validate-gap <feature-name>`

## Steps

### 1. Current State Investigation

- Scan the codebase for domain-related assets:
  - Key files, modules, and directory layout relevant to the feature
  - Reusable components, services, or utilities that could be leveraged
  - Dominant architecture patterns and constraints
- Extract conventions:
  - Naming, layering, dependency direction
  - Import/export patterns and dependency hotspots
  - Testing placement and approach
- Note integration surfaces:
  - Data models/schemas, API clients, auth mechanisms

### 2. Requirements Feasibility Analysis

For each requirement in `requirements.md`:
- Identify technical needs: data models, APIs/services, UI/components, business rules
- Tag each need as: **Exists** / **Missing** / **Unknown** / **Constraint**
- Note non-functional requirements: security, performance, scalability, reliability

### 3. Evaluate Implementation Approach

#### Option A: Extend Existing Components
- Which files/modules to extend
- Compatibility and backward compatibility concerns
- Trade-offs: ✅ Minimal new files ❌ Risk of bloating

#### Option B: Create New Components
- Rationale for new creation
- Integration points with existing system
- Trade-offs: ✅ Clean separation ❌ More files to navigate

#### Option C: Hybrid Approach
- Which parts extend vs. which are new
- Migration/phased strategy if needed
- Trade-offs: ✅ Balanced ❌ More coordination required

### 4. Complexity & Risk Assessment

Assign effort and risk labels:
| Label | Definition |
|-------|-----------|
| S | 1–3 days: existing patterns, minimal deps |
| M | 3–7 days: some new patterns, moderate complexity |
| L | 1–2 weeks: significant functionality, multiple integrations |
| XL | 2+ weeks: architectural changes, broad impact |

| Risk | Definition |
|------|-----------|
| High | Unknown tech, complex integrations, architectural shifts |
| Medium | New patterns with guidance, manageable integrations |
| Low | Extend established patterns, familiar tech, clear scope |

### 5. Output

Produce a gap analysis summary (can be a separate `gap-analysis.md` or a section in `requirements.md`) containing:
- Requirement-to-Asset Map with gap tags (Missing / Unknown / Constraint)
- Options A/B/C with rationale and trade-offs
- Effort (S/M/L/XL) and Risk (High/Medium/Low) with one-line justification
- Recommended approach and key decisions for the design phase
- Research items to carry forward

## Reference Rules

See [`rules/gap-analysis.md`](../../rules/gap-analysis.md) for the authoritative analysis framework.

## Guardrails

- Defer deep research to the design phase — only record unknowns as "Research Needed."
- Do not make final architecture decisions here — provide options and analysis.
- Flag all assumptions and unknowns explicitly.
- This step is informational; the design phase makes the binding decisions.

## See Also

- [`kiro-spec-design`](../kiro-spec-design/SKILL.md) — next step after gap analysis
- [`kiro-spec-requirements`](../kiro-spec-requirements/SKILL.md) — prerequisites
- [`rules/gap-analysis.md`](../../rules/gap-analysis.md) — full analysis framework
