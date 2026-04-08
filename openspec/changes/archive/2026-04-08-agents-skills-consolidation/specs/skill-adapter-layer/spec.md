## ADDED Requirements

### Requirement: Symlink adapter layer for OpenCode
Each skill in `.agents/skills/` SHALL have a corresponding symlink in `.opencode/skills/` that points to the canonical skill directory. The symlink SHALL use a relative path so that the skill content resolves correctly.

#### Scenario: OpenCode discovers canonical skill via symlink
- **WHEN** OpenCode scans `.opencode/skills/`
- **THEN** it SHALL find `.opencode/skills/<skill-name>/SKILL.md` as a symlink pointing to the canonical `.agents/skills/<category>/<skill-name>/SKILL.md`
- **AND** the skill content SHALL be identical to the canonical version (no duplication)

#### Scenario: Editing canonical skill updates all adapters
- **WHEN** a user edits `.agents/skills/nix/nix-flake-devshell/SKILL.md`
- **THEN** the content SHALL be immediately available via `.opencode/skills/nix-flake-devshell/SKILL.md` (through the symlink)

### Requirement: Symlink adapter layer for pi
Each skill in `.agents/skills/` SHALL have a corresponding symlink in `.pi/skills/` that points to the canonical skill directory. The symlink SHALL use a relative path.

#### Scenario: Pi discovers canonical skill via symlink
- **WHEN** pi scans `.pi/skills/`
- **THEN** it SHALL find `.pi/skills/<skill-name>/SKILL.md` as a symlink pointing to the canonical `.agents/skills/<category>/<skill-name>/SKILL.md`
- **AND** pi SHALL ALSO discover the skill directly via `.agents/skills/` (native discovery path)
- **AND** there SHALL be no functional difference between the two discovery paths

#### Scenario: Pi dual discovery produces no conflict
- **WHEN** pi discovers `nix-flake-devshell` via both `.agents/skills/nix/nix-flake-devshell/` and `.pi/skills/nix-flake-devshell/`
- **THEN** pi SHALL warn about the duplicate name but keep the first discovery
- **AND** both paths SHALL resolve to the same canonical content

### Requirement: Adapter symlinks use relative paths
All symlinks in `.opencode/skills/` and `.pi/skills/` SHALL use relative paths (e.g., `../../.agents/skills/<category>/<skill-name>/`) so that the repository remains portable and symlinks work across different mount points.

#### Scenario: Symlink portability
- **WHEN** the repository is cloned to a different path
- **THEN** all symlinks SHALL still resolve correctly because they use relative paths

### Requirement: Tool-specific prompt templates remain separate
The `.opencode/command/` and `.pi/prompts/` directories contain prompt template invokers, not skills. These SHALL remain in their tool-specific locations and SHALL NOT be migrated into `.agents/skills/`. They MAY be updated to reference the canonical skill location for cross-reference.

#### Scenario: OpenCode command invoker references canonical skill
- **WHEN** `.opencode/command/opsx-explore.md` is read
- **THEN** it SHALL remain at its current path as a prompt template
- **AND** it MAY contain a comment referencing `.agents/skills/openspec/openspec-explore/`

### Requirement: Symlink creation validation
After creating symlinks, a validation step SHALL verify that each symlink resolves to an existing canonical SKILL.md file. Broken symlinks SHALL be treated as errors and MUST be fixed before the migration phase is considered complete.

#### Scenario: Verification script checks symlinks
- **WHEN** the migration script runs
- **THEN** it SHALL iterate all symlinks in `.opencode/skills/` and `.pi/skills/` and verify each resolves to a readable `SKILL.md`
- **AND** it SHALL report any broken symlinks as errors