# Diagrams: Beads & Dolt Skills Implementation

Visual representation of the changes made during this session.

---

## 1. Directory Structure: Before vs After

### BEFORE: Flat reference docs, no skill discovery

```mermaid
graph TD
    A[".agents/skills/beads/"] --> B["core.md (reference)"]
    A --> C["config.md (reference)"]
    A --> D["sync.md (reference)"]
    A --> E["workflows.md (reference)"]
    A --> F["dependencies.md (reference)"]
    A --> G["multi-agent.md (reference)"]
    
    H["docs/beads/"] --> I["beads-knowledge-base.md"]
    H --> J["test-beads.sh"]
    H --> K["test-beads-basic.sh"]
    
    style B fill:#e1f5ff
    style C fill:#e1f5ff
    style D fill:#e1f5ff
    style E fill:#e1f5ff
    style F fill:#e1f5ff
    style G fill:#e1f5ff
    style I fill:#fff3e0
    style J fill:#f3e5f5
    style K fill:#f3e5f5
```

### AFTER: Layered architecture with skill discovery

```mermaid
graph TD
    A[".agents/skills/beads/"] --> S1["beads-workflow/"]
    A --> S2["dolt-operations/"]
    A --> R["Reference Layer<br/>(6 .md files)"]
    
    S1 --> S1F["SKILL.md<br/>(335 lines)"]
    S2 --> S2F["SKILL.md<br/>(476 lines)"]
    
    R --> R1["core.md"]
    R --> R2["config.md"]
    R --> R3["sync.md"]
    R --> R4["workflows.md"]
    R --> R5["dependencies.md"]
    R --> R6["multi-agent.md"]
    
    H["docs/beads/"] --> HN["README.md<br/>(Navigation)"]
    H --> HK["beads-knowledge-base.md"]
    H --> HT["test-*.sh"]
    
    LOG[".agents/changelog/"] --> LOG1["CHANGELOG.md"]
    LOG --> LOG2["2026-04-09-beads-dolt-skills/"]
    LOG2 --> LOG2A["session.md"]
    LOG2 --> LOG2B["changes.md"]
    LOG2 --> LOG2C["diagrams.md"]
    
    style S1F fill:#c8e6c9
    style S2F fill:#c8e6c9
    style R1 fill:#e1f5ff
    style R2 fill:#e1f5ff
    style R3 fill:#e1f5ff
    style R4 fill:#e1f5ff
    style R5 fill:#e1f5ff
    style R6 fill:#e1f5ff
    style HN fill:#fff9c4
    style HK fill:#fff3e0
    style HT fill:#f3e5f5
    style LOG fill:#fce4ec
    style LOG2 fill:#fce4ec
```

---

## 2. Documentation Architecture: Three Layers

```mermaid
graph LR
    A["AGENT LAYER"] -->|discoverable| B["Skills (Procedural)"]
    B -->|point to| C["Reference (Theory)"]
    C -->|support| B
    
    D["HUMAN LAYER"] -->|read| C
    D -->|find| E["Navigation<br/>docs/beads/README.md"]
    E -->|points to| B
    E -->|points to| C
    
    F["TEST LAYER"] -->|verify| B
    G["CONTEXT LAYER"] -->|documents| F
    G -->|archives| H["Changelog"]
    
    subgraph Skills
        B1["beads-workflow<br/>(daily operations)"]
        B2["dolt-operations<br/>(database ops)"]
        B --> B1
        B --> B2
    end
    
    subgraph Reference
        C1["core.md<br/>(issue lifecycle)"]
        C2["config.md<br/>(setup)"]
        C3["sync.md<br/>(data integrity)"]
        C4["workflows.md<br/>(formulas/molecules)"]
        C5["dependencies.md<br/>(ready work)"]
        C6["multi-agent.md<br/>(coordination)"]
        C --> C1
        C --> C2
        C --> C3
        C --> C4
        C --> C5
        C --> C6
    end
    
    style B fill:#c8e6c9
    style C fill:#e1f5ff
    style E fill:#fff9c4
    style H fill:#fce4ec
```

---

## 3. Skill Discovery Flow

How the pi agent framework discovers and uses the new skills:

```mermaid
sequenceDiagram
    participant User as "Hayden"
    participant Pi as "Pi Agent Framework"
    participant Discovery as ".agents/skills/"
    participant Skill1 as "beads-workflow"
    participant Skill2 as "dolt-operations"
    
    User->>Pi: Start session
    Pi->>Discovery: Scan for skills
    Discovery->>Discovery: Find beads-workflow/SKILL.md
    Discovery->>Discovery: Find dolt-operations/SKILL.md
    Discovery-->>Pi: 2 skills discovered
    
    User->>Pi: "I need to work on beads issues"
    Pi->>Skill1: Load beads-workflow skill
    Skill1-->>Pi: Procedural guidance + examples
    Pi-->>User: Available commands with examples
    
    User->>Pi: "I need to query the database"
    Pi->>Skill2: Load dolt-operations skill
    Skill2-->>Pi: Database operations + examples
    Pi-->>User: SQL query templates
    
    User->>User: bd ready --json (from skill 1)
    User->>User: dolt sql -q "SELECT..." (from skill 2)
```

---

## 4. Daily Workflow Process

How agents use beads-workflow during daily operations:

```mermaid
graph TD
    Start["Session Start"] --> Step1["Run: /beads-workflow"]
    Step1 --> Step2["Read: Finding Work section"]
    Step2 --> Step3["Execute: bd ready --json"]
    Step3 --> Step4{"Work found?"}
    
    Step4 -->|Yes| Step5["Read: Work and Update section"]
    Step5 --> Step6["Claim: bd update --claim"]
    Step6 --> Step7["Work on issue"]
    Step7 --> Step8["Update: bd update --label"]
    Step8 --> Step9["Track discoveries: bd create --deps"]
    Step9 --> Step10["Decision point"]
    
    Step10 -->|Still working| Step8
    Step10 -->|Done| Step11["Read: Close and Sync section"]
    Step11 --> Step12["Close: bd close --reason"]
    Step12 --> Step13["CRITICAL: bd sync"]
    Step13 --> End["Session End"]
    
    Step4 -->|No| Step14["Read: Dependency Management"]
    Step14 --> Step15["Check blockers: bd blocked"]
    Step15 --> Step16["Unblock or create new"]
    Step16 --> End
    
    style Start fill:#c8e6c9
    style Step1 fill:#c8e6c9
    style Step13 fill:#ff6b6b
    style End fill:#c8e6c9
```

---

## 5. Database Operations Process

How agents use dolt-operations for database work:

```mermaid
graph TD
    Start["Need database work"] --> Step1["Run: /dolt-operations"]
    Step1 --> Step2{What do you need?}
    
    Step2 -->|Inspect schema| Step3A["Read: Schema Inspection"]
    Step3A --> Step4A["dolt tables"]
    Step4A --> Step5A["dolt describe issues"]
    
    Step2 -->|Query data| Step3B["Read: Querying Issue Data"]
    Step3B --> Step4B["Choose query pattern"]
    Step4B --> Step5B["Execute: dolt sql -q"]
    
    Step2 -->|Fix issues| Step3C["Read: Data Modification"]
    Step3C --> Step4C["Create backup branch"]
    Step4C --> Step5C["dolt sql UPDATE/INSERT"]
    
    Step2 -->|Resolve conflict| Step3D["Read: Conflict Resolution"]
    Step3D --> Step4D["dolt conflicts show"]
    Step4D --> Step5D["dolt conflicts resolve"]
    
    Step2 -->|Migrate data| Step3E["Read: Data Migration"]
    Step3E --> Step4E["Create migration branch"]
    Step4E --> Step5E["Execute migration steps"]
    
    Step5A --> Verify["Verify changes"]
    Step5B --> Verify
    Step5C --> Verify
    Step5D --> Verify
    Step5E --> Verify
    
    Verify --> Commit["dolt add & commit"]
    Commit --> End["Merge to main"]
    
    style Start fill:#e1f5ff
    style Step1 fill:#e1f5ff
    style Verify fill:#fff9c4
    style End fill:#e1f5ff
```

---

## 6. Documentation Navigation Paths

How humans and agents navigate the three layers:

```mermaid
graph TD
    subgraph Entry["Entry Points"]
        EP1["Quick help needed"]
        EP2["Deep understanding"]
        EP3["Agent developing code"]
    end
    
    subgraph Nav1["Path 1: Quick Help"]
        EP1 --> N1A["docs/beads/README.md"]
        N1A --> N1B{Use skills?}
        N1B -->|Yes| N1C["beads-workflow<br/>or<br/>dolt-operations"]
        N1B -->|No| N1D["Reference docs"]
        N1C --> N1E["Get guidance + examples"]
    end
    
    subgraph Nav2["Path 2: Deep Learning"]
        EP2 --> N2A["docs/beads/README.md"]
        N2A --> N2B["beads-knowledge-base.md"]
        N2B --> N2C["Reference layer"]
        N2C --> N2D["Theory + context"]
    end
    
    subgraph Nav3["Path 3: Agent Development"]
        EP3 --> N3A["Pi discovers skills"]
        N3A --> N3B["beads-workflow<br/>or<br/>dolt-operations"]
        N3B --> N3C["Execute procedures"]
        N3C --> N3D["Cross-references<br/>for deeper help"]
        N3D --> N3E["Reference layer"]
    end
    
    style EP1 fill:#c8e6c9
    style EP2 fill:#e1f5ff
    style EP3 fill:#fff9c4
    style N1E fill:#c8e6c9
    style N2D fill:#e1f5ff
    style N3C fill:#fff9c4
```

---

## 7. Integration Points: Skills ↔ Reference

How the two skills connect to each other and to reference material:

```mermaid
graph TB
    subgraph SkillLayer["SKILL LAYER (Procedural)"]
        BW["beads-workflow<br/>Daily operations"]
        DO["dolt-operations<br/>Database ops"]
    end
    
    subgraph RefLayer["REFERENCE LAYER (Theory)"]
        Core["core.md<br/>Issue lifecycle"]
        Config["config.md<br/>Configuration"]
        Sync["sync.md<br/>Sync operations"]
        Workflows["workflows.md<br/>Formulas/Molecules"]
        Deps["dependencies.md<br/>Dependency mgmt"]
        Multi["multi-agent.md<br/>Multi-agent"]
    end
    
    subgraph Archive["ARCHIVE LAYER"]
        KB["beads-knowledge-base.md<br/>Comprehensive guide"]
        Tests["test-*.sh<br/>Test utilities"]
    end
    
    BW -->|When blocked| DO
    DO -->|Session context| BW
    
    BW -->|More info| Core
    BW -->|More info| Deps
    BW -->|More info| Sync
    
    DO -->|Schema details| Config
    DO -->|Data integrity| Sync
    
    Core -->|Deep dive| KB
    Config -->|Deep dive| KB
    Sync -->|Deep dive| KB
    Workflows -->|Deep dive| KB
    Deps -->|Deep dive| KB
    Multi -->|Deep dive| KB
    
    BW -.->|validate| Tests
    DO -.->|validate| Tests
    
    style BW fill:#c8e6c9
    style DO fill:#c8e6c9
    style KB fill:#fff3e0
    style Tests fill:#f3e5f5
```

---

## 8. Changelog System: Session Documentation

How sessions are documented and organized:

```mermaid
graph TD
    A["Session Starts"] --> B["Create session directory"]
    B --> C["2026-04-09-beads-dolt-skills/"]
    
    C --> D1["session.md"]
    C --> D2["changes.md"]
    C --> D3["diagrams.md"]
    
    D1 --> D1A["Overview"]
    D1 --> D1B["Problem Statement"]
    D1 --> D1C["Solution Delivered"]
    D1 --> D1D["Architecture Changes"]
    D1 --> D1E["Design Decisions"]
    D1 --> D1F["Integration Points"]
    D1 --> D1G["Retrospective"]
    
    D2 --> D2A["Files Created"]
    D2 --> D2B["Files Modified"]
    D2 --> D2C["Files Maintained"]
    D2 --> D2D["Rationale"]
    D2 --> D2E["Lessons Learned"]
    
    D3 --> D3A["Directory Structure"]
    D3 --> D3B["Architecture Diagrams"]
    D3 --> D3C["Process Flows"]
    D3 --> D3D["Integration Points"]
    
    E["Master CHANGELOG.md"] --> F["Index of all sessions"]
    F --> G["Session 2026-04-09"]
    G -->|links to| C
    
    style A fill:#fce4ec
    style C fill:#f8bbd0
    style D1 fill:#f3e5f5
    style D2 fill:#f3e5f5
    style D3 fill:#f3e5f5
    style E fill:#fce4ec
    style F fill:#f8bbd0
```

---

## 9. Summary: What Changed

```mermaid
graph LR
    subgraph Before["BEFORE<br/>Flat + No Discovery"]
        B1["6 reference docs<br/>(~23KB)"]
        B2["Knowledge base<br/>(~450 lines)"]
        B3["Test utilities"]
        B4["❌ No SKILL.md"]
        B5["❌ No dolt guidance"]
        B6["❌ No changelog"]
    end
    
    Arrow["➜ Option A<br/>Layered +<br/>Discoverable"]
    
    subgraph After["AFTER<br/>Layered + Discoverable"]
        A1["2 new SKILL.md files<br/>(811 lines)"]
        A2["✅ beads-workflow"]
        A3["✅ dolt-operations"]
        A4["6 reference docs<br/>maintained"]
        A5["Navigation hub"]
        A6["Changelog system"]
    end
    
    Before -->|Transform| Arrow
    Arrow -->|To| After
    
    style B1 fill:#e1f5ff
    style B2 fill:#fff3e0
    style B3 fill:#f3e5f5
    style B4 fill:#ffcccc
    style B5 fill:#ffcccc
    style B6 fill:#ffcccc
    
    style A1 fill:#c8e6c9
    style A2 fill:#c8e6c9
    style A3 fill:#c8e6c9
    style A4 fill:#e1f5ff
    style A5 fill:#fff9c4
    style A6 fill:#fce4ec
```

---

## 10. Impact Matrix: Who Benefits

```mermaid
graph TD
    subgraph Agents["🤖 AI AGENTS"]
        AG1["Discover beads-workflow skill"]
        AG2["Execute: bd ready, update, close, sync"]
        AG3["Discover dolt-operations skill"]
        AG4["Execute: dolt schema, sql, conflicts"]
        AG5["Follow process flows seamlessly"]
    end
    
    subgraph Humans["👤 HUMANS"]
        HU1["Quick reference: docs/beads/README.md"]
        HU2["Deep learning: Reference layer"]
        HU3["Comprehensive guide: Knowledge base"]
        HU4["Test utilities: test-*.sh"]
        HU5["See what changed over time"]
    end
    
    subgraph Project["📋 PROJECT"]
        PR1["Documented decisions in changelog"]
        PR2["Clear separation: skills vs reference"]
        PR3["Fully backward compatible"]
        PR4["Extensible pattern for future sessions"]
        PR5["Visual diagrams for understanding"]
    end
    
    AG1 -.->|Improves| PR1
    HU1 -.->|Improves| PR2
    PR1 -.->|Benefits| Agents
    PR2 -.->|Benefits| Humans
    
    style AG1 fill:#c8e6c9
    style AG2 fill:#c8e6c9
    style AG3 fill:#c8e6c9
    style AG4 fill:#c8e6c9
    style AG5 fill:#c8e6c9
    
    style HU1 fill:#e1f5ff
    style HU2 fill:#e1f5ff
    style HU3 fill:#e1f5ff
    style HU4 fill:#e1f5ff
    style HU5 fill:#e1f5ff
    
    style PR1 fill:#fce4ec
    style PR2 fill:#fce4ec
    style PR3 fill:#fce4ec
    style PR4 fill:#fce4ec
    style PR5 fill:#fce4ec
```

---

## Key Takeaways

From these diagrams, you can see:

1. **Layered architecture** separates concerns (skills, reference, archive)
2. **Skill discovery** is automatic through pi's framework
3. **Navigation is clear** for both agents and humans
4. **Cross-references** create knowledge threads
5. **Changelog system** preserves context and decisions
6. **No breaking changes** — everything is additive
7. **Clear benefits** for agents, humans, and the project

---

**See Also**:
- [Session Summary](./session.md)
- [Detailed Changes](./changes.md)
- [Master Changelog](../CHANGELOG.md)
