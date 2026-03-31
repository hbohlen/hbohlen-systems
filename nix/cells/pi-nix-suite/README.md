# pi-nix-suite

Nix integration suite for the [pi](https://github.com/badlogic/pi-mono) coding agent. Provides tmux-based subagent spawning, REPL integration, and Nix-specific tooling.

## Features

- **Subagent Management** (`/subagent`) - Spawn specialized agents in tmux windows
- **REPL Integration** (`/repl`) - Open nix, python, or node REPLs in split panes
- **Nix Expert** (`/nix`) - Quick access to Nix specialist agent
- **Flake Checking** (`/flake-check`) - Run and debug nix flake checks
- **Agent Templates** - Pre-configured agents: scout, worker, nix-expert
- **Default Skills** - Reusable patterns for common Nix workflows

## Installation

### Via Nix ( flakes)

```nix
{
  inputs.pi-nix-suite = {
    url = "path:./nix/cells/pi-nix-suite";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, pi-nix-suite, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = [ pi-nix-suite.packages.${system}.default ];
      };
    };
}
```

### Manual Setup

```bash
# Run the setup script to link commands into ~/.pi
pi-nix-suite-setup
```

## Usage

### Slash Commands

Once installed, these commands are available in pi:

#### /subagent

Spawn a subagent in a new tmux window:

```
/subagent "Explore the codebase structure" --agent=scout
/subagent "Implement error handling" --agent=worker
/subagent "Debug this flake" --agent=nix-expert
```

Agent types:
- **scout** - Fast reconnaissance (lightweight model)
- **worker** - Implementation agent (capable model)
- **nix-expert** - Nix specialist with deep knowledge

Navigation:
- Press `Ctrl+B` then window number to view
- Press `Ctrl+B` then `0` to return to main window

#### /repl

Open a REPL in a horizontal split:

```
/repl nix     # nix repl .#
/repl python  # Python (auto-detects venv)
/repl node    # Node.js
```

Navigation:
- Use `Ctrl+B` + arrow keys to move between panes
- Type `exit` or `Ctrl+D` to close REPL

#### /nix

Quick access to the Nix expert:

```
/nix "Debug this flake error"
/nix "How do I add a new system configuration?"
```

#### /flake-check

Run nix flake check with helpful error context:

```
/flake-check        # Check current directory
/flake-check ./path # Check specific flake
```

## Directory Structure

```
pi-nix-suite/
├── commands/           # Slash command scripts
│   ├── subagent
│   ├── repl
│   ├── nix
│   └── flake-check
├── templates/          # Agent system prompts
│   ├── agent-scout.md
│   ├── agent-worker.md
│   └── agent-nix-expert.md
├── skills/             # Reusable skill definitions
│   ├── nixos-deploy.md
│   └── flake-debug.md
└── default.nix         # Nix package definition
```

## Configuration

Commands and templates are installed to:

- Global: `~/.pi/agent/commands/`, `~/.pi/agent/templates/`
- Project: `./.pi/commands/` (pi also checks here)

Set `PI_NIX_SUITE_DIR` to override the installation source.

## Requirements

- [pi](https://github.com/badlogic/pi-mono) - The coding agent
- tmux - For window/pane management
- nix - For Nix-specific features

## License

MIT
