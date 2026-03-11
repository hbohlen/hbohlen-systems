## ADDED Requirements

### Requirement: Query workflow phase beads
The skill SHALL query beads for workflow phase tracking.

#### Scenario: Get open beads
- **WHEN** querying beads
- **THEN** skill retrieves open beads with workflow phase types

### Requirement: Map bead types to phases
The skill SHALL map bead types to workflow phases.

#### Scenario: Proposal type bead
- **WHEN** a bead has type "proposal"
- **THEN** skill maps it to proposal phase

### Requirement: Identify current phase bead
The skill SHALL identify the most recent workflow phase bead.

#### Scenario: Find current phase
- **WHEN** multiple phase beads exist
- **THEN** most recent in-progress or ready bead is current
