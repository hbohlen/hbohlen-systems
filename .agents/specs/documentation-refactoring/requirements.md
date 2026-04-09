# Requirements Document

## Introduction

The `hbohlen-systems` repository has accumulated documentation across multiple overlapping systems:
`docs/plans/`, `docs/superpowers/plans/`, `docs/superpowers/specs/`, `docs/superpowers/references/`,
`openspec/changes/`, `openspec/changes/archive/`, `openspec/specs/`, `lib/README.md`, `pkgs/README.md`,
`secrets/README.md`, `.agents/inventories/`, and `.kiro/`. This documentation has grown organically and
now exhibits redundancy, inconsistent naming conventions (date-prefixed filenames mixed with
slug-based), unclear ownership between legacy and current workflows, and no discoverable entry point
for new contributors or AI agents.

This refactoring aims to consolidate, normalize, and logically organize all project documentation so
that it is readable, navigable, consistently structured, and maintainable over time. The scope
includes structural reorganization, naming-convention standardization, stub-module README population,
and establishing a lightweight governance model to prevent future drift.

---

## Requirements

### Requirement 1: Documentation Inventory and Audit

**Objective:** As a maintainer, I want a complete, current inventory of all documentation files in
the repository, so that I can identify gaps, redundancy, and misclassification before reorganization
begins.

#### Acceptance Criteria

1. The Documentation system shall produce an inventory listing every `.md` file in the repository
   (excluding `.git/` and `node_modules/`) with its current path, inferred category, and a
   recommended target location.
2. When a document is discovered whose purpose cannot be clearly inferred from its filename or
   content, the Documentation system shall flag it as requiring manual classification.
3. The Documentation system shall identify all date-prefixed filenames (matching the pattern
   `YYYY-MM-DD-*`) and list them as candidates for normalization.
4. If two or more documents are found to cover the same subject with substantially overlapping
   content, the Documentation system shall flag them as duplication candidates.
5. The Documentation system shall differentiate between _active_ documents (referenced by current
   workflows or specs) and _archive_ documents (completed work or superseded content).

---

### Requirement 2: Structural Reorganization

**Objective:** As a developer or AI agent, I want a clear, predictable directory structure for all
project documentation, so that I can locate relevant documents without ambiguity.

#### Acceptance Criteria

1. The Documentation system shall organize human-facing project documentation under a single top-level
   `docs/` directory with clearly named subdirectories reflecting document type.
2. The `docs/` hierarchy shall separate documents by type: architecture decisions, implementation
   plans, runbooks/references, and changelogs/release notes.
3. When documents currently exist under `docs/plans/` or `docs/superpowers/plans/`, the Documentation
   system shall consolidate them into a single canonical location and remove the parallel structure.
4. When documents currently exist under `docs/superpowers/specs/` or `docs/superpowers/references/`,
   the Documentation system shall relocate or link them into the canonical hierarchy.
5. The `openspec/` directory shall remain structurally intact for active changes, but completed
   changes in `openspec/changes/archive/` shall be summarized or linked rather than preserved
   verbatim in the primary tree.
6. The `.kiro/` and `.agents/` directories shall not be modified by this refactoring; they are
   governed by their own skill-based workflows.

---

### Requirement 3: Naming Convention Standardization

**Objective:** As a maintainer, I want all documentation filenames to follow a consistent, predictable
convention, so that sorting and discovery by both humans and automated tools is reliable.

#### Acceptance Criteria

1. The Documentation system shall normalize filename conventions such that slug-based names
   (`feature-design.md`) are the primary pattern for persistent reference documents.
2. When a date-prefix is semantically meaningful (e.g., changelogs, release notes, time-anchored
   plans), the Documentation system shall retain the `YYYY-MM-DD-` prefix; in all other cases it
   shall be removed.
3. The Documentation system shall ensure all filenames consist only of lowercase letters, numerals,
   and hyphens (no underscores, spaces, or mixed case).
4. If a rename operation would cause a broken internal link within any other document, the
   Documentation system shall update the referencing document before completing the rename.
5. The Documentation system shall document the finalized naming convention in a `docs/CONVENTIONS.md`
   file so that it is discoverable by future contributors and agents.

---

### Requirement 4: Stub-Module README Population

**Objective:** As a developer, I want every top-level module directory to have a meaningful `README.md`,
so that the purpose and usage of each module is immediately clear without reading source code.

#### Acceptance Criteria

1. The Documentation system shall identify all top-level directories that contain functional Nix or
   configuration code but whose `README.md` contains only a placeholder stub (e.g., `lib/`, `pkgs/`,
   `secrets/`).
2. When a stub README is found, the Documentation system shall replace it with a document that
   describes the directory's purpose, its contents, and how it relates to other modules.
3. The Documentation system shall ensure every populated README includes at minimum: a one-sentence
   purpose statement, a description of the directory's contents, and any relevant usage or
   contribution notes.
4. If a module's source files are self-documenting (via inline comments or attribute descriptions),
   the README shall reference those inline sources rather than duplicating their content.
5. The Documentation system shall not generate README content for directories that are intentionally
   tool-managed (e.g., `node_modules/`, `.direnv/`) or whose contents are entirely secret/sensitive.

---

### Requirement 5: Navigation and Discoverability

**Objective:** As a new contributor or AI agent onboarding to the project, I want a single entry
point that provides an overview of the entire project and guides me to the right documentation, so
that I can orient myself quickly without reading every file.

#### Acceptance Criteria

1. The Documentation system shall ensure that a root-level `README.md` (or equivalent entry point)
   provides a high-level overview of the repository's purpose, structure, and key workflows.
2. The root entry point shall link to each major documentation category and each top-level functional
   module.
3. When a new top-level directory is added to the repository, the root entry point shall be updated
   to include it.
4. The Documentation system shall ensure that `docs/CONVENTIONS.md` is explicitly linked from the
   root entry point so that naming and organizational conventions are immediately discoverable.
5. The Documentation system shall ensure that active AI-agent entry points (`.agents/AGENTS.md`,
   `AGENTS.md`) remain accurate and reference the canonical skills and spec directories.

---

### Requirement 6: Maintenance Governance

**Objective:** As a maintainer, I want a lightweight, documented process for keeping documentation
current as the project evolves, so that the refactoring benefits are not eroded over time.

#### Acceptance Criteria

1. The `docs/CONVENTIONS.md` shall define the canonical directory structure, naming rules, and the
   process for adding new documentation.
2. When a new feature spec is completed under `.kiro/specs/`, the governance process shall specify
   which artifacts (if any) are promoted to the `docs/` hierarchy and in what form.
3. The Documentation system shall define ownership boundaries: `.kiro/` docs are managed by
   kiro-spec skills; `openspec/` docs are managed by openspec skills; all other docs under `docs/`
   are maintained directly.
4. If any document in `docs/` has not been modified in more than 90 days and is not classified as a
   reference or archive document, the governance process shall flag it for review.
5. The Documentation system shall specify whether `docs/` is intended to be AI-readable (i.e.,
   ingested by agents as steering context) or human-only, and mark files accordingly.

---

## Triage Table

### `docs/plans/`
| File | Classification | Proposed Target Path | Reason |
| --- | --- | --- | --- |
| `2025-03-30-dendritic-devshell-implementation.md` | `keep-archive` | `docs/plans/archive/` | Historical implementation details |
| `2026-03-30-hetzner-nixos-deployment-v2-implementation-plan.md` | `keep-active` | `docs/plans/active/hetzner-nixos-deployment-v2.md` | Current server deployment plan |

### `docs/superpowers/plans/`
| File | Classification | Proposed Target Path | Reason |
| --- | --- | --- | --- |
| `2025-03-30-hetzner-nixos-deployment-plan.md` | `discard` | None | Superseded by v2 plan |
| `2025-03-31-hetzner-server-hardening-implementation.md` | `keep-archive` | `docs/plans/archive/` | Historical hardening record |
| `2025-03-31-pi-nix-suite-implementation.md` | `discard` | None | Package removed |
| `2025-04-01-oh-my-pi-web-implementation.md` | `discard` | None | Superseded/Obsolete |
| `2026-03-31-opencode-tailscale-web-implementation.md` | `keep-archive` | `docs/plans/archive/` | Implemented feature |
| `2026-03-31-opnix-tailscale-bootstrap-implementation.md` | `keep-archive` | `docs/plans/archive/` | Done setup |
| `2026-04-01-gno-tailscale-plan.md` | `keep-archive` | `docs/plans/archive/` | Completed |
| `2026-04-08-mnemosyne-web-ui-phase1-implementation.md` | `keep-active` | `docs/plans/active/mnemosyne-web-ui-phase1.md` | Currently active project |

### `docs/superpowers/specs/`
| File | Classification | Proposed Target Path | Reason |
| --- | --- | --- | --- |
| `2025-03-30-dendritic-devshell-design.md` | `keep-archive` | `docs/architecture/decisions/` | ADR-like historical design |
| `2025-03-30-hetzner-nixos-deployment-design.md` | `discard` | None | Superseded by v2 |
| `2025-03-31-hetzner-server-hardening-design.md` | `keep-archive` | `docs/architecture/decisions/` | Security architecture record |
| `2025-03-31-pi-nix-suite-design.md` | `discard` | None | Package removed |
| `2025-04-01-oh-my-pi-web-frontend-design.md` | `discard` | None | Superseded |
| `2026-03-30-hetzner-nixos-deployment-v2-design.md` | `keep-active` | `docs/architecture/decisions/hetzner-nixos-deployment-v2.md` | Current architecture |
| `2026-03-31-opencode-tailscale-web-design.md` | `keep-archive` | `docs/architecture/decisions/` | Past design |
| `2026-03-31-opnix-tailscale-bootstrap-design.md` | `keep-archive` | `docs/architecture/decisions/` | Past design |
| `2026-04-01-dendritic-refactor-design.md` | `keep-archive` | `docs/architecture/decisions/` | Past design |
| `2026-04-01-gno-tailscale-design.md` | `keep-archive` | `docs/architecture/decisions/` | Past design |
| `2026-04-08-mnemosyne-web-ui-phase1-design.md` | `keep-active` | `docs/architecture/decisions/mnemosyne-web-ui-phase1.md` | Current project architecture |

### `docs/superpowers/references/`
| File | Classification | Proposed Target Path | Reason |
| --- | --- | --- | --- |
| `2026-03-31-hetzner-redeploy-upgrade-runbook.md` | `keep-active` | `docs/runbooks/hetzner-redeploy-upgrade.md` | Operational runbook |

### `openspec/changes/archive/`
*Note: These directories remain in place under openspec ownership.*
| Directory | Classification | Proposed Target Path | Reason |
| --- | --- | --- | --- |
| `2026-04-01-fix-devshell-and-gno-serve/` | `keep-archive` | No move | Maintained by openspec skills |
| `2026-04-03-resolve-custom-domains-over-tailscale/` | `keep-archive` | No move | Maintained by openspec skills |
| `2026-04-06-run-opencode-web-as-user/` | `keep-archive` | No move | Maintained by openspec skills |
| `2026-04-06-tmux-agent-menu/` | `keep-archive` | No move | Maintained by openspec skills |
| `2026-04-08-agents-skills-consolidation/` | `keep-archive` | No move | Maintained by openspec skills |

