## ADDED Requirements

### Requirement: Canonical skill directory structure
The repository SHALL establish `.agents/skills/` as the canonical source of truth for all repo-owned agent skills. Skills SHALL be organized into nested category subdirectories (e.g., `nix/`, `devops/`, `openspec/`, `personal/`, `opnix/`). Each skill SHALL reside in its own directory containing a `SKILL.md` file.

#### Scenario: Skill discovery by pi coding agent
- **WHEN** pi starts in the repository root
- **THEN** pi SHALL discover all skills under `.agents/skills/` via recursive directory traversal, including those nested in category subdirectories

#### Scenario: Skill organization by category
- **WHEN** a new skill `nix-flake-devshell` is created under `.agents/skills/nix/`
- **THEN** the skill directory SHALL be `.agents/skills/nix/nix-flake-devshell/` with `SKILL.md` at its root
- **AND** the `name` field in frontmatter SHALL be `nix-flake-devshell` (matching the directory name, not the full path)

### Requirement: SKILL.md frontmatter schema
Every `SKILL.md` in `.agents/skills/` SHALL conform to the Agent Skills specification. The `name` and `description` fields SHALL be required. Optional fields SHALL include `tags`, `category`, `license`, `compatibility`, `metadata`, `allowed-tools`, and `disable-model-invocation`.

#### Scenario: Valid frontmatter with minimal fields
- **WHEN** a skill `debug-nixos-hetzner` is created with only required fields
- **THEN** the frontmatter SHALL contain `name: debug-nixos-hetzner` and `description:` with a usage-oriented sentence
- **AND** pi SHALL discover and load the skill without warnings

#### Scenario: Valid frontmatter with extended fields
- **WHEN** a skill `nix-flake-devshell` is created with `tags: [nix, flake, devshell]` and `category: nix`
- **THEN** the frontmatter SHALL be valid per the Agent Skills specification (unknown fields are ignored)
- **AND** pi SHALL discover the skill normally

#### Scenario: Name mismatches directory
- **WHEN** a `SKILL.md` has `name: foo` but resides in a directory named `bar`
- **THEN** pi SHALL emit a warning about name mismatch and the skill SHALL still be loadable via `/skill:bar`

### Requirement: Skill companion files
Skills MAY contain companion files in subdirectories (`templates/`, `scripts/`, `references/`, `examples/`). The `SKILL.md` SHALL reference companion files using relative paths from the skill directory root.

#### Scenario: Skill with templates
- **WHEN** skill `nix-flake-devshell` contains `templates/flake.nix`
- **THEN** the SKILL.md SHALL reference it as `[flake.nix template](templates/flake.nix)`
- **AND** the agent SHALL be able to read `templates/flake.nix` relative to the skill directory

### Requirement: Globally unique skill names
Skill names (the `name` field in frontmatter and the parent directory name) SHALL be globally unique across all categories in `.agents/skills/`.

#### Scenario: Name collision across categories
- **WHEN** two skills in different categories both use `name: deploy`
- **THEN** pi SHALL warn and keep only the first discovery
- **AND** the skill SHALL be renamed or reorganized to avoid collision

### Requirement: AGENTS.md repo-level instructions
The `.agents/AGENTS.md` file SHALL exist and provide repo-level agent instructions. It SHALL reference the skill hierarchy and briefly describe the category taxonomy so agents understand where to find skills.

#### Scenario: Agent reads AGENTS.md
- **WHEN** an agent starts in the repository
- **THEN** AGENTS.md SHALL be loaded as context and SHALL contain a reference to `.agents/skills/` as the canonical skill location