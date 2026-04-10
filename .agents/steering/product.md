# Product Overview

**hbohlen-systems** is a dendritic, declaratively-managed personal infrastructure project. It treats all user-facing systems—servers, workstations, and home environments—as code, enabling reproducible deployments, automated recovery, and version-controlled configuration drift detection.

## Core Capabilities

1. **Multi-host NixOS Management** — Deploy and manage NixOS systems across Hetzner Cloud, local hosts, and dev machines from a single declarative codebase.
2. **Home Manager Integration** — Declarative dotfiles, shell environments, and application configurations synced across all systems.
3. **Security-First Infrastructure** — Automated SSH hardening, firewall, fail2ban, 1Password secret injection, and Tailscale VPN routing.
4. **Reproducible Deployments** — Deterministic Nix builds ensure identical environments across machines; easy rollback and recovery.
5. **Automated Agent Workflows** — Spec-driven development with agents orchestrating deployment specs, testing, and architectural decisions.

## Target Use Cases

- **Infrastructure as Code** — Quickly redeploy or recover any system by replaying declarative configuration.
- **Multi-Environment Consistency** — Keep dev, staging, and production configurations in sync without manual drift.
- **Experimental Deployments** — Test changes safely in isolated Nix builds before pushing to live systems.
- **Heterogeneous Team Setup** — Onboard developers with reproducible shells and environment standards.

## Value Proposition

By treating infrastructure as Nix expressions, hbohlen-systems eliminates manual configuration, reduces incident recovery time, and ensures every system is auditable and versionable. The dendritic architecture naturally supports organic growth and experimentation without forcing rigid module hierarchies.

---
_Updated: April 9, 2026 | Focus: purpose and capability patterns, not exhaustive features_
