## MODIFIED Requirements

### Requirement: opencode available in devShell

The devShell SHALL include the `opencode` package from the `llm-agents.nix` flake input. The devshell module SHALL be located in `parts/devshell.nix`.

#### Scenario: opencode is in devShell packages
- **WHEN** a user enters the devShell via `nix develop`
- **THEN** the `opencode` binary is available on `$PATH`

#### Scenario: devshell module location
- **WHEN** searching for the devshell configuration
- **THEN** it is found in `parts/devshell.nix`, not in `modules/devshell.nix`