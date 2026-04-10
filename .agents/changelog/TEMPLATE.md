# Session Template

Use this template when documenting a new session. Copy it to `session.md` in your new session directory.

---

# Session: [Feature Name]

**Date**: YYYY-MM-DD  
**Agent**: [Agent name or "Manual"]  
**User**: [User name if different from agent]  
**Status**: [✅ Complete | 🚧 In Progress | ❌ Blocked]  
**Scope**: [One-line description of what this session accomplished]

---

## Overview

[1-2 paragraph summary of what was done in this session. Focus on the key achievement.]

## Problem Statement

[What problem did this session solve? What was missing or broken before?]

### Before This Session
- ✅ [What was working]
- ✅ [What existed]
- ❌ [What was missing]
- ❌ [What was broken]

### Impact
- [How many users/agents affected?]
- [What capability was added?]
- [What was improved?]

## Solution Delivered

### New Deliverables

| Item | Location | Type | Size | Purpose |
|------|----------|------|------|---------|
| [Name] | [Path] | [File/Skill/Doc] | [LOC/Size] | [Purpose] |

### Architecture Changes

[If applicable, show before/after structure]

```
BEFORE:
[text structure]

AFTER:
[text structure]
```

## Key Design Decisions

[List 3-5 key decisions made and the reasoning]

1. **Decision Name**: [Explanation of why this choice was made]
2. **Decision Name**: [Reasoning]
3. ...

## Integration Points

| Component | Integration | Example |
|-----------|-------------|---------|
| [Component] | [How it integrates] | [Example usage] |

## Testing

[How was this verified? What tests were run?]

✅ Verified:
- [Test 1]
- [Test 2]
- [Test 3]

## What Can Be Done Now

### New Capabilities

[If this added agent capabilities, list what agents can now do]

- Agents can now [capability 1]
- Agents can now [capability 2]
- Agents can now [capability 3]

### New Constraints

[If this introduced constraints, document them]

- [Constraint 1]: [Explanation]
- [Constraint 2]: [Explanation]

## Metrics

- **New files created**: [Number]
- **Lines of code/docs added**: [Number]
- **Files modified**: [Number]
- **Breaking changes**: [Number]
- **Time to implementation**: [Hours]

## Future Enhancements

[What would be good additions or improvements in the future?]

1. **Idea Name**: [Description]
2. **Idea Name**: [Description]
3. ...

## Files Modified/Created

```
NEW:
  file1
  file2
  directory/
    file3

MODIFIED:
  file4 (reason for modification)

MAINTAINED/UNCHANGED:
  file5 (why it wasn't changed)
```

## Session Retrospective

**What Went Well**
- ✅ [Success 1]
- ✅ [Success 2]
- ✅ [Success 3]

**What Could Be Better**
- [Area for improvement 1]
- [Area for improvement 2]
- [Area for improvement 3]

**Key Learning**
[One or two key things learned in this session that should inform future work]

---

## See Also

- [Diagrams and Flow](./diagrams.md) — Visual representation of changes
- [Detailed Changes](./changes.md) — Line-by-line change documentation
- [Master Changelog](../CHANGELOG.md) — Index of all sessions

---

**Template Last Updated**: 2026-04-09
