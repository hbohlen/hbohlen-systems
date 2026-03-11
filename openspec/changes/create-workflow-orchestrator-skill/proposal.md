## Why

The workflow orchestrator needs a skill that can detect the current workflow phase from OpenSpec and beads state, and present clear resume points for session recovery. This is critical for multi-session development where context may be lost between sessions.

## What Changes

- Create new pi skill: `.pi/skills/workflow-orchestrator/`
- Skill queries OpenSpec state for artifact statuses
- Skill queries beads state for workflow phase beads
- Skill computes current phase and presents resume point

## Capabilities

### New Capabilities

- **workflow-orchestrator-skill**: The main skill for phase detection and resume
- **openspec-state-query**: Ability to query OpenSpec change state
- **beads-state-query**: Ability to query beads workflow phase
- **phase-computation**: Logic to compute current phase from both states
- **resume-presentation**: Format and present resume point to user

### Modified Capabilities

- (none - new skill)

## Impact

- New skill directory: `.pi/skills/workflow-orchestrator/`
- New skill: `workflow-orchestrator`
- Updated skills documentation
