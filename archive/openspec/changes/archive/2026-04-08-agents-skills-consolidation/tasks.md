## 1. Inventory and Baseline

- [x] 1.1 Create `.agents/inventories/migration-map.md` listing every skill in `.opencode/skills/`, `.pi/skills/`, and `backups/hermes-personalization/skills/` with source path, canonical destination path, adapter path(s), and disposition (promote/merge/leave-in-backup)
- [x] 1.2 Audit all 7 `.opencode/skills/*/SKILL.md` files for content and frontmatter, recording current state in the migration map
- [x] 1.3 Audit all 4 `.pi/skills/*/SKILL.md` files, compare against `.opencode` versions, record diffs in migration map
- [x] 1.4 Audit all 22 Hermes skills (8 local + 14 external), categorize each as promote/merge/leave-in-backup per D5, record in migration map
- [ ] 1.5 Verify pi discovers `.agents/skills/` by default by running pi and confirming skills appear
- [ ] 1.6 (Deferred) Verify OpenCode discovers `.opencode/skills/` flat entries and record the discovery pattern

## 2. Scaffold `.agents/` Structure

- [x] 2.1 Create `.agents/AGENTS.md` with repo-level agent instructions pointing to the skill hierarchy and category taxonomy
- [x] 2.2 Create `.agents/skills/` directory with category subdirectories: `devops/`, `nix/`, `opnix/`, `openspec/`, `personal/`
- [x] 2.3 Create `.agents/templates/SKILL-template.md` with canonical frontmatter scaffold and recommended content sections
- [x] 2.4 Create `.agents/standards/` directory (empty for now, reserved for future standards)

## 3. Promote Canonical Skills to `.agents/skills/`

- [x] 3.1 Copy `.opencode/skills/bootstrapping-1password-tokens/SKILL.md` to `.agents/skills/devops/bootstrapping-1password-tokens/SKILL.md` with normalized frontmatter (add `tags`, `category`)
- [x] 3.2 Copy `.opencode/skills/nixos-lockout-safe-deployments/SKILL.md` to `.agents/skills/devops/nixos-lockout-safe-deployments/SKILL.md` with normalized frontmatter
- [x] 3.3 Copy `.opencode/skills/opnix-nixos-integration/SKILL.md` to `.agents/skills/opnix/opnix-nixos-integration/SKILL.md` with normalized frontmatter
- [x] 3.4 Copy `.opencode/skills/openspec-apply-change/SKILL.md` to `.agents/skills/openspec/openspec-apply-change/SKILL.md` with normalized frontmatter
- [x] 3.5 Copy `.opencode/skills/openspec-archive-change/SKILL.md` to `.agents/skills/openspec/openspec-archive-change/SKILL.md` with normalized frontmatter
- [x] 3.6 Copy `.opencode/skills/openspec-explore/SKILL.md` to `.agents/skills/openspec/openspec-explore/SKILL.md` with normalized frontmatter
- [x] 3.7 Copy `.opencode/skills/openspec-propose/SKILL.md` to `.agents/skills/openspec/openspec-propose/SKILL.md` with normalized frontmatter

## 4. Promote Hermes Local Skills

- [x] 4.1 Promote `backups/hermes-personalization/skills/local/nix/nix-flake-devshell/` to `.agents/skills/nix/nix-flake-devshell/` -- copy SKILL.md and templates/, normalize frontmatter
- [x] 4.2 Promote `backups/hermes-personalization/skills/local/nix/nix-dendritic-pattern/` to `.agents/skills/nix/nix-dendritic-pattern/` -- copy SKILL.md and templates/, normalize frontmatter
- [x] 4.3 Promote `backups/hermes-personalization/skills/local/nix/debug-nixos-anywhere-hetzner-boot-failure/` to `.agents/skills/nix/debug-nixos-anywhere-hetzner-boot-failure/` -- copy SKILL.md, normalize frontmatter
- [x] 4.4 Promote `backups/hermes-personalization/skills/local/nix/hetzner-nixos-redeploy-upgrade/` to `.agents/skills/nix/hetzner-nixos-redeploy-upgrade/` -- copy SKILL.md, normalize frontmatter
- [x] 4.5 Promote `backups/hermes-personalization/skills/local/nix/nixos-remote-install/` to `.agents/skills/nix/nixos-remote-install/` -- copy SKILL.md, normalize frontmatter
- [x] 4.6 Promote `backups/hermes-personalization/skills/local/devops/server-hardening-tailscale-safe/` to `.agents/skills/devops/server-hardening-tailscale-safe/` -- copy SKILL.md and templates/, normalize frontmatter, add cross-reference to nixos-lockout-safe-deployments
- [x] 4.7 Promote `backups/hermes-personalization/skills/local/devops/server-security-hardening/` to `.agents/skills/devops/server-security-hardening/` -- copy SKILL.md, normalize frontmatter
- [x] 4.8 Promote `backups/hermes-personalization/skills/local/personal/working-with-adhd-dendritic/` to `.agents/skills/personal/working-with-adhd-dendritic/` -- copy SKILL.md, normalize frontmatter

## 5. Validation

- [ ] 5.1 Verify all 15 canonical SKILL.md files have valid frontmatter (`name` matches directory name, `description` present)
- [ ] 5.2 Verify pi discovers all skills via `.agents/skills/` recursive traversal by running pi
- [ ] 5.3 Confirm `backups/hermes-personalization/` remains untouched as archival (no changes expected)
- [ ] 5.4 Verify skill name uniqueness across all categories (no duplicate `name` fields)

## 6. (Deferred) OpenCode and pi Adapter Layers

These tasks are deferred until OpenCode support is needed:

- [ ] 6.1 Create symlinks in `.opencode/skills/` pointing to canonical `.agents/skills/` locations
- [ ] 6.2 Verify all `.opencode/skills/` symlinks resolve correctly
- [ ] 6.3 Convert `.pi/skills/` to symlinks or remove duplicates once pi discovers `.agents/skills/` natively
- [ ] 6.4 Handle pi's duplicate name warning gracefully (same skill found via both paths)

## 7. (Deferred) Documentation References

- [ ] 7.1 Add comments to `.opencode/command/opsx-*.md` files referencing canonical skill locations
- [ ] 7.2 Add comments to `.pi/prompts/opsx-*.md` files referencing canonical skill locations