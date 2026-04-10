# Session Log and Change History

This directory tracks significant changes, improvements, and experiments across development sessions.

## Purpose

- **For humans**: Understand what changed and why over the project's lifetime
- **For agents**: Reference successful patterns and architectural decisions
- **For decision-making**: Retrospectively review what worked and what didn't

## Structure

Each session is organized as:
```
.agents/changelog/
├── CHANGELOG.md (this file — index and master log)
├── 2026-04-09-beads-dolt-skills/
│   ├── session.md (summary)
│   ├── changes.md (detailed changes)
│   └── diagrams.md (before/after + process flows in Mermaid)
├── 2026-04-XX-another-feature/
│   ├── session.md
│   ├── changes.md
│   └── diagrams.md
└── TEMPLATE.md (template for new sessions)
```

## Session Index

### Latest Sessions

| Date | Feature | Status | Key Changes | Diagrams |
|------|---------|--------|-------------|----------|
| 2026-04-09 | Beads & Dolt Skills | ✅ Complete | 2 new skills, docs reorganized | [View](./2026-04-09-beads-dolt-skills/diagrams.md) |

## How to Add a Session

1. Create a new directory: `.agents/changelog/YYYY-MM-DD-feature-name/`
2. Copy `TEMPLATE.md` to `session.md`, fill it out
3. Create `changes.md` with detailed changes
4. Create `diagrams.md` with Mermaid diagrams
5. Add entry to table above
6. Commit all files to git

## For Agents

When implementing changes:
1. Reference past sessions to understand patterns
2. Look at diagrams to understand architectural decisions
3. Use successful patterns from previous sessions
4. Document your work as a new session at the end

Example agent workflow:
```bash
# At start: Check what's been done
find .agents/changelog -name "diagrams.md" | head -3

# At end: Create new session entry
/spec-init "beads-dolt-skills-enhancement"
# ... document your work in session.md ...
```

---

**Last updated**: 2026-04-09
