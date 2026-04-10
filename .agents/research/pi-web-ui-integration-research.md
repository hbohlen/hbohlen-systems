# Pi Web UI Integration — Research Summary

**Date**: April 9, 2026  
**Status**: Initial Research Complete  
**Next**: Spec Definition

---

## Executive Summary

You want to create a custom web UI integration with **pi** (the minimal terminal coding agent) or **pi-mono** (the monorepo). Research shows three viable architectures:

1. **Native Web Components** (Recommended for custom UX)
   - Use `@mariozechner/pi-web-ui` package from pi-mono
   - Mount custom web components (`AgentInterface`, `ChatPanel`)
   - Full control over layout, branding, and UX
   - IndexedDB storage, artifact rendering, attachments included

2. **RPC Bridge** (Recommended for headless/remote)
   - Run pi as headless subprocess with `--mode rpc`
   - Bridge service (Node/Go/Python) translates WebSocket ↔ RPC JSON
   - Browser client communicates over HTTP/WebSocket
   - Cleanest for deployment, security, and isolation

3. **MCP Integration** (For embedding in other AI clients)
   - Wrap pi as an MCP server
   - Render UI inside Claude, ChatGPT, VS Code, etc.
   - Tool results include interactive UI components
   - Best for cross-client deployment

---

## What is pi-mono?

A **monorepo** containing:

- **`@mariozechner/pi-coding-agent`** — Terminal CLI agent
- **`@mariozechner/pi-agent-core`** — Core agent state machine and LLM loop
- **`@mariozechner/pi-ai`** — Unified LLM API (20+ providers)
- **`@mariozechner/pi-web-ui`** — **Web components library** (web.dev custom elements)
- **`@mariozechner/pi-tui`** — Terminal UI components
- Optional: Slack bot, vLLM integration, etc.

The web UI package is the **key** for custom web interfaces. It's battle-tested and ships with real features.

---

## Architecture Option 1: Native Web Components

### Best for

- Custom branding and full UX control
- Single-page app with your own layout
- Embedded in a larger dashboard or IDE

### How it works

```typescript
import { Agent } from '@mariozechner/pi-agent-core';
import { getModel } from '@mariozechner/pi-ai';
import {
  AppStorage,
  setAppStorage,
  defaultConvertToLlm,
  AgentInterface,
} from '@mariozechner/pi-web-ui';

// Initialize storage
const storage = AppStorage.create();
await storage.init();
setAppStorage(storage);

// Create agent
const agent = new Agent({
  initialState: {
    systemPrompt: 'You are a helpful assistant.',
    model: getModel('anthropic', 'claude-sonnet-4-5'),
    thinkingLevel: 'off',
    messages: [],
    tools: [],
  },
  convertToLlm: defaultConvertToLlm,
});

// Mount custom component
const chat = document.createElement('agent-interface');
chat.session = agent;
chat.enableAttachments = true;
chat.enableModelSelector = true;
document.getElementById('chat-root').appendChild(chat);
```

### Customization hooks

- `onApiKeyRequired` — Custom auth modal
- `onBeforeSend` — Intercept/modify prompts
- `registerMessageRenderer()` — Custom message types
- `registerToolRenderer()` — Custom tool output
- `toolsFactory` — Dynamic tool injection
- `sandboxUrlProvider` — Custom artifact sandboxing

### Included features

- ✅ Real-time streaming chat
- ✅ File attachments with extraction
- ✅ Interactive artifacts (HTML, SVG, Markdown, PDF, XLSX, etc.)
- ✅ IndexedDB session/settings persistence
- ✅ Model and thinking-level selectors
- ✅ Cost tracking
- ✅ Theme toggle

---

## Architecture Option 2: RPC Bridge

### Best for

- Headless deployment (remote server)
- Isolation (sandboxed subprocess)
- Cross-language clients (Python, Go, Rust)

### How it works

```
Browser (WebSocket client)
    ↕ (JSON)
Bridge Service (Node/Go/Python)
    ↕ (stdin/stdout)
Pi Process (--mode rpc)
```

#### Pi side

```bash
pi --mode rpc --no-session --provider anthropic --model claude-sonnet-4-5
```

#### Bridge service (minimal Node example)

```typescript
import { spawn } from 'child_process';
import WebSocket from 'ws';

const pi = spawn('pi', ['--mode', 'rpc']);
const wss = new WebSocket.Server({ port: 8080 });

wss.on('connection', (ws) => {
  pi.stdout.on('data', (data) => {
    // Pipe RPC events to client
    ws.send(data.toString());
  });
  
  ws.on('message', (msg) => {
    // Pipe client commands to pi
    pi.stdin.write(msg + '\n');
  });
});
```

#### RPC command protocol

- `prompt(message, images?)` — Send prompt
- `steer(message)` — Interrupt agent
- `follow_up(message)` — Queue after agent finishes
- `set_model(provider, modelId)` — Switch model
- `get_state()` — Query session state
- `bash(command)` — Execute and capture
- `compact(customInstructions?)` — Compress context
- And 20+ more commands

### Events streamed back

- `message_update` — Streaming text/thinking
- `tool_execution_*` — Tool lifecycle
- `agent_start/end` — Turn boundaries
- `auto_compaction_*` — Context management

---

## Architecture Option 3: MCP Integration

### Best for

- Running inside Claude, ChatGPT, VS Code, or other MCP clients
- Interactive tools that render UI components
- Embedded agents without separate deployment

### Pattern

1. Wrap pi as MCP server
2. Define MCP tools that return UI metadata
3. Browser/client renders tool results as interactive components
4. Tool results can update model context

### Example tool with UI

```typescript
{
  name: "review_diff",
  description: "Review and approve a code diff",
  uiMetadata: {
    type: "form",
    fields: [
      { name: "path", type: "text" },
      { name: "oldCode", type: "textarea" },
      { name: "newCode", type: "textarea" },
    ]
  },
  execute: async (params) => {
    return {
      content: [{ type: "text", text: "Diff reviewed" }],
      ui: { /* rendered in host */ }
    };
  }
}
```

---

## Web UI Package Features

### `@mariozechner/pi-web-ui` Components

| Component | Purpose |
|-----------|---------|
| `ChatPanel` | Batteries-included chat + artifacts + file handling |
| `AgentInterface` | Lower-level for custom layouts |
| `MessageInput` | Composable message composer |
| `AttachmentButton` | File upload with extraction |
| `ModelSelector` | Model/provider picker |
| `ThinkingLevelSelector` | Reasoning level control |
| `SettingsDialog` | Preferences modal |
| `ArtifactsPanel` | Artifact preview/rendering |
| `AppStorage` | IndexedDB wrapper for sessions, settings, keys |

### Storage provided

- Session JSONL files (tree navigation support)
- Settings (global + per-project)
- API keys (IndexedDB encryption)
- Artifact history
- Attachments

---

## Integration Points

### 1. LLM Provider Integration

```typescript
// Any provider from pi-ai
const model = getModel('anthropic', 'claude-sonnet-4-5');
const model = getModel('openai', 'gpt-4o');
const model = getModel('google', 'gemini-2-0-flash');
// Custom providers supported via models.json or registerProvider()
```

### 2. Custom Tools

```typescript
pi.registerTool({
  name: 'my-tool',
  description: 'What it does',
  parameters: Type.Object({ /* schema */ }),
  async execute(id, params, signal, onUpdate, ctx) {
    // Implement tool
    return { content: [...], details: {...} };
  },
  renderCall(args, theme) { /* custom rendering */ },
  renderResult(result, options, theme) { /* custom rendering */ }
});
```

### 3. Custom Extensions (for cli)

```typescript
// ~/.pi/agent/extensions/my-extension.ts
export default function (pi: ExtensionAPI) {
  pi.on('tool_call', async (event, ctx) => {
    // Intercept/block/modify tool calls
  });
  pi.on('message_update', async (event, ctx) => {
    // React to streaming messages
  });
}
```

### 4. Message Rendering

```typescript
pi.registerMessageRenderer('myType', (msg, options, theme) => {
  // Custom render for { role: 'assistant', customType: 'myType', ... }
});
```

### 5. Settings/Preferences

```typescript
const storage = AppStorage.create();
const settings = storage.settings;
settings.set('myApp.theme', 'dark');
settings.set('myApp.apiEndpoint', 'https://...');
await storage.flush();
```

---

## Recommended Starting Architecture

**For you**: Start with **Option 1 (Native Web Components)** because:

1. **Minimal setup** — Just npm install and mount a component
2. **Full control** — Your own layout, branding, features
3. **No deployment complexity** — Runs in the browser (mostly)
4. **Foundation for others** — Can later add RPC bridge or MCP wrapper on top
5. **Real-time collaboration** — IndexedDB storage for offline support

### Tech Stack

- **Framework**: React, Vue, Svelte, or vanilla (your choice)
- **Agent**: `@mariozechner/pi-agent-core` (~10KB gzipped)
- **UI**: `@mariozechner/pi-web-ui` web components
- **LLM**: `@mariozechner/pi-ai` (unified API)
- **Storage**: IndexedDB (built-in to AppStorage)
- **Build**: Vite or esbuild (web components work with any bundler)

---

## Key Decisions to Make

1. **Scope**: Chat-only, or include file browser + terminal + other tools?
2. **Branding**: Fully custom UI, or use ChatPanel + customize?
3. **Deployment**: Single-user dev tool, multi-user SaaS, or embedded?
4. **Auth**: OAuth/API keys only, or team-wide configuration?
5. **Tools**: Use built-in tools (read, bash, write), or register custom ones?
6. **Storage**: Browser IndexedDB, or backend database?
7. **Artifacts**: Preview interactive artifacts, or show as code?

---

## Next Steps

1. **Generate spec** with `/spec-init`
2. **Define requirements** (which integration model, which features, MVP scope)
3. **Design** (component architecture, data flow, deployment model)
4. **Implement** (start minimal: agent + chat UI, iterate)
5. **Deploy** (dev env first, then production scaling)

---

## Useful Links

- **pi-mono repo**: <https://github.com/badlogic/pi-mono>
- **pi-web-ui docs**: <https://pi.dev> (search for "Web UI")
- **pi-agent-core API**: GitHub source in pi-mono
- **Examples**: pi-mono/examples/web-ui/
- **RPC protocol**: pi docs/rpc.md
- **MCP Apps spec**: modelcontextprotocol.io

---

## Open Questions for You

1. What's your primary use case? (dev tool, demo, product feature, research?)
2. Do you want file access / terminal execution, or just chat?
3. Single-user or multi-user?
4. Any specific branding or layout constraints?
5. Deployment target? (localhost, team server, public SaaS, embedded?)

**These will shape the spec and architecture recommendations.**
