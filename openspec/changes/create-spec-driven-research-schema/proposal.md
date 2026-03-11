## Why

The workflow orchestrator needs a structured OpenSpec schema that supports research-driven development. The current generic schema doesn't provide the phased workflow (exploration → proposal → research → specs → design → tasks) needed for systematic feature development with embedded research phases.

## What Changes

- Create new OpenSpec schema: `spec-driven-research`
- Define artifact pipeline: exploration → proposal → spec-validation → research → specs → design → tasks
- Add research artifact type for gap-filling investigations
- Configure schema at `openspec/schemas/spec-driven-research/`

## Capabilities

### New Capabilities

- **spec-driven-research-schema**: The new schema defining artifact dependencies and phases
- **research-phase**: Capability to embed focused research within the spec workflow
- **phase-detection**: Ability to detect current workflow phase from artifact states

### Modified Capabilities

- (none - new schema)

## Impact

- New directory: `openspec/schemas/spec-driven-research/`
- New schema configuration in `openspec/config.yaml`
- Workflow orchestrator will use this schema for new changes
