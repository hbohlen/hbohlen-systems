## ADDED Requirements

### Requirement: Present current phase
The skill SHALL present the current workflow phase to the user.

#### Scenario: Show phase
- **WHEN** computing current phase
- **THEN** skill displays "Current Phase: <phase-name>"

### Requirement: Show ready items
The skill SHALL show items ready for work.

#### Scenario: Ready artifacts
- **WHEN** artifacts are ready
- **THEN** skill lists them under "Ready to work on:"

### Requirement: Show blockers
The skill SHALL show what is blocking progress.

#### Scenario: Blocked items
- **WHEN** items are blocked
- **THEN** skill lists them under "Blocked by:" with reasons

### Requirement: Provide next action
The skill SHALL suggest the next action.

#### Scenario: Has ready items
- **WHEN** items are ready
- **THEN** skill suggests "Run /opsx:apply or work on <item>"

#### Scenario: All complete
- **WHEN** all items are done
- **THEN** skill suggests next steps like creating new change
