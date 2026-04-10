# pi-nix-suite Extension Design

**Date:** 2025-03-31  
**Status:** Draft (Pending Review)  
**Scope:** Tmux-native subagent visibility, multi-REPL integration, self-improving skill system

---

## Overview

The `pi-nix-suite` extension provides deep Nix/NixOS integration for the `pi` coding agent, enabling:

1. **Visible subagents** - Spawn parallel pi instances in separate tmux windows
2. **Multi-REPL access** - Nix, Python, and Node REPLs in tmux splits
3. **Self-improving skills** - Hybrid pattern detection with user approval

---

## Architecture

### File Structure

```
~/.pi/agent/extensions/pi-nix-suite/
├── index.ts                 # Main extension entry point
├── tmux.ts                  # Tmux window/pane management
├── repl-manager.ts          # REPL lifecycle management
├── skill-generator.ts       # Pattern detection & skill generation
├── commands.ts              # Slash command definitions
└── templates/
    ├── nix-repl.nix         # Nix REPL flake template
    ├── agent-scout.md       # Scout subagent definition
    ├── agent-worker.md      # Worker subagent definition
    ├── agent-nix-expert.md  # Nix-specialized agent
    └── skill-template.md    # Auto-generated skill template
```

### Integration with hbohlen-systems

```
nix/cells/pi-nix-suite/
├── default.nix              # Extension package derivation
├── skills/                  # Version-controlled skills
│   ├── nixos-deploy.md
│   ├── flake-debug.md
│   └── system-upgrade.md
└── config.nix               # Extension configuration
```

---

## Feature Specifications

### 1. Subagent Window Management (/subagent)

**User Interface:**
```
User: /subagent scout the codebase for auth patterns
pi:   Spawning scout in tmux window 1...
      Press Ctrl-B N to view, Ctrl-B P to return
```

**Tmux Window Structure:**
```
[0] pi (main)           <- Main pi session
[1] subagent-scout      <- Scout agent working
[2] subagent-worker     <- Worker agent implementing
```

**Commands:**
| Command | Description |
|---------|-------------|
| `/subagent <task>` | Spawn single agent with auto-selected type |
| `/subagent scout <task>` | Spawn scout agent (fast recon) |
| `/subagent worker <task>` | Spawn worker agent (implementation) |
| `/subagent parallel <n> <task>` | Spawn n agents working in parallel |
| `/subagent chain "scout -> worker" <task>` | Chained agents |
| `/subagent list` | List active subagent windows |
| `/subagent close <n>` | Close specific subagent window |

**Tmux Integration:**
- Uses `$PI_TMUX_SOCKET` (default: `$XDG_RUNTIME_DIR/pi-tmux`)
- Spawns new windows in current tmux session
- Subagent inherits working directory, environment, and model
- Subagents auto-close on completion (configurable)

**Implementation Details:**
```typescript
// tmux.ts core functions
function spawnSubagentWindow(
  name: string,
  task: string,
  agentType: 'scout' | 'worker' | 'custom',
  cwd: string
): Promise<number> // Returns window index

function listSubagentWindows(): WindowInfo[]
function closeSubagentWindow(index: number): void
function attachToSubagent(index: number): void
```

---

### 2. Multi-REPL Integration (/repl)

**User Interface:**
```
User: /repl nix
pi:   Opening Nix REPL in split pane...
      Use Ctrl-B arrow keys to navigate
```

**REPL Types:**

| REPL | Command | Preloaded Context |
|------|---------|-------------------|
| Nix | `/repl nix` | `nix repl .#` with current flake |
| Python | `/repl python` | Python with project deps if available |
| Node | `/repl node` | Node REPL in project directory |

**Tmux Pane Layout:**
```
+----------------+----------------+
|                |   REPL Pane    |
|                |   (25% width)  |
|  Main pi       +----------------+
|  (75% width)   |                |
|                |                |
+----------------+----------------+
```

**Commands:**
| Command | Description |
|---------|-------------|
| `/repl nix` | Open Nix REPL with current flake loaded |
| `/repl python` | Open Python REPL |
| `/repl node` | Open Node.js REPL |
| `/repl close` | Close current REPL pane |
| `/repl close all` | Close all REPL panes |
| `/repl send <code>` | Send code to active REPL |

**Nix REPL Special Features:**
- Preloads current project flake (`nix repl .#`)
- Can import project outputs for testing
- `:load` command available for loading specific nix files
- Provides `pi-test` helper function for quick evals

**Implementation Details:**
```typescript
// repl-manager.ts
type ReplType = 'nix' | 'python' | 'node';

interface ReplSession {
  type: ReplType;
  paneId: string;
  workingDir: string;
  history: string[];
}

function openRepl(type: ReplType, cwd: string): Promise<string> // Returns paneId
function closeRepl(paneId: string): void
function sendToRepl(paneId: string, code: string): void
function getActiveRepls(): ReplSession[]
```

---

### 3. Self-Improving Skill System

**Overview:**
Hybrid approach combining automatic pattern detection with explicit user approval.

**Workflow:**
```
1. Session completes successfully
        ↓
2. Pattern detector analyzes session:
   - Tool sequence patterns
   - File types touched
   - Problem domain classification
   - Success indicators
        ↓
3. Generate skill suggestion:
   - Proposed name
   - Description
   - Confidence score (0.0 - 1.0)
        ↓
4. Prompt user:
   "Create skill 'nix-flake-check' from this session? [Y/n/edit/skip]"
        ↓
5. User responds:
   Y      → Save skill to ~/.pi/agent/skills/auto/<name>.md
   n      → Dismiss, don't ask again for this pattern
   edit   → Open editor to customize skill
   skip   → Skip this time, keep suggesting
        ↓
6. New skill available immediately via /command
```

**Pattern Detection:**
```typescript
interface DetectedPattern {
  name: string;
  description: string;
  toolSequence: string[];
  filePatterns: RegExp[];
  keywords: string[];
  confidence: number;
}

// Example patterns:
// - "nix-flake-check": uses `nix flake check`, touches *.nix files
// - "system-deploy": uses `nixos-rebuild`, touches nixos configs
// - "python-dep-update": modifies requirements.txt, uses pip
```

**Skill File Format:**
```markdown
---
name: nix-flake-check
description: Debug Nix flake evaluation errors
type: auto-generated
source-session: <session-id>
generated: 2025-03-31T10:30:00Z
confidence: 0.92
---

# Nix Flake Check

Use this skill when encountering Nix flake evaluation errors.

## Tools
- read, bash, edit

## Workflow
1. Run `nix flake check` to identify error
2. Read the specific file mentioned in error
3. Check for syntax errors, missing imports
4. Test fix with `nix flake check` again

## Example Invocation
User: "flake check is failing"
→ Run nix flake check, analyze output, fix issues
```

**Commands:**
| Command | Description |
|---------|-------------|
| `/skill-approve` | List pending skill suggestions |
| `/skill-approve <name>` | Approve specific skill |
| `/skill-reject <name>` | Reject specific skill |
| `/skill-edit <name>` | Edit skill before saving |
| `/skill-list` | List all auto-generated skills |
| `/skill-delete <name>` | Delete auto-generated skill |

**Configuration:**
```json
{
  "skillGeneration": {
    "enabled": true,
    "threshold": 0.8,
    "autoSave": false,
    "maxSuggestions": 5,
    "categories": ["nix", "python", "node", "general"]
  }
}
```

---

### 4. Nix-Specific Integration (/nix)

**Command:** `/nix <query>`

**Purpose:** Specialized agent with Nix expertise and REPL access.

**Capabilities:**
- Nix expression evaluation via `nix repl`
- Flake introspection
- System configuration validation
- Derivation debugging
- NixOS module assistance

**Agent Configuration:**
```yaml
name: nix-expert
description: Nix/NixOS specialist with REPL access
tools: read, write, edit, bash, repl-nix
model: claude-sonnet-4
systemPrompt: |
  You are a Nix expert. You have access to a Nix REPL for testing
  expressions. Always verify your changes by evaluating them.
  
  When debugging flakes:
  1. Use repl-nix to test expressions
  2. Check evaluation with nix flake check
  3. Verify builds with nix build (dry-run first)
```

**Custom Tool: repl-nix**
```typescript
{
  name: "repl-nix",
  description: "Evaluate Nix expression in the REPL",
  parameters: {
    expression: string  // Nix expression to evaluate
  },
  // Sends expression to active Nix REPL pane, returns result
}
```

---

## Configuration

### Extension Config File

Location: `~/.pi/agent/extensions/pi-nix-suite/config.json`

```json
{
  "tmux": {
    "socket": "${XDG_RUNTIME_DIR}/pi-tmux",
    "sessionName": "pi-main",
    "windowPrefix": "pi-",
    "autoCloseCompleted": true,
    "defaultLayout": "even-horizontal"
  },
  "repls": {
    "nix": {
      "enabled": true,
      "command": "nix repl .#",
      "initCommands": ["builtins.currentSystem"]
    },
    "python": {
      "enabled": true,
      "command": "python3",
      "detectVenv": true
    },
    "node": {
      "enabled": true,
      "command": "node"
    }
  },
  "skillGeneration": {
    "enabled": true,
    "threshold": 0.8,
    "autoSave": false,
    "maxSuggestionsPerSession": 3,
    "categories": ["nix", "deployment", "python", "node"]
  },
  "agents": {
    "scout": {
      "model": "claude-haiku-4",
      "tools": ["read", "grep", "find", "ls"],
      "maxTokens": 4000
    },
    "worker": {
      "model": "claude-sonnet-4",
      "tools": ["read", "write", "edit", "bash"],
      "maxTokens": 8000
    },
    "nix-expert": {
      "model": "claude-sonnet-4",
      "tools": ["read", "write", "edit", "bash", "repl-nix"],
      "maxTokens": 8000
    }
  }
}
```

### NixOS Integration

```nix
# nix/cells/pi-nix-suite/default.nix
{ inputs, pkgs, ... }:

{
  packages.pi-nix-suite = pkgs.buildNpmPackage {
    pname = "pi-nix-suite";
    version = "0.1.0";
    src = ./extension;
    
    installPhase = ''
      mkdir -p $out/share/pi/extensions/pi-nix-suite
      cp -r dist/* $out/share/pi/extensions/pi-nix-suite/
      
      # Install skills
      mkdir -p $out/share/pi/skills
      cp -r ${./skills}/* $out/share/pi/skills/
    '';
  };
  
  # Home-manager module for automatic setup
  homeManagerModules.pi-nix-suite = { config, ... }: {
    home.file.".pi/agent/extensions/pi-nix-suite".source = 
      "${packages.pi-nix-suite}/share/pi/extensions/pi-nix-suite";
    home.file.".pi/agent/skills/nix-suite".source = 
      "${packages.pi-nix-suite}/share/pi/skills";
  };
}
```

---

## User Workflows

### Workflow 1: Debugging a Nix Flake

```
[main pi] /nix why is my flake check failing?
[nix-expert] Opening Nix REPL and investigating...
[nix-expert] Found the issue: missing `nixpkgs` input in `flake.nix:23`
[nix-expert] Fixed! Test with `nix flake check` to verify.

[main pi] /nix flake check still failing
[nix-expert] Let me check again...

<session completes successfully>

[main pi] 📝 Create skill 'nix-flake-debug' from this session? [Y/n/edit/skip]
[main pi] Y
[main pi] Skill saved! Use /nix-flake-debug in future sessions.
```

### Workflow 2: Parallel Implementation

```
[main pi] /subagent parallel 3 "implement auth for users, posts, and comments"
[pi] Spawning 3 workers in windows 1, 2, 3...

[user presses Ctrl-B 1]
[window 1] worker-1 working on users...

[user presses Ctrl-B 2]
[window 2] worker-2 working on posts...

[user presses Ctrl-B 0]
[main pi] All subagents completed. Merge results?
```

### Workflow 3: REPL-Driven Development

```
[main pi] /repl nix
[pi] Nix REPL opened in right pane

[main pi] I need to test this function
[pi] Use /repl send to send code to the REPL

[main pi] /repl send "myFunction { arg = 42; }"
[REPL] { result = "success"; value = 42; }

[main pi] Great, that works. Now implement it in the flake.
```

---

## Error Handling

### Tmux Errors
- **Socket not found:** Prompt to start tmux or use fallback (inline subagent)
- **Window spawn failed:** Retry with exponential backoff, max 3 attempts
- **Subagent crash:** Capture exit code, show stderr in main pi window

### REPL Errors
- **REPL not installed:** Show installation hint (nix-shell -p nodejs)
- **Flake eval error:** Capture and display in pi conversation
- **Pane focus lost:** Provide `/repl focus` to restore

### Skill Generation Errors
- **Low confidence:** Don't suggest, silently log
- **Duplicate skill:** Prompt to merge/update instead
- **Invalid skill name:** Auto-sanitize, show preview

---

## Security Considerations

1. **Subagent isolation:** Each subagent runs as separate process with inherited env
2. **REPL sandboxing:** Nix REPL has access to current project only
3. **Skill validation:** Generated skills are plain markdown, executable content is user-reviewed
4. **Tmux socket:** Uses user-private socket, no group/world access

---

## Future Enhancements

1. **Wezterm backend:** Alternative to tmux for GUI users
2. **Persistent REPLs:** Save REPL state between sessions
3. **Skill marketplace:** Export/import skills as nix expressions
4. **Collaborative subagents:** Multiple users in same tmux session
5. **Integration with hbohlen-systems:** Auto-detect flake structure, provide context

---

## Success Criteria

- [ ] `/subagent` spawns visible tmux windows
- [ ] `/repl nix` opens Nix REPL with flake preloaded
- [ ] `/repl python` and `/repl node` work for non-Nix projects
- [ ] Skill suggestions appear after successful sessions
- [ ] Skill approval workflow is one-keystroke (Y/n)
- [ ] All features work over SSH in tmux
- [ ] Extension is packaged in hbohlen-systems flake

---

## Open Questions

1. Should subagent windows auto-rename as they progress (show current tool)?
2. Should REPL history persist across pi sessions?
3. Should skill generation look at git diffs to understand what was changed?
4. How should we handle subagents that need user input mid-task?

---

**Next Step:** Review this design, then invoke `writing-plans` skill to create implementation plan.
