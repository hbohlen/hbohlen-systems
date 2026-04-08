## Context

This repository uses multiple coding agent tools (OpenCode, pi) and has accumulated skill-like assets in three siloed locations:

1. **`.opencode/skills/`** (7 skills) -- OpenCode-format skills with YAML frontmatter. 4 are openspec workflow skills, 3 are infrastructure skills (1password bootstrapping, opnix integration, NixOS lockout-safe deployments). OpenCode discovers skills only at `.opencode/skills/<name>/SKILL.md` (flat, no categories).

2. **`.pi/skills/`** (4 skills) -- Near-identical copies of the 4 openspec skills, differing only in slash-command syntax (`/opsx:explore` vs `/opsx-explore`). Pi discovers skills from multiple paths including `.agents/skills/` and `.pi/skills/`, with recursive directory traversal.

3. **`backups/hermes-personalization/skills/`** (22 skills) -- An archival export from a Hermes agent, containing 14 external superpowers skills and 8 local skills. Some local skills (nix-flake-devshell, server-hardening-tailscale-safe) overlap with existing `.opencode/skills/` entries. Others are unique.

Additionally, `.opencode/command/` (4 files) and `.pi/prompts/` (4 files) contain simplified invoker wrappers for openspec commands. These are prompt templates, not skills -- they serve a different function and should not be consolidated into `.agents/skills/`.

The pi coding agent natively discovers `.agents/skills/` with recursive directory support, making it a perfect canonical location. OpenCode requires `.opencode/skills/<name>/SKILL.md` (flat structure), necessitating symlink adapters.

Key constraint: the `opencode.json` plugin config installs the `superpowers` package to `.opencode/node_modules/`. These external skills (brainstorming, TDD, systematic-debugging, etc.) are managed by the package manager and should NOT be migrated or duplicated. They are analogous to npm dependencies, not repo-owned content.

## Goals / Non-Goals

**Goals:**

- Establish `.agents/skills/` as the single source of truth for all repo-owned reusable agent skills
- Support nested category directories (e.g., `nix/`, `devops/`, `openspec/`, `personal/`) for progressive disclosure and organization
- Make `.opencode/skills/` and `.pi/skills/` thin symlink adapter layers with zero duplicated content
- Migrate viable Hermes local skills from archival backup into canonical categories
- Define a standard SKILL.md frontmatter schema consistent with the Agent Skills specification (`name`, `description` required; `tags`, `category`, `compatibility`, `license`, `metadata`, `allowed-tools`, `disable-model-invocation` optional)
- Create `.agents/AGENTS.md` as repo-level agent instructions
- Ensure pi can discover all canonical skills natively (no configuration needed)
- Ensure OpenCode can discover all canonical skills via symlinks (no content duplication)
- Support future agent tools without structural changes to `.agents/`

**Non-Goals:**

- Migrating external superpowers skills from `.opencode/node_modules/` or the Hermes backup -- these are package-managed, not repo-owned
- Migrating `.opencode/command/` or `.pi/prompts/` into `.agents/skills/` -- these are prompt templates, not skills
- Building a custom pi extension for skill routing (may revisit later)
- Replacing or modifying the `opencode.json` plugin system
- Changing how openspec commands work (they remain in `.opencode/command/` and `.pi/prompts/`)
- Archiving or deleting `backups/hermes-personalization/` -- it stays as archival reference

## Decisions

### D1: Canonical skill directory and discovery

**Decision:** `.agents/skills/` is the canonical source of truth for all repo-owned skills, organized into nested category subdirectories.

```
.agents/skills/
├── devops/
│   ├── nixos-lockout-safe-deployments/
│   │   └── SKILL.md
│   ├── bootstrapping-1password-tokens/
│   │   └── SKILL.md
│   ├── server-hardening-tailscale-safe/
│   │   ├── SKILL.md
│   │   └── templates/
│   │       └── hardening-checklist.sh
│   └── server-security-hardening/
│       └── SKILL.md
├── nix/
│   ├── nix-flake-devshell/
│   │   ├── SKILL.md
│   │   └── templates/
│   │       ├── flake.nix
│   │       ├── devshell.nix
│   │       ├── starship.toml
│   │       ├── config.fish
│   │       ├── envrc
│   │       └── gitignore
│   ├── nix-dendritic-pattern/
│   │   ├── SKILL.md
│   │   └── templates/
│   │       ├── flake.nix
│   │       └── devshells.nix
│   ├── debug-nixos-anywhere-hetzner-boot-failure/
│   │   └── SKILL.md
│   ├── hetzner-nixos-redeploy-upgrade/
│   │   └── SKILL.md
│   └── nixos-remote-install/
│       └── SKILL.md
├── opnix/
│   └── opnix-nixos-integration/
│       └── SKILL.md
├── openspec/
│   ├── openspec-apply-change/
│   │   └── SKILL.md
│   ├── openspec-archive-change/
│   │   └── SKILL.md
│   ├── openspec-explore/
│   │   └── SKILL.md
│   └── openspec-propose/
│       └── SKILL.md
└── personal/
    └── working-with-adhd-dendritic/
        └── SKILL.md
```

**Rationale:** Pi natively discovers `.agents/skills/` with recursive directory traversal. Categories provide progressive disclosure (agent sees descriptions, loads on demand). The Agent Skills spec requires `name` in frontmatter to match the parent directory name, not the full path, so `nix-flake-devshell` at `.agents/skills/nix/nix-flake-devshell/SKILL.md` is invoked as `/skill:nix-flake-devshell`.

**Alternatives considered:**
- Flat `.agents/skills/` (no categories): rejected because it loses progressive disclosure and makes the directory harder to browse as skill count grows
- Category prefix in skill names (e.g., `nix-nix-flake-devshell`): rejected because it violates the Agent Skills spec naming convention and makes skills less readable
- Separate namespace per tool (e.g., `.agents/skills/opencode/` vs `.agents/skills/pi/`): rejected because the same skill content should serve all tools, with adapters handling format differences

### D2: Tool adapter strategy -- symlinks, not generation

**Decision:** `.opencode/skills/` and `.pi/skills/` become thin symlink layers. Each skill directory is a symlink pointing to its canonical location in `.agents/skills/`.

Example for OpenCode:
```
.opencode/skills/bootstrapping-1password-tokens/SKILL.md
  → ../../.agents/skills/devops/bootstrapping-1password-tokens/SKILL.md
```

Example for pi:
```
.pi/skills/openspec-explore/SKILL.md
  → ../../.agents/skills/openspec/openspec-explore/SKILL.md
```

**Rationale:** Symlinks are zero-maintenance, require no generation scripts, and work on Linux (this repo targets NixOS). The canonical content exists in exactly one place. Editing a canonical skill automatically updates all adapters.

**Alternatives considered:**
- Generation scripts that produce tool-specific wrappers: rejected because it adds a build step, creates divergence, and requires a runner. Not worth the complexity for a personal infra repo.
- Copying content: rejected because it re-introduces the exact duplication problem this change solves.
- pi `settings.json` skills path: pi already discovers `.agents/skills/` natively, so no configuration is needed for pi. `settings.json` is only needed if pointing to non-standard paths. Symlinks in `.pi/skills/` are kept as a backup discovery path for cases where the project root isn't the cwd.

### D3: SKILL.md frontmatter schema

**Decision:** Adopt the Agent Skills specification (https://agentskills.io/specification) as the canonical format, extended with a `tags` field for categorization.

Required fields:
- `name`: kebab-case, matches parent directory name, max 64 chars
- `description`: max 1024 chars, describes what the skill does and when to use it

Optional fields:
- `tags`: array of lowercase strings for search/categorization (e.g., `[nix, flake, devshell]`)
- `category`: string matching the category subdirectory (e.g., `nix`, `devops`, `openspec`)
- `license`: string (e.g., `MIT`)
- `compatibility`: string describing environment requirements
- `metadata`: arbitrary key-value mapping (e.g., `author`, `version`, `generatedBy`)
- `allowed-tools`: space-delimited list of pre-approved tools (experimental)
- `disable-model-invocation`: boolean, when `true` skill is hidden from system prompt

Example canonical frontmatter:
```yaml
---
name: nix-flake-devshell
description: Create a Nix devShell using flake-parts with dendritic cells pattern, fish shell, starship, and common development tools
tags: [nix, flake, devshell, fish, starship, dendritic]
category: nix
author: hbohlen-systems implementation experience
version: 1.0.0
---
```

**Rationale:** The Agent Skills spec is what pi implements. Using it ensures compatibility with pi and any future tool that adopts the standard. The `tags` and `category` fields are added for progressive disclosure and organization within the repo -- they don't conflict with the spec (unknown fields are ignored per the validation docs).

**Alternatives considered:**
- Custom schema: rejected because it would conflict with pi's validation warnings and lack interop
- No frontmatter standardization: rejected because normalizing all skills to a common format eliminates the current fragmentation (3 different frontmatter formats exist today)

### D4: Skill companion files (templates, scripts, references)

**Decision:** Skills may contain companion files in subdirectories (`templates/`, `scripts/`, `references/`, `examples/`). The SKILL.md references these using relative paths. Companion files follow the skill, not the category.

Example:
```
.agents/skills/nix/nix-flake-devshell/
├── SKILL.md
├── templates/
│   ├── flake.nix
│   ├── devshell.nix
│   ├── starship.toml
│   ├── config.fish
│   ├── envrc
│   └── gitignore
└── references/
    └── interop-with-opnix.md
```

The SKILL.md references templates via relative paths: `See the [flake.nix template](templates/flake.nix) for the starting point.`

**Rationale:** The Agent Skills spec explicitly says "Everything else is freeform" beyond SKILL.md. Companion files are a natural extension. Grouping them under the skill (not under a shared `templates/` at the category level) keeps each skill self-contained and portable.

### D5: Hermes backup skill triage

**Decision:** Skills from `backups/hermes-personalization/skills/local/` are evaluated case-by-case. Each skill is either:

1. **Promoted** to `.agents/skills/<category>/` with normalization (frontmatter standardized, content reviewed)
2. **Merged** with an existing skill if the domain overlaps significantly
3. **Left in backup** if it's outdated, too context-specific, or not useful for current workflows

Triage decisions:

| Hermes Skill | Decision | Reason |
|---|---|---|
| `nix-flake-devshell` | **Promote** to `nix/` | Actively useful, has templates |
| `nix-dendritic-pattern` | **Promote** to `nix/` | Actively useful, has templates |
| `server-hardening-tailscale-safe` | **Merge** into existing `nixos-lockout-safe-deployments` | Significant overlap in domain; combine with canonical skill, incorporate checklist template |
| `server-security-hardening` | **Promote** to `devops/` | Complementary to lockout-safe, broader scope |
| `debug-nixos-anywhere-hetzner-boot-failure` | **Promote** to `nix/` | Actively useful for this Hetzner-deployed repo |
| `hetzner-nixos-redeploy-upgrade` | **Promote** to `nix/` | Actively useful for this Hetzner-deployed repo |
| `nixos-remote-install` | **Promote** to `nix/` | Actively useful |
| `working-with-adhd-dendritic` | **Promote** to `personal/` | Personal workflow skill |

External superpowers skills (14 in `backups/hermes-personalization/skills/external/superpowers/`) are NOT promoted -- they are managed by the `superpowers` npm package installed via `opencode.json`.

### D6: `.agents/` top-level structure

**Decision:** The `.agents/` directory serves as the canonical agent configuration hub for this repository.

```
.agents/
├── AGENTS.md              # Repo-level agent instructions, points to skill hierarchy
├── skills/                # Canonical skills (primary content)
│   ├── devops/
│   ├── nix/
│   ├── opnix/
│   ├── openspec/
│   └── personal/
├── standards/             # Shared behavioral standards referenced by skills
│   └── commit-conventions.md
├── templates/             # Skill authoring templates
│   └── SKILL-template.md
└── inventories/           # Migration maps and skill registries
    └── migration-map.md
```

**Rationale:** `AGENTS.md` is loaded by pi (and other agent tools) as context. `standards/` provides shared references that multiple skills can link to. `templates/` provides a scaffold for creating new skills. `inventories/` tracks the migration from old locations (useful during transition, can be archived later).

**Alternatives considered:**
- `.agents/` with only `skills/`: rejected because it doesn't provide a place for AGENTS.md, standards, or templates that are referenced by skills
- `.agents/manifests/` and `.agents/scripts/` and `.agents/adapters/`: rejected as over-engineering for a personal infra repo. Adapter logic lives as symlinks in `.opencode/skills/` and `.pi/skills/`. Scripts that support skills live inside the skill directory. Manifests aren't needed with symlinks.

### D7: Handling openspec command invokers

**Decision:** `.opencode/command/` and `.pi/prompts/` remain in place. They are prompt templates (invocation entry points), not skills. Their content can be simplified to reference the canonical skill location rather than duplicating skill content.

No symlinks needed for these -- they are a different concern (how to invoke a skill via a slash command) than where the skill content lives.

**Rationale:** OpenCode commands are discovered from `.opencode/command/`, not from `.agents/`. Pi prompts are discovered from `.pi/prompts/`. These are invocation UI, not skill content.

### D8: `.gitignore` and version control

**Decision:** Symlinks are committed to git. The `.agents/skills/` directory is fully version-controlled. `.opencode/node_modules/` remains gitignored (managed by package manager).

**Rationale:** Symlinks are the simplest adapter and work reliably on Linux/Git. Git tracks the symlink target, not the linked content, so there's no duplication in the repo.

## Risks / Trade-offs

- **[Symlink portability]** → Symlinks don't work on Windows. Mitigation: this repo targets NixOS/Linux. If Windows support is needed in the future, symlinks can be replaced with a generation script at that point.
- **[OpenCode flat skill discovery]** → OpenCode discovers `.opencode/skills/<name>/SKILL.md` flat (no categories). Symlinks in `.opencode/skills/<name>/` must point to the canonical skill with a flat name, losing category context. Mitigation: the canonical `.agents/skills/` structure preserves categories; only the adapter layer is flat.
- **[Skill name collision]** → If two skills in different categories have the same `name` frontmatter, pi will warn and keep only the first discovery. Mitigation: all skill names must be globally unique across categories. The `category` field in frontmatter is for organization, not namespacing.
- **[Hermes backup skill quality]** → Some Hermes skills may be outdated, reference old patterns, or have incomplete content. Mitigation: each promoted skill is reviewed and normalized during migration, not bulk-copied.
- **[Migration disruption]** → Moving skills changes paths that agents may reference. Mitigation: incremental phased migration with symlinks in place before content moves. Each phase is independently verifiable.
- **[External superpowers skills]** → The superpowers package installs its own skills to `.opencode/node_modules/superpowers/skills/`. These are separate from repo-owned content and must not be affected by this change. Mitigation: `.agents/skills/` only contains repo-owned content; external skills remain managed by their respective package managers.

## Open Questions

- Should `tailscale/acl.hujson` or other config files in the repo root be referenced as companion resources in skills, or should they remain independent? (Leaning toward independent -- skills can reference repo files by path without claiming ownership.)
- Should `.agents/standards/commit-conventions.md` be created now or deferred? (Leaning toward deferred -- create when a standard actually needs to be referenced by multiple skills.)
- Should the `.pi/settings.json` explicitly add `.agents/skills/` as a skill path, or rely on pi's automatic discovery? (Leaning toward relying on automatic discovery since `.agents/skills/` is a native pi path.)
- Should `.opencode/command/` files be updated to include a note like "This command invokes the skill at `.agents/skills/openspec/openspec-explore/`"? (Leaning toward yes -- a small cross-reference aids discoverability without coupling.)