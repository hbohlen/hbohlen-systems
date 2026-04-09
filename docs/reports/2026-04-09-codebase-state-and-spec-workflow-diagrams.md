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
