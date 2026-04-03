## Requirements

### Requirement: opencode available in devShell
The devShell SHALL include the `opencode` package from the `llm-agents.nix` flake input.

#### Scenario: opencode is in devShell packages
- **WHEN** a user enters the devShell via `nix develop`
- **THEN** the `opencode` binary is available on `$PATH`
