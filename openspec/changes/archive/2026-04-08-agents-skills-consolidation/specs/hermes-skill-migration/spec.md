## ADDED Requirements

### Requirement: Hermes skill triage
Each skill in `backups/hermes-personalization/skills/local/` SHALL be evaluated and assigned one of three dispositions: **promote** (migrate to `.agents/skills/`), **merge** (combine with an existing canonical skill), or **leave in backup** (keep archival, do not promote).

#### Scenario: Promote a unique Hermes skill
- **WHEN** a Hermes local skill (e.g., `nix-flake-devshell`) has no overlap with existing canonical skills
- **THEN** it SHALL be promoted to the appropriate `.agents/skills/<category>/` directory with normalized frontmatter

#### Scenario: Merge overlapping Hermes skill
- **WHEN** a Hermes local skill (e.g., `server-hardening-tailscale-safe`) significantly overlaps with an existing canonical skill (e.g., `nixos-lockout-safe-deployments`)
- **THEN** the unique content from the Hermes skill SHALL be incorporated into the canonical skill
- **AND** relevant companion files (e.g., `templates/hardening-checklist.sh`) SHALL be added to the canonical skill's companion files
- **AND** the canonical skill's `description` and content SHALL be updated to cover the merged domain

#### Scenario: Leave in backup
- **WHEN** a Hermes skill is outdated, too context-specific, or not useful for current workflows
- **THEN** it SHALL remain in `backups/hermes-personalization/` without migration

### Requirement: External superpowers skills are not migrated
The 14 external superpowers skills in `backups/hermes-personalization/skills/external/superpowers/` SHALL NOT be promoted to `.agents/skills/`. They are managed by the `superpowers` npm package installed via `opencode.json` and are not repo-owned content.

#### Scenario: External skill not in canonical directory
- **WHEN** `.agents/skills/` is inspected
- **THEN** no superpowers skills (brainstorming, test-driven-development, etc.) SHALL be present
- **AND** these skills SHALL remain discoverable via `.opencode/node_modules/superpowers/skills/`

### Requirement: Frontmatter normalization during migration
When a Hermes skill is promoted or merged, its frontmatter SHALL be normalized to conform to the canonical SKILL.md schema (D3 from design). This includes standardizing `name`, `description`, adding `tags` and `category`, and removing tool-specific fields that don't match the Agent Skills spec.

#### Scenario: Normalized frontmatter for promoted skill
- **WHEN** `nix-flake-devshell` is promoted from Hermes backup
- **THEN** its frontmatter SHALL include `name: nix-flake-devshell`, `description:` (normalized from existing), `tags: [nix, flake, devshell, fish, starship, dendritic]`, and `category: nix`
- **AND** fields not in the Agent Skills spec (e.g., `author`, `version` at the top level) SHALL be moved to `metadata` or removed

### Requirement: Companion files migrate with skills
When a Hermes skill with companion files (e.g., `templates/`, `scripts/`, `references/`) is promoted, all companion files SHALL be migrated along with the SKILL.md to maintain the skill's self-contained structure.

#### Scenario: Skill with templates is promoted
- **WHEN** `nix-flake-devshell` (which has `templates/flake.nix`, `templates/devshell.nix`, etc.) is promoted
- **THEN** the canonical skill directory at `.agents/skills/nix/nix-flake-devshell/` SHALL contain both `SKILL.md` and the `templates/` subdirectory with all files