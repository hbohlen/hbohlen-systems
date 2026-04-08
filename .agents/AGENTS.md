# Agent Instructions

This repository uses `.agents/skills/` as the canonical source of agent skills. Skills are organized into category subdirectories for progressive disclosure.

## Skill Categories

| Category | Path | Purpose |
|----------|------|---------|
| `devops` | `.agents/skills/devops/` | Server hardening, deployment safety, infrastructure operations |
| `nix` | `.agents/skills/nix/` | NixOS, Nix flakes, devshells, remote installs |
| `opnix` | `.agents/skills/opnix/` | 1Password secret injection into NixOS/Home Manager |
| `openspec` | `.agents/skills/openspec/` | OpenSpec workflow (propose, explore, apply, archive) |
| `personal` | `.agents/skills/personal/` | Personal workflow and productivity skills |

## Adding a Skill

1. Create a directory under the appropriate category: `.agents/skills/<category>/<skill-name>/`
2. Create `SKILL.md` with required frontmatter (`name`, `description`) and optional fields (`tags`, `category`, `license`, `compatibility`, `metadata`)
3. Add companion files as needed: `templates/`, `scripts/`, `references/`, `examples/`
4. The `name` field must match the directory name (e.g., `nix-flake-devshell`)
5. Reference companion files from SKILL.md using relative paths

## Tool Compatibility

- **pi**: Discovers `.agents/skills/` natively via recursive directory traversal
- **OpenCode**: Uses `.opencode/skills/` (adapter layer, to be configured separately)