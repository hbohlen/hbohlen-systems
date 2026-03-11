## ADDED Requirements

### Requirement: Bead contains JJ change ID reference
Each bead SHALL store the associated jj change ID for traceability.

#### Scenario: Link bead to jj change
- **WHEN** a bead is created for a task
- **THEN** user can store the jj change ID in the bead's notes or metadata

#### Scenario: Reference bead from jj commit
- **WHEN** user creates a jj commit with a message
- **THEN** the bead ID (e.g., `bd-123`) can be referenced in the commit message

### Requirement: JJ operations are tracked in bead history
Beads SHALL be able to track jj operations for audit purposes.

#### Scenario: Record jj operation
- **WHEN** user performs a jj operation (describe, bookmark, etc.)
- **THEN** the operation can be recorded in the bead's notes

### Requirement: Resume from jj state
The system SHALL support resuming work based on jj state.

#### Scenario: Find bead from jj change
- **WHEN** user has a jj change ID
- **THEN** they can search beads for related work by parsing commit messages or notes

#### Scenario: Checkout jj change from bead
- **WHEN** user references a bead's jj change ID
- **THEN** they can use `jj co <change-id>` to restore that state
