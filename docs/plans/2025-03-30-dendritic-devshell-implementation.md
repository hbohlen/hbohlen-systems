# Dendritic DevShell Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Create a minimal, working devShell using flake-parts and dendritic cells pattern that provides fish, starship, zoxide, direnv, pi, and ADHD-friendly tooling.

**Architecture:** flake-parts-based Nix flake with dendritic cells pattern. Each cell is self-contained in `nix/cells/`. Root flake.nix imports flake-parts and loads cells. The devShell cell defines packages, shell hook, and tool configurations.

**Tech Stack:** Nix, flake-parts, fish shell, starship, zoxide, direnv, llm-agents.nix (pi)

---

## Task 1: Create Root flake.nix

**Objective:** Create the root flake with flake-parts, nixpkgs, and llm-agents inputs, loading the dendritic cells structure.

**Files:**
- Create: `flake.nix`

**Step 1: Write the flake.nix**

```nix
{
  description = "hbohlen-systems - dendritic personal infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      imports = [
        ./nix/cells/devshells
      ];
    };
}
```

**Step 2: Verify syntax**

Run: `nix flake check --no-build 2>&1 | head -20`

Expected: Error about missing `./nix/cells/devshells` (we'll create it next)

**Step 3: Commit**

```bash
git add flake.nix
git commit -m "feat: add root flake.nix with flake-parts structure"
```

---

## Task 2: Create Directory Structure

**Objective:** Create the dendritic cells directory structure for the devShell.

**Files:**
- Create: `nix/cells/devshells/default.nix`
- Create: `nix/cells/devshells/config/` (for fish/starship configs)

**Step 1: Create directories**

```bash
mkdir -p nix/cells/devshells/config
```

**Step 2: Verify structure**

Run: `find nix -type d`

Expected:
```
nix
nix/cells
nix/cells/devshells
nix/cells/devshells/config
```

**Step 3: Commit**

```bash
git add nix/
git commit -m "chore: create dendritic cells directory structure"
```

---

## Task 3: Create Basic DevShell Cell

**Objective:** Create the devShell cell that defines packages and a basic shell hook.

**Files:**
- Create: `nix/cells/devshells/default.nix`

**Step 1: Write the devShell cell**

```nix
{ inputs, ... }:
{
  perSystem = { config, self', inputs', pkgs, system, ... }:
    let
      # Import llm-agents packages
      llm-agents-packages = inputs.llm-agents.packages.${system};
    in
    {
      devShells.default = pkgs.mkShell {
        name = "hbohlen-systems";

        packages = with pkgs; [
          # Core shell
          fish
          starship
          direnv
          nix-direnv

          # Navigation & search
          eza
          ripgrep
          zoxide
          fzf

          # Editor & dev tools
          neovim
          git

          # AI/Agents
          llm-agents-packages.pi

          # LSPs & formatters
          nil
          lua-language-server
          stylua
          ast-grep
        ];

        shellHook = ''
          echo "Entering hbohlen-systems devShell..."
          export SHELL=${pkgs.fish}/bin/fish

          # Start fish if not already in fish
          if [[ -z "$FISH_VERSION" ]]; then
            exec ${pkgs.fish}/bin/fish
          fi
        '';
      };
    };
}
```

**Step 2: Verify syntax**

Run: `nix flake check --no-build 2>&1 | head -20`

Expected: No errors or warnings about syntax

**Step 3: Test devShell entry**

Run: `nix develop --command echo "Shell entered successfully"`

Expected: "Shell entered successfully" (may take a while on first run)

**Step 4: Commit**

```bash
git add nix/cells/devshells/default.nix
git commit -m "feat: add basic devShell with packages"
```

---

## Task 4: Create Starship Configuration

**Objective:** Create a minimal, ADHD-friendly starship configuration file.

**Files:**
- Create: `nix/cells/devshells/config/starship.toml`

**Step 1: Write starship.toml**

```toml
# Minimal, ADHD-friendly starship config
# Shows: directory (truncated), git branch + status

format = """
$directory$git_branch$git_status
$character"""

# Directory - show current location, truncate if deep
[directory]
truncation_length = 3
truncation_symbol = ".../"
format = "[$path]($style) "
style = "cyan"

# Git branch - show current branch
[git_branch]
symbol = ""
format = "[$symbol$branch]($style) "
style = "purple"

# Git status - show dirty state only
[git_status]
format = '([$all_status$ahead_behind]($style) )'
style = "yellow"
conflicted = "✘"
ahead = "⇡"
behind = "⇣"
diverged = "⇕"
up_to_date = ""
untracked = "?"
stashed = ""
modified = "✎"
staged = "+"
renamed = "→"
deleted = "✘"

# Character prompt
[character]
success_symbol = "[>](green)"
error_symbol = "[>](red)"

# Disable everything else
[username]
disabled = true
[hostname]
disabled = true
[time]
disabled = true
[cmd_duration]
disabled = true
[line_break]
disabled = true
[battery]
disabled = true
```

**Step 2: Update devShell to include starship config**

Modify `nix/cells/devshells/default.nix` shellHook section:

```nix
        shellHook = ''
          echo "Entering hbohlen-systems devShell..."
          export SHELL=${pkgs.fish}/bin/fish

          # Set starship config
          export STARSHIP_CONFIG=${./config/starship.toml}

          # Start fish if not already in fish
          if [[ -z "$FISH_VERSION" ]]; then
            exec ${pkgs.fish}/bin/fish
          fi
        '';
```

**Step 3: Verify flake still evaluates**

Run: `nix flake check --no-build 2>&1 | head -20`

Expected: No errors

**Step 4: Commit**

```bash
git add nix/cells/devshells/config/starship.toml nix/cells/devshells/default.nix
git commit -m "feat: add minimal starship configuration"
```

---

## Task 5: Create Fish Configuration

**Objective:** Create fish config with abbreviations, starship init, and zoxide init.

**Files:**
- Create: `nix/cells/devshells/config/config.fish`

**Step 1: Write config.fish**

```fish
# hbohlen-systems devShell fish configuration
# This runs when entering the devShell

# Initialize starship prompt
if command -v starship > /dev/null
    starship init fish | source
end

# Initialize zoxide (smart cd)
if command -v zoxide > /dev/null
    zoxide init fish | source
end

# Initialize direnv
if command -v direnv > /dev/null
    direnv hook fish | source
end

# Abbreviations (expand on space, show full command)
# Git abbreviations
abbr -a g git
abbr -a gs 'git status'
abbr -a gd 'git diff'
abbr -a gds 'git diff --staged'
abbr -a ga 'git add'
abbr -a gaa 'git add -A'
abbr -a gc 'git commit'
abbr -a gcm 'git commit -m'
abbr -a gl 'git log --oneline -15'
abbr -a gp 'git push'
abbr -a gpl 'git pull'
abbr -a gco 'git checkout'
abbr -a gb 'git branch'

# Navigation abbreviations
abbr -a l 'eza --icons --group-directories-first'
abbr -a la 'eza -a --icons --group-directories-first'
abbr -a ll 'eza -la --icons --group-directories-first'
abbr -a lt 'eza --tree --icons'
abbr -a z 'z'

# Editor abbreviations
abbr -a n nvim
abbr -a v nvim

# Nix abbreviations
abbr -a ns 'nix develop'
abbr -a nb 'nix build'
abbr -a nr 'nix run'
abbr -a nf 'nix flake'

# Welcome message
echo "Welcome to hbohlen-systems devShell"
echo "Fish shell with starship, zoxide, and abbreviations ready"
echo "Type 'abbr -a' to see all abbreviations"
```

**Step 2: Update devShell to use config.fish**

Modify `nix/cells/devshells/default.nix` shellHook section:

```nix
        shellHook = ''
          echo "Entering hbohlen-systems devShell..."
          export SHELL=${pkgs.fish}/bin/fish

          # Set starship config
          export STARSHIP_CONFIG=${./config/starship.toml}

          # Set fish config directory for this shell
          export XDG_CONFIG_HOME="$PWD/.nix-devshell-config"
          mkdir -p "$XDG_CONFIG_HOME/fish"
          cp ${./config/config.fish} "$XDG_CONFIG_HOME/fish/config.fish"

          # Start fish if not already in fish
          if [[ -z "$FISH_VERSION" ]]; then
            exec ${pkgs.fish}/bin/fish
          fi
        '';
```

**Step 3: Verify flake evaluates**

Run: `nix flake check --no-build 2>&1 | head -20`

Expected: No errors

**Step 4: Commit**

```bash
git add nix/cells/devshells/config/config.fish nix/cells/devshells/default.nix
git commit -m "feat: add fish configuration with abbreviations"
```

---

## Task 6: Create .envrc for Direnv

**Objective:** Create .envrc file for automatic devShell activation with direnv.

**Files:**
- Create: `.envrc`
- Modify: `.gitignore` (to ignore .direnv)

**Step 1: Write .envrc**

```bash
# hbohlen-systems direnv configuration
# Automatically activates nix develop when entering project

use flake
```

**Step 2: Update .gitignore**

If .gitignore doesn't exist, create it. Add:

```
# Direnv
.direnv/

# Fish config generated by devShell
.nix-devshell-config/

# Nix build results
result
result-*
```

**Step 3: Allow direnv (manual step for user)**

Note: After this is committed, the user needs to run:
`direnv allow`

**Step 4: Verify flake evaluates**

Run: `nix flake check --no-build 2>&1 | head -20`

Expected: No errors

**Step 5: Commit**

```bash
git add .envrc .gitignore
git commit -m "feat: add direnv configuration for auto-activation"
```

---

## Task 7: Lock Flake Inputs

**Objective:** Create flake.lock to pin dependencies.

**Files:**
- Create: `flake.lock`

**Step 1: Update flake inputs**

Run: `nix flake update`

Expected: Downloads and pins nixpkgs, flake-parts, llm-agents

**Step 2: Verify flake.lock exists**

Run: `ls -la flake.lock`

Expected: File exists with recent timestamp

**Step 3: Commit**

```bash
git add flake.lock
git commit -m "chore: lock flake inputs"
```

---

## Task 8: Full Integration Test

**Objective:** Verify all success criteria are met.

**Files:**
- None (verification only)

**Step 1: Test nix develop**

Run: `nix develop --command fish -c "echo 'Fish version:' && fish --version"`

Expected: Fish version printed (e.g., "fish, version 3.x.x")

**Step 2: Test packages availability**

Run: `nix develop --command fish -c "which neovim rg eza zoxide direnv pi"`

Expected: All paths printed

**Step 3: Test starship prompt**

Run: `nix develop --command fish -c "starship --version"`

Expected: Starship version printed

**Step 4: Test abbreviations**

Run: `nix develop --command fish -c "abbr -a | head -5"`

Expected: List of abbreviations shown

**Step 5: Test pi**

Run: `nix develop --command fish -c "pi --help 2>&1 | head -5"`

Expected: pi help output shown

**Step 6: Verify git status**

Run: `git status`

Expected: Working tree clean (all changes committed)

---

## Success Criteria Checklist

After all tasks complete, verify:

- [ ] `nix develop` enters a shell with fish as the default
- [ ] `fish` shows starship prompt with git info
- [ ] All packages available: neovim, rg, eza, zoxide, direnv, pi
- [ ] `direnv allow` + entering project auto-activates the shell (user tests manually)
- [ ] `z <partial-path>` jumps to matching directory
- [ ] `abbr -a` shows the defined abbreviations
- [ ] `pi --help` works

---

## Out of Scope (Future Work)

As noted in the spec, these are NOT part of this implementation:

- Home-manager configuration
- System configuration (NixOS)
- Custom pi plugins/extensions
- Hermes skills
- AI workflows
- Dotfiles management
- Other shells (bash, zsh)

---

## Notes for Implementer

1. **First nix develop will be slow** — it downloads and builds packages
2. **If fish doesn't start automatically** — check shellHook logic
3. **If starship config doesn't load** — verify STARSHIP_CONFIG path
4. **If abbreviations don't work** — ensure config.fish is copied to XDG_CONFIG_HOME
5. **Test incrementally** — run `nix flake check` after each task
