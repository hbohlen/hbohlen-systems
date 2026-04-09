# Codebase State and Spec Workflow Diagrams

**Date:** 2026-04-09  
**Purpose:** Visualize the current repository layout and the recommended `.agents/skills/spec` workflow usage.

---

## 1) Current codebase state (high-level)

```mermaid
flowchart TD
    R[hbohlen-systems]

    R --> A[.agents/<br/>Canonical agent workflow artifacts]
    R --> D[docs/<br/>Human-facing documentation]
    R --> O[.opencode/<br/>Adapter commands]
    R --> H[.hermes/<br/>Adapter skills]
    R --> AR[archive/<br/>Archived historical content]
    R --> N[nixos/ hosts/ home/ pkgs/ lib/<br/>System and configuration code]
    R --> S[scripts/ tests/ parts/ tailscale/<br/>Operational/support code]

    A --> A1[skills/spec/<br/>Canonical spec workflow]
    A --> A2[specs/<br/>Feature specs]
    A --> A3[steering/<br/>Project memory]
    A --> A4[templates/ and rules/]

    D --> D1[CONVENTIONS.md and AGENTS.md]
    D --> D2[reports/]
    D --> D3[legacy: plans/, superpowers/, beads/]

    AR --> AR1[openspec/<br/>Archived OpenSpec materials]
```

---

## 2) How to use the spec skills workflow

```mermaid
flowchart TD
    Start([Start feature work]) --> Steering[/steering<br/>refresh project memory]
    Steering --> Init[/spec-init "feature description"/]
    Init --> Req[/spec-requirements feature/]
    Req --> Gap{Need gap check?}
    Gap -- Yes --> GapCmd[/spec-validate-gap feature/]
    Gap -- No --> Design
    GapCmd --> Design[/spec-design feature/]
    Design --> DesignCheck{Need design review?}
    DesignCheck -- Yes --> ValidateDesign[/spec-validate-design feature/]
    DesignCheck -- No --> Tasks
    ValidateDesign --> Tasks[/spec-tasks feature/]
    Tasks --> Implement[/spec-implement feature/]
    Implement --> ImplCheck{Need implementation review?}
    ImplCheck -- Yes --> ValidateImpl[/spec-validate-implementation feature/]
    ImplCheck -- No --> Status
    ValidateImpl --> Status[/spec-status feature/]
    Status --> Done([Done / iterate])
```

---

## 3) Practical usage notes

- Use `.agents/skills/spec/` as the source of truth for spec commands.
- Put feature artifacts in `.agents/specs/<feature>/`.
- Keep durable human-facing documentation in `docs/` and place one-time summaries in `docs/reports/`.
- Keep deprecated/superseded materials in `archive/` for review before deletion.

---

## 4) Module map + where to look first for changes

```mermaid
flowchart LR
    F[flake.nix] --> P[parts/<br/>flake composition]
    F --> L[lib/<br/>core helpers]
    F --> T[tests/unit + tests/evaluation]

    P --> NX[nixos/<br/>system modules]
    P --> HM[home/<br/>home-manager modules]
    P --> HC[hosts/<br/>host entrypoints]
    P --> PK[pkgs/<br/>custom packages]

    NX --> SEC[security, ssh, tailscale]
    NX --> OPS[opencode, caddy, gno]
    HM --> UX[tmux, ssh-client, session-vars]
    HC --> H1[hbohlen-01.nix]
    HC --> H2[hbohlen-01-hardware-configuration.nix]
```

### Change targeting quick guide

- **Host behavior or services** → start in `hosts/` then follow imports into `nixos/`.
- **User shell/session behavior** → `home/`.
- **Shared flake wiring/outputs** → `parts/` and `lib/`.
- **Package-level customizations** → `pkgs/`.
- **Safety checks/regression** → `tests/unit/` and `tests/evaluation/`.

---

## 5) Tooling and access architecture (canonical vs adapters)

```mermaid
flowchart TD
    U[You] --> PI[pi]
    U --> OC[OpenCode]
    U --> HM[Hermes]

    PI --> CAN[.agents/skills/**<br/>Canonical skills]
    OC --> OCA[.opencode/commands/**<br/>Adapter commands]
    HM --> HMA[.hermes/skills/**<br/>Adapter skills]

    OCA --> CAN
    HMA --> CAN

    CAN --> SPEC[spec/*]
    CAN --> DIAG[diagrams/mermaid-diagrams]
    CAN --> DEV[devops/*, nix/*, opnix/*, openspec/*, beads/*]

    SPEC --> SPECS[.agents/specs/**]
    SPEC --> STEER[.agents/steering/**]
```

---

## 6) Command flows for day-to-day work

### Spec-driven feature delivery (recommended default)

```mermaid
flowchart LR
    A[/steering/] --> B[/spec-init/]
    B --> C[/spec-requirements/]
    C --> D[/spec-design/]
    D --> E[/spec-tasks/]
    E --> F[/spec-implement/]
    F --> G[/spec-status/]
```

### OpenSpec lifecycle (for OpenSpec-managed changes)

```mermaid
flowchart LR
    O1[/opsx-propose/] --> O2[/opsx-explore/]
    O2 --> O3[/opsx-apply/]
    O3 --> O4[/opsx-archive/]
```

### Beads loop (task selection and closure)

```mermaid
flowchart LR
    B1[bd ready --json] --> B2[bd update <id> --claim]
    B2 --> B3[Implement + validate]
    B3 --> B4[bd close <id> --reason "..."]
    B4 --> B5[bd sync]
```
