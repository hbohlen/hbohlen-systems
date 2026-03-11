## Context

The hbohlen-systems project is building a **Workflow Orchestrator** that combines:
- **beads** - Git-backed issue tracking with dependencies
- **OpenSpec** - Spec-driven development methodology
- **jj** - Jujutsu VCS (git-compatible, immutable history)
- **pi** - AI coding agent

Currently, the project uses plain git. We need to integrate jj while maintaining git interoperability for team collaboration.

## Goals / Non-Goals

**Goals:**
- Integrate jj as the primary VCS layer
- Enable jj-git interoperability (push/pull between jj and git remotes)
- Create workflows for session-based development using jj
- Track jj operations in beads for audit and resume
- Enable pi to leverage jj worktrees for isolation

**Non-Goals:**
- Migrating existing git history (use jj import-git instead)
- Full jj CLI mastery (focus on workflow-relevant commands)
- Multi-VCS support beyond jj+git

## Decisions

### 1. jj over Git CLI
**Decision**: Use jj as the primary interface, with git as remote storage only.

**Rationale**: jj provides:
- Undo capability (`jj undo`) - critical for AI agent experimentation
- Better conflict resolution with `@` moves
- Immutable history - safer for AI-assisted work
- Clean divergence view

**Alternatives considered**:
- Using git directly with pi hooks - loses jj's unique benefits
- Using git worktrees - less flexible than jj's repo model

### 2. jj-git Interoperability Strategy
**Decision**: Use `jj git push` and `jj git pull` for remote sync, keeping git as the protocol layer.

**Rationale**: 
- Team members can use either jj or git
- GitHub/GitLab remotes work unchanged
- jj's smart commits integrate well with PR workflows

**Alternatives considered**:
- Pure jj with jj-server - adds infrastructure complexity
- Git-only with jj as local cache - loses jj's commit model

### 3. Beads Integration Approach
**Decision**: Track jj operation outcomes (commit IDs, change IDs) in bead metadata, not automatic syncing.

**Rationale**:
- Beads provides issue tracking, not VCS
- Linking bead to jj change ID enables cross-referencing
- User controls when to sync (manual or auto via hooks)

### 4. Session Isolation with jj
**Decision**: Use jj's bookmark-based sessions, not separate worktrees for each session.

**Rationale**:
- Bookmarks are lightweight
- Easy to switch with `jj bookmark <name>`
- Works with `jj describe` for session naming

**Alternatives considered**:
- jj worktrees - heavier, better for true isolation
- Git branches - jj bookmarks are essentially branches with better UX

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|------------|
| Team resistance to jj | Adoption friction | Document git interoperability, gradual rollout |
| jj bugs in edge cases | Lost work | Use `jj git clone` for backup, frequent git pushes |
| Learning curve | Productivity dip | Create jj quick-reference, alias common commands |
| pi hooks may need jj CLI | Integration gap | Research pi hooks system, create wrapper if needed |

## Open Questions

1. **Should we auto-sync jj → git on session end?** Need to test hooks integration
2. **How to handle jj conflict markers in pi?** May need custom tool handling
3. **Beads sync with jj log?** Could parse `jj log` for bead-linked changes
