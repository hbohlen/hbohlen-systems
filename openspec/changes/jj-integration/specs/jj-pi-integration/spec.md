## ADDED Requirements

### Requirement: PI can execute jj commands
The pi bash tool SHALL support executing jj commands.

#### Scenario: PI runs jj log
- **WHEN** pi executes `jj log`
- **THEN** the output is returned in structured form

#### Scenario: PI creates jj bookmark
- **WHEN** pi runs `jj bookmark create <name>`
- **THEN** a new bookmark is created in the jj repo

### Requirement: PI can use jj for worktree isolation
The system SHALL support using jj bookmarks or worktrees for isolating pi sessions.

#### Scenario: PI works in isolated bookmark
- **WHEN** pi session starts with a specific bookmark
- **THEN** pi operates on that bookmark's working copy

#### Scenario: PI creates worktree for heavy isolation
- **WHEN** a separate jj worktree is created
- **THEN** pi can operate in that isolated directory

### Requirement: PI hooks can trigger jj operations
The pi hooks system SHALL support jj integration points.

#### Scenario: jj sync on session end
- **WHEN** pi session completes
- **THEN** a hook can trigger `jj git push` to sync changes

#### Scenario: jj undo on session abort
- **WHEN** pi session is interrupted (compaction)
- **THEN** hooks can support rollback via `jj undo`
