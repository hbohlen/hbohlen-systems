# Skills Migration Map

Maps every skill from its original location to its canonical destination in `.agents/skills/`.

## From .opencode/skills/ (7 skills)

| Skill | Canonical Destination | Status |
|-------|----------------------|--------|
| `bootstrapping-1password-tokens` | `.agents/skills/devops/bootstrapping-1password-tokens/` | Promoted with normalized frontmatter |
| `nixos-lockout-safe-deployments` | `.agents/skills/devops/nixos-lockout-safe-deployments/` | Promoted with normalized frontmatter |
| `opnix-nixos-integration` | `.agents/skills/opnix/opnix-nixos-integration/` | Promoted with normalized frontmatter |
| `openspec-apply-change` | `.agents/skills/openspec/openspec-apply-change/` | Promoted with normalized frontmatter |
| `openspec-archive-change` | `.agents/skills/openspec/openspec-archive-change/` | Promoted with normalized frontmatter |
| `openspec-explore` | `.agents/skills/openspec/openspec-explore/` | Promoted with normalized frontmatter |
| `openspec-propose` | `.agents/skills/openspec/openspec-propose/` | Promoted with normalized frontmatter |

## From backups/hermes-personalization/skills/local/ (8 skills)

| Skill | Canonical Destination | Disposition | Status |
|-------|----------------------|-------------|--------|
| `nix-flake-devshell` | `.agents/skills/nix/nix-flake-devshell/` | Promoted (with templates/) | Promoted with normalized frontmatter |
| `nix-dendritic-pattern` | `.agents/skills/nix/nix-dendritic-pattern/` | Promoted (with templates/) | Promoted with normalized frontmatter |
| `debug-nixos-anywhere-hetzner-boot-failure` | `.agents/skills/nix/debug-nixos-anywhere-hetzner-boot-failure/` | Promoted | Promoted with normalized frontmatter |
| `hetzner-nixos-redeploy-upgrade` | `.agents/skills/nix/hetzner-nixos-redeploy-upgrade/` | Promoted | Promoted with normalized frontmatter |
| `nixos-remote-install` | `.agents/skills/nix/nixos-remote-install/` | Promoted | Promoted with normalized frontmatter |
| `server-hardening-tailscale-safe` | `.agents/skills/devops/server-hardening-tailscale-safe/` | Promoted (with templates/) | Promoted with normalized frontmatter |
| `server-security-hardening` | `.agents/skills/devops/server-security-hardening/` | Promoted | Promoted with normalized frontmatter |
| `working-with-adhd-dendritic` | `.agents/skills/personal/working-with-adhd-dendritic/` | Promoted | Promoted with normalized frontmatter |

## From backups/hermes-personalization/skills/external/superpowers/ (14 skills)

These are external skills managed by the `superpowers` npm package. They are NOT promoted to `.agents/skills/`.

| Skill | Source | Disposition |
|-------|--------|-------------|
| brainstorming | npm: superpowers | Left in backup (package-managed) |
| dispatching-parallel-agents | npm: superpowers | Left in backup (package-managed) |
| executing-plans | npm: superpowers | Left in backup (package-managed) |
| finishing-a-development-branch | npm: superpowers | Left in backup (package-managed) |
| receiving-code-review | npm: superpowers | Left in backup (package-managed) |
| requesting-code-review | npm: superpowers | Left in backup (package-managed) |
| subagent-driven-development | npm: superpowers | Left in backup (package-managed) |
| systematic-debugging | npm: superpowers | Left in backup (package-managed) |
| test-driven-development | npm: superpowers | Left in backup (package-managed) |
| using-git-worktrees | npm: superpowers | Left in backup (package-managed) |
| using-superpowers | npm: superpowers | Left in backup (package-managed) |
| verification-before-completion | npm: superpowers | Left in backup (package-managed) |
| writing-plans | npm: superpowers | Left in backup (package-managed) |
| writing-skills | npm: superpowers | Left in backup (package-managed) |

## From .pi/skills/ (4 skills)

These are duplicates of the openspec skills with pi-specific slash-command syntax. They remain in `.pi/skills/` for now as pi will also discover the canonical versions from `.agents/skills/`.

| Skill | Canonical Alternative | Status |
|-------|----------------------|--------|
| `openspec-apply-change` | `.agents/skills/openspec/openspec-apply-change/` | Duplicate remains (pi discovers both) |
| `openspec-archive-change` | `.agents/skills/openspec/openspec-archive-change/` | Duplicate remains (pi discovers both) |
| `openspec-explore` | `.agents/skills/openspec/openspec-explore/` | Duplicate remains (pi discovers both) |
| `openspec-propose` | `.agents/skills/openspec/openspec-propose/` | Duplicate remains (pi discovers both) |

## Adapter Layers (not yet created)

| Tool | Path | Mechanism | Status |
|------|------|-----------|--------|
| OpenCode | `.opencode/skills/` | Symlink adapters (deferred) | Not yet created |
| pi | `.pi/skills/` | Native discovery of `.agents/skills/` + existing `.pi/skills/` | Active |