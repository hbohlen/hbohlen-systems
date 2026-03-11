## ADDED Requirements

### Requirement: JJ is initialized in the project
The system SHALL initialize jj in the project directory, creating the `.jj/` directory and configuring git interoperability.

#### Scenario: Fresh jj init
- **WHEN** `jj init --git` is run in an existing git repository
- **THEN** jj is initialized with git backend, existing git history is preserved

#### Scenario: jj detects existing git repo
- **WHEN** `jj init` is run in a directory with `.git/`
- **THEN** jj automatically uses git backend

### Requirement: Common jj aliases are configured
The system SHALL provide convenient aliases for frequently used jj commands.

#### Scenario: jj describe alias
- **WHEN** user runs `jj describe` or configured alias
- **THEN** the current change is described with a session-friendly message

#### Scenario: jj sync alias
- **WHEN** user runs `jj sync` (custom alias)
- **THEN** `jj git push && jj git pull` executes in sequence

### Requirement: Session bookmarks are used
The system SHALL use jj bookmarks for session-based development.

#### Scenario: Create session bookmark
- **WHEN** user creates a new bookmark with `jj bookmark start-<task-name>`
- **THEN** a new bookmark is created at current `@`

#### Scenario: Switch sessions
- **WHEN** user runs `jj bookmark <existing-bookmark>`
- **THEN** the working copy is updated to that bookmark's state
