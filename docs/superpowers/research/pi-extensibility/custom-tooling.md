# PI Hooks Design Research

**Research Issue:** hbohlen-systems-62d  
**Status:** Research Complete  
**Source:** [extensions.md](file:///home/hbohlen/.local/share/mise/installs/node/25.7.0/lib/node_modules/@mariozechner/pi-coding-agent/docs/extensions.md) (PI SDK Documentation)

---

## Overview

PI provides a comprehensive event/hook system that allows extensions to intercept and modify behavior at various points in the agent lifecycle. Extensions register handlers using `pi.on(eventName, handler)`.

---

## Event Categories

### 1. Session Events

| Event | When Fired | Can Cancel | Key Use Cases |
|-------|------------|------------|---------------|
| `session_directory` | CLI startup, before session manager created | No | Custom session storage location |
| `session_start` | Initial session load | No | Session initialization, notifications |
| `session_before_switch` | Before `/new` or `/resume` | **Yes** | Confirm before switching |
| `session_switch` | After session switch completes | No | Post-switch cleanup/setup |
| `session_before_fork` | Before `/fork` | **Yes** | Confirm or modify fork behavior |
| `session_fork` | After fork completes | No | Post-fork notifications |
| `session_before_compact` | Before compaction | **Yes** | Custom summarization |
| `session_compact` | After compaction | No | Post-compaction logging |
| `session_before_tree` | Before tree navigation | **Yes** | Custom summaries |
| `session_tree` | After tree navigation | No | Post-navigation tracking |
| `session_shutdown` | On exit (Ctrl+C, Ctrl+D) | No | Cleanup, state save |

### 2. Agent Events

| Event | When Fired | Return Value | Key Use Cases |
|-------|------------|--------------|---------------|
| `before_agent_start` | After user submits, before agent loop | `{ message?, systemPrompt? }` | Inject context, modify system prompt |
| `agent_start` | Once per user prompt | None | Start-of-turn tracking |
| `agent_end` | After agent completes | None | End-of-turn tracking |
| `turn_start` | Each LLM turn | None | Turn-level tracking |
| `turn_end` | After each turn | None | Turn-level cleanup |
| `message_start` | User/assistant/tool message begins | None | Message lifecycle |
| `message_update` | Assistant streaming updates | None | Streaming UI |
| `message_end` | Message completes | None | Message tracking |
| `tool_execution_start` | Before tool runs | None | Tool start logging |
| `tool_execution_update` | During tool execution | None | Progress updates |
| `tool_execution_end` | After tool completes | None | Tool completion |
| `context` | Before each LLM call | `{ messages? }` | Message filtering/injection |
| `before_provider_request` | After payload built, before send | Replace payload | Debugging, payload modification |

### 3. Model Events

| Event | When Fired | Key Use Cases |
|-------|------------|---------------|
| `model_select` | On model change (/model, Ctrl+P, restore) | UI updates, model-specific init |

### 4. Tool Events

| Event | When Fired | Return Value | Key Use Cases |
|-------|------------|--------------|---------------|
| `tool_call` | Before tool executes | `{ block?, reason? }` | Permission gates, input validation |
| `tool_result` | After tool executes | Partial result patch | Result filtering, reformatting |

### 5. Input Events

| Event | When Fired | Return Value | Key Use Cases |
|-------|------------|--------------|---------------|
| `input` | User input received | `{ action: "continue" \| "transform" \| "handled" }` | Input transformation, command routing |

### 6. Bash Events

| Event | When Fired | Key Use Cases |
|-------|------------|---------------|
| `user_bash` | Bash command entered | Interactive bash extensions |

---

## Registration Mechanism

```typescript
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  // Single handler
  pi.on("session_start", async (event, ctx) => {
    ctx.ui.notify("Session started!", "info");
  });

  // With typed event
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "bash" && event.input.command.includes("rm -rf")) {
      return { block: true, reason: "Dangerous command blocked" };
    }
  });
}
```

### Handler Response Patterns

| Event Type | Response | Effect |
|------------|----------|--------|
| Session events (`*_before_*`) | `{ cancel: true }` | Cancel the operation |
| `tool_call` | `{ block: true, reason: "..." }` | Block tool execution |
| `before_agent_start` | `{ message: {...}, systemPrompt: "..." }` | Inject message or modify prompt |
| `input` | `{ action: "continue" \| "transform" \| "handled" }` | Continue, modify, or skip agent |
| `context` | `{ messages: [...] }` | Filter/modify context |
| `tool_result` | `{ content?, details?, isError? }` | Patch result |

---

## Execution Order

### User Prompt Flow

```
1. Extension commands checked first
2. input event fires (can intercept/transform)
3. Skill/template expansion (if not handled)
4. before_agent_start (can inject messages, modify system prompt)
5. agent_start
6. For each turn:
   a. turn_start
   b. context (modify messages)
   c. before_provider_request (debug payload)
   d. LLM call → tool calls
   e. tool_call (can block)
   f. tool_execution_* events
   g. tool_result (can modify)
   h. turn_end
7. agent_end
```

### Session Events Flow

```
/new or /resume:
  session_before_switch → (optional cancel) → session_switch

/fork:
  session_before_fork → (optional cancel) → session_fork

/compact:
  session_before_compact → (optional cancel/modify) → session_compact

/tree:
  session_before_tree → (optional cancel/modify) → session_tree
```

---

## ExtensionContext (ctx)

All event handlers receive `ctx: ExtensionContext` with:

| Property | Type | Description |
|----------|------|-------------|
| `ctx.ui` | object | User interface methods (notify, confirm, select, etc.) |
| `ctx.hasUI` | boolean | Whether UI is available |
| `ctx.cwd` | string | Current working directory |
| `ctx.sessionManager` | SessionManager | Access to session state |
| `ctx.modelRegistry` | object | Model listing and API key access |
| `ctx.model` | object | Current active model |
| `ctx.isIdle()` | function | Check if agent is idle |
| `ctx.abort()` | function | Abort current operation |
| `ctx.shutdown()` | function | Request graceful shutdown |
| `ctx.compact()` | function | Trigger compaction |
| `ctx.getContextUsage()` | function | Current token usage |
| `ctx.getSystemPrompt()` | function | Current system prompt |

---

## Example: Blocking Dangerous Commands

```typescript
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

pi.on("tool_call", async (event, ctx) => {
  if (isToolCallEventType("bash", event)) {
    const { command } = event.input;
    if (command.includes("rm -rf /") || command.includes("> /dev/sda")) {
      return { block: true, reason: "Destructive command blocked" };
    }
  }
});
```

---

## Example: Custom Compaction

```typescript
pi.on("session_before_compact", async (event, ctx) => {
  const { preparation, signal } = event;
  const { messagesToSummarize, tokensBefore } = preparation;

  // Use a different/faster model for summarization
  const model = ctx.modelRegistry.find("google", "gemini-2.5-flash");
  const apiKey = await ctx.modelRegistry.getApiKey(model);

  const summary = await summarize(messagesToSummarize, model, apiKey, signal);

  return {
    compaction: {
      summary,
      firstKeptEntryId: preparation.firstKeptEntryId,
      tokensBefore,
    }
  };
});
```

---

## Key Design Patterns

1. **Before/After Pairs**: Most session events have `before_*` (can cancel) and `*` (post-action) variants
2. **Chaining**: Events like `input`, `tool_result` chain across handlers - each sees the result of previous handlers
3. **Cancellation**: `before_*` events can return `{ cancel: true }` to stop the operation
4. **Transforms**: Input transforms chain; tool results can be partially patched
5. **Typed Events**: Use `isToolCallEventType()` to get type-safe event properties

---

## File Locations

- **Documentation**: `/home/hbohlen/.local/share/mise/installs/node/25.7.0/lib/node_modules/@mariozechner/pi-coding-agent/docs/extensions.md`
- **Examples**: `/home/hbohlen/.local/share/mise/installs/node/25.7.0/lib/node_modules/@mariozechner/pi-coding-agent/examples/extensions/`
  - `custom-compaction.ts` - Full compaction customization
  - `confirm-destructive.ts` - Tool blocking example
  - `bash-spawn-hook.ts` - Bash tool hook
  - `input-transform.ts` - Input transformation

---

## Next Steps for Workflow Orchestrator

Potential hook integrations:
1. `session_before_switch` - Check for pending work before context switch
2. `before_agent_start` - Inject workflow context into prompts
3. `tool_call` - Gate tool access based on workflow state
4. `tool_result` - Capture tool outputs for workflow tracking
5. `session_before_compact` - Preserve workflow state in summaries
6. `session_shutdown` - Save workflow state before exit
