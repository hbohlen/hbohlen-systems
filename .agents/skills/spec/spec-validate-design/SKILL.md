---
name: spec-validate-design
description: Conduct a quality review of a completed design document and issue a GO/NO-GO recommendation. Focuses on the 3 most critical issues related to architecture alignment, consistency, and requirements fulfillment. Optional but recommended before task generation.
tags: [spec, workflow, design-review, validation]
category: spec
metadata:
  version: "1.0"
  source: .agents/
---

# spec-validate-design

Quality-review a completed design document and issue a GO/NO-GO recommendation.

## Overview

Evaluates `design.md` against project context, architecture standards, and the steering principles. The review is focused: it identifies at most 3 critical issues (not an exhaustive list) and delivers a clear GO/NO-GO decision. The goal is quality assurance, not perfection-seeking.

## When to Use

- After `design.md` has been generated.
- Before running `/spec-tasks` to catch fundamental flaws early.
- Invoked as: `/spec-validate-design <feature-name>`

## Steps

### 1. Load Context

- Read `.agents/specs/<feature-name>/design.md`
- Read `.agents/specs/<feature-name>/requirements.md`
- Read all `.agents/steering/` files as project memory
- Read `research.md` if it exists

### 2. Evaluate Against Core Criteria

#### A. Existing Architecture Alignment (Critical)
- Integration with existing system boundaries and layers
- Consistency with established architectural patterns
- Proper dependency direction and coupling management
- Alignment with current module organization

#### B. Design Consistency & Standards
- Adherence to project naming conventions and code standards
- Consistent error handling and logging strategies
- Uniform configuration and dependency management
- Alignment with established data modeling patterns

#### C. Extensibility & Maintainability
- Design flexibility for future requirements
- Clear separation of concerns and single responsibility
- Testability and debugging considerations
- Appropriate complexity for requirements

#### D. Type Safety & Interface Design
- Proper type definitions and interface contracts
- Avoidance of unsafe patterns (e.g., `any` in TypeScript)
- Clear API boundaries and data structures
- Input validation and error handling coverage

### 3. Identify Critical Issues (≤ 3)

For each issue, document:
```
🔴 Critical Issue [N]: [Brief title]
Concern: [Specific problem]
Impact: [Why it matters]
Suggestion: [Concrete improvement]
Traceability: [Requirement ID or section from requirements.md]
Evidence: [design.md section/heading where the issue appears]
```

Limit to the **3 most impactful** concerns. Do not produce an exhaustive list of minor issues.

### 4. Recognize Strengths

Acknowledge 1–2 strong aspects of the design to maintain balanced feedback.

### 5. Issue GO/NO-GO Decision

**GO**: No critical architectural misalignment, requirements addressed, clear implementation path, acceptable risks.

**NO-GO**: Fundamental conflicts with existing architecture, critical requirement gaps, high failure risk, or disproportionate complexity.

### 6. Output Report

```markdown
## Design Review Summary
[2–3 sentences on overall quality and readiness]

## Critical Issues (≤ 3)
[Structured issue blocks as above]

## Design Strengths
[1–2 positive aspects]

## Final Assessment
Decision: GO / NO-GO
Rationale: [1–2 sentences]
Next Steps: [What to do]
```

Keep the full review to approximately 400 words.

### 7. Engage Interactively

After presenting the review, ask whether the designer wants to discuss any issues or alternatives before proceeding.

## Reference Rules

See [`rules/design-review.md`](../../rules/design-review.md) for the authoritative review process.

## Guardrails

- Limit critical issues to **3 maximum** — focus on the highest-impact concerns.
- Each issue must include Evidence (design.md section) and Traceability (requirement ID).
- Do not perform implementation-level design or deep technology research during review.
- Constructive tone: provide solutions, not just criticism.
- A GO decision does not require a perfect design — it requires acceptable risk.

## See Also

- [`spec-design`](../spec-design/SKILL.md) — design generation (pre-review)
- [`spec-tasks`](../spec-tasks/SKILL.md) — next step after a GO decision
- [`rules/design-review.md`](../../rules/design-review.md) — full review framework
