## Why

Skill-like assets are scattered across `.opencode/skills/`, `.pi/skills/`, and `backups/hermes-personalization/skills/`, with no single source of truth. The same openspec skills are duplicated across two tool directories with cosmetic syntax differences (`/opsx-explore` vs `/opsx:explore`). The Hermes backup contains local skills that are only accessible as archival data, not as usable agent skills. Tool-specific directories (`.opencode/`, `.pi/`) currently serve as both the canonical skill store and the tool adapter layer, conflating two different concerns. As the number of skills grows and more agent tools are adopted, this fragmentation makes it unclear where to edit, what's canonical, and how to ensure consistency.

Consolidating under `.agents/skills/` creates a single authoritative location that pi already discovers natively (recursive discovery at any depth), while tool-specific directories become thin adapters.

## What Changes

- Establish `.agents/skills/` as the canonical, repo-owned, editable source for all reusable skills, organized into nested category directories (e.g., `.agents/skills/nix/`, `.agents/skills/devops/`, `.agents/skills/openspec/`)
- Convert `.opencode/skills/` to a thin symlink adapter layer pointing back to `.agents/skills/` (one symlink per skill)
- Convert `.pi/skills/` to a thin symlink adapter layer pointing back to `.agents/skills/` (one symlink per skill)
- Migrate viable Hermes local skills from `backups/hermes-personalization/skills/local/` into `.agents/skills/` appropriate categories
- Keep `backups/hermes-personalization/` as archival -- it is NOT a canonical skill source
- Define a canonical `SKILL.md` frontmatter schema (based on the Agent Skills specification) that all skills follow
- Normalize all 7 existing `.opencode/skills/` and 4 `.pi/skills/` entries into `.agents/skills/` canonical locations
- Create `.agents/AGENTS.md` as the repo-level agent instruction file pointing to the skill hierarchy
- Create `.agents/templates/` for reusable skill templates (e.g., `SKILL-template.md`)
- Create `.agents/standards/` for agent behavior standards referenced by skills
- Handle `.opencode/command/` and `.pi/prompts/` as tool-specific invokers that are NOT migrated into `.agents/skills/` (they are prompt templates, not skills)

## Capabilities

### New Capabilities
- `canonical-skill-layout`: Defines the `.agents/` directory tree, skill category taxonomy, canonical `SKILL.md` frontmatter schema, required vs optional companion files, and naming conventions
- `skill-adapter-layer`: Defines how `.opencode/skills/` and `.pi/skills/` become thin symlink adapters pointing to `.agents/skills/`, preserving tool-specific discovery while eliminating content duplication
- `hermes-skill-migration`: Defines the triage process for migrating Hermes local skills from archival backup into canonical `.agents/skills/` categories, including deduplication, normalization, and archival decisions
- `skill-standards`: Defines the `.agents/standards/` and `.agents/templates/` directories for shared agent behavior standards and skill authoring templates

### Modified Capabilities
_(No existing specs are modified -- this is a new capability set)_

## Impact

- All 11 existing skill directories (7 in `.opencode/skills/`, 4 in `.pi/skills/`) will have their content moved to `.agents/skills/` and replaced with symlinks
- 8 Hermes local skills will be evaluated for migration; some will merge with existing skills (e.g., `server-hardening-tailscale-safe` overlaps with `nixos-lockout-safe-deployments`), others will be promoted as new canonical skills
- `.opencode/command/` and `.pi/prompts/` remain in place (they are prompt templates, not skills) but may be updated to reference canonical skill locations
- `.agents/AGENTS.md` is new and will be loaded by pi and potentially other agent tools
- The `opencode.json` plugin config (`superpowers`) continues to install external skills to `.opencode/node_modules/` -- these are NOT migrated (they are managed by the package manager)
- `.pi/settings.json` may be created or updated to explicitly include `.agents/skills/` as a skill path