# PI Sub-agent System Research

## Executive Summary

pi supports sub-agent dispatch through two primary mechanisms: (1) a built-in `subagent/` extension that spawns isolated pi processes for parallel/chain workflows, and (2) the SDK's `createAgentSession()` API for programmatic multi-agent orchestration. Both enable splitting work across specialized agents with their own context windows, models, and tool sets.

---

## Mechanism 1: Subagent Extension

### Overview

The subagent extension (`examples/extensions/subagent/`) is a ready-made solution for dispatching child agents. It spawns separate `pi` subprocesses with delegated system prompts and configuration.

### Features

| Feature | Description |
|---------|-------------|
| **Isolated context** | Each subagent runs in a separate pi process |
| **Streaming output** | See tool calls and progress in real-time |
| **Parallel execution** | Up to 8 tasks, 4 concurrent |
| **Chain workflows** | Sequential execution with `{previous}` placeholder for context passing |
| **Abort support** | Ctrl+C propagates to kill subagent processes |
| **Usage tracking** | Shows turns, tokens, cost, and context usage per agent |

### Installation

```bash
# Symlink the extension
mkdir -p ~/.pi/agent/extensions/subagent
ln -sf "/path/to/pi-coding-agent/examples/extensions/subagent/index.ts" ~/.pi/agent/extensions/subagent/index.ts
ln -sf "/path/to/pi-coding-agent/examples/extensions/subagent/agents.ts" ~/.pi/agent/extensions/subagent/agents.ts

# Symlink agents
mkdir -p ~/.pi/agent/agents
ln -sf "/path/to/pi-coding-agent/examples/extensions/subagent/agents/scout.md" ~/.pi/agent/agents/scout.md

# Symlink workflow prompts (optional)
mkdir -p ~/.pi/agent/prompts
```

### Agent Definition Format

Agents are markdown files with YAML frontmatter:

```markdown
---
name: my-agent
description: What this agent does
tools: read, grep, find, ls
model: claude-haiku-4-5
---

System prompt for the agent goes here.
```

**Locations:**
- `~/.pi/agent/agents/*.md` - User-level (always loaded)
- `.pi/agent/agents/*.md` - Project-level (requires `agentScope: "both"` or `"project"`)

### Usage Patterns

**Single agent:**
```
Use scout to find all authentication code
```

**Parallel execution:**
```
Run 2 scouts in parallel: one to find models, one to find providers
```

**Chain workflow:**
```
Use a chain: first have scout find the read tool, then have planner suggest improvements
```

**Workflow prompts:**
```
/implement add Redis caching to the session store
/scout-and-plan refactor auth to support OAuth
/implement-and-review add input validation to API endpoints
```

### Security Model

The extension executes separate `pi` subprocesses with delegated prompts. 

- **User-level agents** (`~/.pi/agent/agents/`) are always loaded
- **Project-level agents** (`.pi/agents/`) require explicit enablement via `agentScope: "both"` or `"project"`
- Interactive confirmation prompt before running project-local agents
- Set `confirmProjectAgents: false` to disable prompts

### Tool Parameters

| Mode | Parameter | Description |
|------|-----------|-------------|
| Single | `{ agent, task }` | One agent, one task |
| Parallel | `{ tasks: [...] }` | Multiple agents concurrent (max 8, 4 concurrent) |
| Chain | `{ chain: [...] }` | Sequential with `{previous}` placeholder |

---

## Mechanism 2: SDK-based Sessions

### createAgentSession()

The SDK provides `createAgentSession()` for programmatic agent creation:

```typescript
import { createAgentSession, SessionManager, AuthStorage, ModelRegistry } from "@mariozechner/pi-coding-agent";

const { session } = await createAgentSession({
  sessionManager: SessionManager.inMemory(),
  authStorage: AuthStorage.create(),
  modelRegistry: new ModelRegistry(AuthStorage.create()),
  model: myModel,           // optional
  tools: [readTool, bashTool], // optional, defaults provided
});
```

### Multi-session Coordination

Create multiple sessions for parallel work:

```typescript
const sessions = await Promise.all(
  tasks.map(task => createAgentSession({ ... }))
);

// Subscribe to events
sessions.forEach(session => {
  session.subscribe((event) => {
    // Handle events: message_update, tool_call, etc.
  });
});

// Execute in parallel
await Promise.all(sessions.map(s => s.prompt(task)));
```

### AgentSession API

| Method | Description |
|--------|-------------|
| `prompt(text)` | Send prompt, wait for completion |
| `steer(text)` | Interrupt: delivered after current tool |
| `followUp(text)` | Wait: delivered only when agent finishes |
| `subscribe(listener)` | Subscribe to events (returns unsubscribe) |
| `setModel(model)` | Switch model mid-session |
| `setThinkingLevel(level)` | Adjust thinking level |

### Event Types

- `message_update` - Text deltas, tool calls
- `tool_call` - Tool execution events
- `error` - Error conditions

---

## Alternative Approaches

### Bash Spawn Hook

For command-level parallelism, use the bash tool's `spawnHook`:

```typescript
import { createBashTool } from "@mariozechner/pi-coding-agent";

const bashTool = createBashTool(cwd, {
  spawnHook: ({ command, cwd, env }) => ({
    command: `source ~/.profile\n${command}`,
    cwd: `/mnt/sandbox${cwd}`,
    env: { ...env, CI: "1" },
  }),
});
```

### Git Worktrees

For heavy isolation, use git worktrees (see `using-git-worktrees` skill) to create completely separate working directories.

---

## Best Practices

### Context Management
- Use scout agents to compress context before passing to larger agents
- Chain workflows with `{previous}` placeholder for selective context sharing
- Monitor context token usage (shown in output stats)

### Error Handling
- Subagent extension: Exit code != 0 returns error with stderr
- SDK: `stopReason "error"` propagates LLM errors
- Chain mode stops at first failure

### Security Considerations
- Prefer user-level agents over project-level
- Review agent prompts before enabling project scope
- Subagents inherit parent's tool access

---

## Limitations

- **Subagent extension**: Output truncated to last 10 items in collapsed view
- **Parallel mode**: Limited to 8 tasks, 4 concurrent
- **SDK**: Requires programmatic setup, no built-in UI
- **Context**: Each subagent has independent context (no shared memory)

---

## Recommendations for Workflow Orchestrator

1. **Use subagent extension** for most cases - it's the simplest integration
2. **Use SDK** when you need programmatic control or custom UI
3. **Chain pattern**: scout → planner → worker is ideal for implementation tasks
4. **Parallel pattern**: Use for independent reconnaissance tasks
5. **Custom agents**: Define project-specific agents in `.pi/agents/` for specialized workflows

### Integration Points

- **Beads**: Subagents can report findings back to bead notes
- **OpenSpec**: Use subagents to explore requirements, draft specs
- **jj**: Subagents can work in separate jj worktrees
