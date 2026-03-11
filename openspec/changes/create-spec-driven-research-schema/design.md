## Context

The workflow orchestrator design specifies a DAG-based artifact management system using OpenSpec. Currently, no custom schema exists - we're using the default schema. We need to create the `spec-driven-research` schema that defines the phased workflow for spec-driven development with embedded research.

## Goals / Non-Goals

**Goals:**
- Create OpenSpec schema with artifact dependency DAG
- Define phases: exploration, proposal, spec-validation, research, specs, design, tasks
- Support research as a first-class artifact type
- Enable phase detection from artifact states

**Non-Goals:**
- Implement the workflow orchestrator skill (separate change)
- Create research output templates (documented in design)
- Configure jj integration (separate change)

## Decisions

### 1. Schema Structure
**Decision**: Use the artifact-based schema with explicit dependency chains.

**Rationale**: OpenSpec's artifact system naturally models the workflow phases with `requires` fields.

**Alternatives considered**:
- Custom state machine - would require more code, less declarative
- Flat task list - loses dependency tracking

### 2. Research Artifact Type
**Decision**: Include research as a blocking artifact that can have child artifacts.

**Rationale**: Research often spawns sub-questions that need tracking. Making research a first-class artifact enables this hierarchy.

**Alternatives considered**:
- Research as ad-hoc exploration - loses structure
- Research as part of proposal - too early in workflow

### 3. Validation Phase
**Decision**: Include explicit spec-validation phase between proposal and research.

**Rationale**: Validating specs before research ensures we're researching the right things.

**Alternatives considered**:
- Skip validation - risks research misalignment
- Multiple validation passes - adds complexity

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|------------|
| Schema too rigid | Can't handle edge cases | Allow skipping phases via explicit flags |
| Phase detection complex | Hard to determine current phase | Create helper skill to compute state |
| Research artifacts proliferate | Too many research docs | Guidelines for consolidation |

## Open Questions

1. Should research artifacts be required or optional per change?
2. Can multiple research artifacts run in parallel?
3. How to handle research that invalidates the original proposal?
