## MODIFIED Requirements

### Requirement: tmux is installed on NixOS

tmux SHALL be available on the NixOS system via home-manager configuration. The tmux HM module SHALL be located in `home/tmux.nix` and composed via `home/default.nix`.

#### Scenario: tmux binary available
- **WHEN** user logs into the NixOS system
- **THEN** `tmux` is available in PATH

#### Scenario: tmux module location
- **WHEN** searching for the tmux home-manager configuration
- **THEN** it is found in `home/tmux.nix`, not in `modules/tmux.nix`
- **AND** it is imported by `home/default.nix`, not by defining `home-manager.users.hbohlen` inline