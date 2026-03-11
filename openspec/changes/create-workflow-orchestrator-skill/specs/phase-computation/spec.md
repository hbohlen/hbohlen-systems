## ADDED Requirements

### Requirement: Compute phase from OpenSpec
The skill SHALL compute current phase from OpenSpec artifact states.

#### Scenario: All complete
- **WHEN** all artifacts are done
- **THEN** phase is "complete"

#### Scenario: In progress
- **WHEN** artifacts are in progress
- **THEN** phase is the earliest incomplete artifact

### Requirement: Compute phase from Beads
The skill SHALL compute current phase from beads state.

#### Scenario: Use bead type
- **WHEN** beads have phase types
- **THEN** current phase matches most recent bead type

### Requirement: Resolve conflicts
The skill SHALL handle conflicts between OpenSpec and Beads states.

#### Scenario: States match
- **WHEN** both systems agree on phase
- **THEN** use that phase

#### Scenario: States differ
- **WHEN** OpenSpec and Beads report different phases
- **THEN** prefer OpenSpec (source of truth) but warn user
