# Workflow Orchestrator Design

**Date:** 2026-03-11  
**Status:** Draft  
**Author:** AI Assistant

## Overview

Design for a reproducible AI agent workflow that combines beads (issue tracking), OpenSpec (spec-driven development), jj (version control), and pi-coding-agent (minimal skill framework) into a cohesive development methodology.

## Problem Statement

Solo developer with ADHD/OCD needs:
- Structured workflow to prevent getting lost or overwhelmed
- Clear checkpoints between phases
- Hierarchical task tracking with research capabilities
- Version control that supports parallel agent work
- Minimal, customizable agent framework

## Architecture

### Tool Integration

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    WORKFLOW ORCHESTRATOR                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐                   │
│   │   Beads     │     │  OpenSpec   │     │      jj     │                   │
│   │  (Issues)   │     │    (DAG)    │     │  (Version)  │                   │
│   ├─────────────┤     ├─────────────┤     ├─────────────┤                   │
│   │ Epic/Feature│     │ Artifacts   │     │ Workspaces  │                   │
│   │   Parent    │     │  + State    │     │  (parallel) │                   │
│   └─────────────┘     └─────────────┘     └─────────────┘                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

- **Beads**: Issue tracking with Dolt-backed storage; provides memory/context for all tasks
- **OpenSpec**: DAG-based artifact management; enforces workflow dependencies
- **jj**: Git-compatible version control with workspaces for parallel agent tasks
- **pi-coding-agent**: Minimal skill framework; base for custom workflow skills

## OpenSpec Schema: spec-driven-research

```yaml
name: spec-driven-research
artifacts:
  - id: exploration
    generates: exploration.md
    requires: []
    description: Free-form brainstorming and idea exploration

  - id: proposal
    generates: proposal.md
    requires: [exploration]
    description: Initial spec proposal (what & why)

  - id: spec-validation
    generates: validation.md
    requires: [proposal]
    description: Validate spec, identify gaps

  - id: research
    generates: research/**/*.md
    requires: [spec-validation]
    description: Research findings to fill spec gaps

  - id: specs
    generates: specs/**/*.md
    requires: [proposal, research]
    description: Detailed specifications

  - id: design
    generates: design.md
    requires: [specs]
    description: Technical design document

  - id: tasks
    generates: tasks.md
    requires: [design]
    description: Implementation tasks
```

> **Note:** For the workflow-orchestrator itself, the "research" phase specifically covers PI extensibility research (sub-agents, custom tools, hooks) before implementation begins.

## Bead Hierarchy

Parent bead represents the epic/feature. Child beads track each workflow phase:

```
bd-create "Feature: Add User Authentication" -t epic
    │
    ├── bd:explore        # type=exploration, status=done
    │   └── "Brainstorm auth approaches"
    │
    ├── bd:proposal       # type=proposal, status=done  
    │   └── "Create proposal for auth"
    │
    ├── bd:spec-validate # type=validation, status=done
    │   └── "Validate spec for auth"
    │
    ├── bd:research-*     # type=research, status=blocked (by spec gaps)
    │   ├── "Research OAuth providers"
    │   └── "Research token storage security"
    │
    ├── bd:specs          # type=spec, status=ready
    │   └── "Create detailed auth specs"
    │
    ├── bd:design         # type=design, status=blocked (by specs)
    │   └── "Design auth architecture"
    │
    └── bd:task-*         # type=task, status=blocked (by design)
        ├── "Implement OAuth flow"
        └── "Add token refresh"
```

## jj Workflow (Trunk-Based)

### Main Workspace
- Work directly on `main` for small changes
- Auto-commit with `jj describe` + `jj amend`

### Feature Workspaces
For isolation or parallel agent tasks:

```bash
# Create feature workspace
jj workspace add ../feature-name --name feature-add-auth

# Work in feature workspace
# ... implement ...

# Push feature branch
jj git push --bookmark feature-add-auth

# Or use change-based bookmark
jj git push --change @  # Creates push-XXXX bookmark
```

### Completion Flow
```bash
# Merge back to main
jj merge main feature-add-auth
jj git push
```

### Branch Rename
Rename `master` to `main`:
```bash
jj bookmark rename master main
jj git push --bookmark main
```

## Session Resume Flow

When starting a new session, workflow-orchestrator:

1. **Query OpenSpec state** → Which artifacts are ready/blocked/done?
2. **Query Beads state** → Which workflow phase beads exist and their status?
3. **Compute current phase** → Based on artifact + bead state
4. **Present resume point** → "You're in the Research phase. You have 2 research tasks blocked on spec gaps."

## Gap Analysis Flow

1. Run spec validation skill
2. Identify gaps → create child beads with type="research"
3. Each research bead can have child "research question" beads
4. Agent performs focused research, links findings to beads
5. Update spec with research findings
6. Re-run validation until passing

## Error Handling

### Beads Integration
- **Query failures**: Log error, display cached state if available, prompt for manual recovery
- **State inconsistencies**: Detect conflicts between bead status and OpenSpec state, flag for review

### OpenSpec Integration
- **Artifact state corruption**: Validate DAG integrity on load, offer repair options
- **Missing generated files**: Mark artifact as blocked, notify user

### jj Integration
- **Workspace conflicts**: Detect and present merge options
- **Push failures**: Display error, offer retry or force-push option (with warning)
- **Merge conflicts**: Present conflict resolution workflow

## Research Output Templates

Each research area should produce a document with the following structure:

```markdown
# Research: [Topic]

## Question
[What we're trying to find out]

## Findings
[Detailed research results]

## Recommendations
### Recommended Approach
[Specific approach to implement]

### Trade-offs
- [Pro/Con 1]
- [Pro/Con 2]

### Implementation Notes
[How to build it, key files, dependencies]
```

### Sub-agent System Research Deliverables
- Document available dispatch mechanisms (or lack thereof)
- Alternative approaches if native dispatch doesn't exist
- Recommended architecture for sub-agent execution

### Custom Tooling System Research Deliverables
- Tool registration API documentation
- Lifecycle management approach
- Security considerations for custom tools

### Hooks Design Research Deliverables
- Available lifecycle hooks enumeration
- Registration mechanism
- Execution order and error handling model

## Implementation Plan

### Phase 1: Research (PI Extensibility)

Before implementing the workflow orchestrator, we must understand pi's extensibility model:

1. **Sub-agent system research**
   - How to dispatch sub-agents from within pi
   - Available dispatch mechanisms (if any)
   - Alternative approaches if native dispatch doesn't exist

2. **Custom tooling system research**
   - How to register new tools beyond built-in read/bash/edit/write
   - Tool registration API and lifecycle
   - Tool execution model

3. **Hooks design research**
   - Available lifecycle hooks (session start, on completion, etc.)
   - How to register hooks
   - Hook execution order and error handling

**Research outputs:** Document findings in `docs/superpowers/research/pi-extensibility/` with recommendations for each system.

### Phase 2: Schema & Skill Creation

1. Create OpenSpec schema: `openspec/schemas/spec-driven-research/`
2. Create workflow-orchestrator skill: `.pi/skills/workflow-orchestrator/`
3. Create skill templates for session resume

### Phase 3: Version Control Setup

1. Rename master → main branch
2. Configure jj defaults

## Acceptance Criteria

### Phase 1: Research

- [ ] Sub-agent system research completed with documented approach
- [ ] Custom tooling system research completed with implementation plan
- [ ] Hooks design research completed with lifecycle specification
- [ ] Research findings reviewed and approved

### Phase 2: Schema & Skill

- [ ] OpenSpec schema created and validated
- [ ] Workflow-orchestrator skill can detect current phase
- [ ] Session resume shows clear next step
- [ ] Bead hierarchy matches workflow phases

### Phase 3: Version Control

- [ ] jj configured with main branch
- [ ] Workspaces can be created for features
