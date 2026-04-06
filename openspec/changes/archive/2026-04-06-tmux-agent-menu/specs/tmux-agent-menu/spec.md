## ADDED Requirements

### Requirement: Agent menu displays existing sessions

The agent-menu fish script SHALL display a list of active tmux sessions with agent type, project name, and last-active time when launched.

#### Scenario: Sessions exist
- **WHEN** user runs `agent-menu` and active tmux sessions exist
- **THEN** a numbered list of sessions is displayed with session name, agent type, and last-active timestamp

#### Scenario: No sessions exist
- **WHEN** user runs `agent-menu` and no tmux sessions exist
- **THEN** the menu displays "No active sessions" and shows only the "New session" option

### Requirement: Agent menu creates new sessions

The agent-menu fish script SHALL allow users to create new agent sessions by selecting an agent type and providing a project path.

#### Scenario: Create opencode session
- **WHEN** user selects "New session" and chooses "opencode" and provides a project path
- **THEN** a git worktree is created at `<project>/.worktrees/agent-opencode-<date>/` on branch `agent/opencode-<date>`
- **AND** a tmux session named `<project-basename>` is created with two windows
- **AND** window 0 contains a fish shell with `nix develop` active in the worktree
- **AND** window 1 contains `opencode` running with `nix develop` active in the worktree

#### Scenario: Create pi session
- **WHEN** user selects "New session" and chooses "pi" and provides a project path
- **THEN** a git worktree is created with branch `agent/pi-<date>`
- **AND** a tmux session is created with shell in window 0 and `pi` in window 1

#### Scenario: Create hermes session
- **WHEN** user selects "New session" and chooses "hermes" and provides a project path
- **THEN** a git worktree is created with branch `agent/hermes-<date>`
- **AND** a tmux session is created with shell in window 0 and `hermes-agent` in window 1

### Requirement: Agent menu navigates to sessions

The agent-menu fish script SHALL allow users to select an existing session and attach to it.

#### Scenario: Select existing session
- **WHEN** user selects a numbered existing session from the menu
- **THEN** tmux attaches to that session

### Requirement: Sessions auto-activate nix develop

Each tmux window in an agent session SHALL have the project's nix development environment available.

#### Scenario: Window launches with nix develop
- **WHEN** a tmux window is created in an agent session
- **THEN** the shell is launched via `nix develop --command fish` in the worktree directory
- **AND** all packages from the project's flake.nix devShell are available

### Requirement: Sessions use git worktrees for isolation

Each agent session SHALL operate in an isolated git worktree to prevent branch conflicts between parallel agents.

#### Scenario: Worktree is created
- **WHEN** a new session is created for project at path `/home/hbohlen/dev/my-project`
- **THEN** a worktree is created at `/home/hbohlen/dev/my-project/.worktrees/agent-<type>-<date>/`
- **AND** the worktree is on a new branch `agent/<type>-<date>`
- **AND** changes in the worktree do not affect the main working tree

### Requirement: Session windows are labeled

Each tmux window in an agent session SHALL be named to indicate its purpose.

#### Scenario: Window names are set
- **WHEN** a session is created
- **THEN** window 0 is named "shell"
- **AND** window 1 is named the agent type (e.g., "opencode", "pi", "hermes")
