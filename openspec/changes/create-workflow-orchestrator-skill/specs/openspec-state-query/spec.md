## ADDED Requirements

### Requirement: Query current change state
The skill SHALL query the current OpenSpec change state.

#### Scenario: No current change
- **WHEN** no change is active
- **THEN** skill reports no active change

#### Scenario: Change is active
- **WHEN** a change is active
- **THEN** skill retrieves artifact statuses

### Requirement: Get artifact statuses
The skill SHALL retrieve status for all artifacts in the change.

#### Scenario: Parse artifact list
- **WHEN** querying change state
- **THEN** skill can identify which artifacts are done, ready, blocked

### Requirement: Identify blockers
The skill SHALL identify what is blocking ready artifacts.

#### Scenario: Blocked artifact
- **WHEN** an artifact is blocked
- **THEN** skill identifies the missing dependencies
