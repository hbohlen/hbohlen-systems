## ADDED Requirements

### Requirement: Current phase is detectable
The system SHALL determine the current workflow phase from artifact states.

#### Scenario: All artifacts done
- **WHEN** all artifacts are marked done
- **THEN** current phase is "complete"

#### Scenario: Tasks is current
- **WHEN** tasks is ready but not done
- **THEN** current phase is "tasks"

#### Scenario: Multiple artifacts in progress
- **WHEN** multiple artifacts are in progress
- **THEN** earliest artifact in dependency chain is the current phase

### Requirement: Phase maps to bead types
The system SHALL map workflow phases to corresponding bead types.

#### Scenario: Map proposal to bead type
- **WHEN** current phase is proposal
- **THEN** corresponding bead type is "proposal"

### Requirement: Blockers are identifiable
The system SHALL identify what is blocking the current phase.

#### Scenario: Identify blocker
- **WHEN** current phase is blocked
- **THEN** the blocking artifact is identified
