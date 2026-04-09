## Requirements

### Requirement: tmux is installed on NixOS

tmux SHALL be available on the NixOS system via home-manager configuration.

#### Scenario: tmux binary available
- **WHEN** user logs into the NixOS system
- **THEN** `tmux` is available in PATH

### Requirement: tmux is available in devShells

tmux SHALL be available in both the default and ai devShells.

#### Scenario: tmux in default devShell
- **WHEN** user runs `nix develop` in the project
- **THEN** `tmux` is available in PATH

#### Scenario: tmux in ai devShell
- **WHEN** user runs `nix develop .#ai` in the project
- **THEN** `tmux` is available in PATH

### Requirement: tmux-resurrect persists sessions

tmux-resurrect plugin SHALL be configured to save and restore tmux sessions across reboots.

#### Scenario: Save sessions
- **WHEN** user presses prefix + Ctrl-s
- **THEN** all current tmux sessions, windows, and panes are saved

#### Scenario: Restore sessions
- **WHEN** user presses prefix + Ctrl-r
- **THEN** previously saved tmux sessions, windows, and panes are restored

### Requirement: tmux has extended keys enabled

tmux SHALL be configured with extended keys support for compatibility with AI agents that use modified key sequences.

#### Scenario: Extended keys configured
- **WHEN** tmux starts
- **THEN** `extended-keys on` and `extended-keys-format csi-u` are set
- **AND** agents like pi can receive Shift+Enter, Ctrl+Enter correctly

### Requirement: tmux supports 256 colors

tmux SHALL be configured for 256-color terminal support.

#### Scenario: Color support
- **WHEN** tmux starts
- **THEN** `default-terminal` is set to `tmux-256color`
- **AND** applications inside tmux can use 256 colors

### Requirement: tmux enables mouse support

tmux SHALL have mouse mode enabled for window/pane selection and resizing.

#### Scenario: Mouse works
- **WHEN** user clicks a tmux pane
- **THEN** that pane becomes active
- **WHEN** user drags a pane border
- **THEN** the pane resizes

### Requirement: tmux uses vi mode

tmux keybindings SHALL use vi mode for copy-mode navigation.

#### Scenario: Vi copy mode
- **WHEN** user enters tmux copy mode (prefix + [)
- **THEN** vi keybindings are active for navigation and selection
