# Mnemosyne Web UI - Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a simple web-based chat interface for Mnemosyne that reads authentication from local pi config (`~/.pi/agent/`) and provides model selection based on configured providers.

**Architecture:** Simple Node.js server with Hono that serves a minimal HTML chat UI and proxies LLM calls using `@mariozechner/pi-ai`. Config read from existing pi auth.json and settings.json files.

**Tech Stack:** Node.js, Hono, @mariozechner/pi-ai, plain HTML/CSS/JS

---

## File Structure

```
mnemosyne-web/
├── src/
│   ├── index.ts          # Server entry point
│   ├── config/
│   │   ├── auth.ts       # Load pi auth.json
│   │   └── settings.ts   # Load pi settings.json
│   ├── api/
│   │   └── chat.ts       # Chat endpoint
│   └── ui/
│       ├── index.html    # Chat UI
│       └── style.css     # Styles
├── package.json
└── tsconfig.json
```

---

### Task 1: Project Setup

**Files:**
- Create: `mnemosyne-web/package.json`
- Create: `mnemosyne-web/tsconfig.json`

- [ ] **Step 1: Create package.json**

```json
{
  "name": "mnemosyne-web",
  "type": "module",
  "scripts": {
    "dev": "bun run --watch src/index.ts",
    "start": "bun run src/index.ts",
    "build": "tsc"
  },
  "dependencies": {
    "hono": "^4.0.0",
    "@mariozechner/pi-ai": "^0.66.1"
  },
  "devDependencies": {
    "@types/bun": "^1.0.0",
    "typescript": "^5.0.0"
  }
}
```

- [ ] **Step 2: Create tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "outDir": "./dist",
    "rootDir": "./src"
  }
}
```

- [ ] **Step 3: Commit**

```bash
mkdir -p mnemosyne-web/src/config mnemosyne-web/src/api mnemosyne-web/src/ui
cd mnemosyne-web
git init || true
git add package.json tsconfig.json
git commit -m "feat: initial project setup for mnemosyne-web"
```

---

### Task 2: Config Loaders

**Files:**
- Create: `mnemosyne-web/src/config/auth.ts`
- Create: `mnemosyne-web/src/config/settings.ts`

- [ ] **Step 1: Create auth.ts**

```typescript
import { readFileSync, existsSync } from 'fs';
import { join, expandHomeDir } from './path.ts';

interface PiAuth {
  [provider: string]: {
    type: string;
    access: string;
    refresh?: string;
    expires?: number;
    [key: string]: unknown;
  };
}

export function loadAuth(): PiAuth {
  const configPath = expandHomeDir('~/.pi/agent/auth.json');
  
  if (!existsSync(configPath)) {
    console.warn('[auth] No auth.json found, no providers available');
    return {};
  }
  
  try {
    const content = readFileSync(configPath, 'utf-8');
    return JSON.parse(content);
  } catch (e) {
    console.error('[auth] Failed to parse auth.json:', e);
    return {};
  }
}

export function getProviders(auth: PiAuth): string[] {
  return Object.keys(auth);
}
```

- [ ] **Step 2: Create settings.ts**

```typescript
import { readFileSync, existsSync } from 'fs';
import { expandHomeDir } from './path.ts';

interface PiSettings {
  lastChangelogVersion?: string;
  theme?: string;
  defaultProvider?: string;
  defaultModel?: string;
  defaultThinkingLevel?: string;
  [key: string]: unknown;
}

export function loadSettings(): PiSettings {
  const configPath = expandHomeDir('~/.pi/agent/settings.json');
  
  if (!existsSync(configPath)) {
    console.warn('[settings] No settings.json found, using defaults');
    return {};
  }
  
  try {
    const content = readFileSync(configPath, 'utf-8');
    return JSON.parse(content);
  } catch (e) {
    console.error('[settings] Failed to parse settings.json:', e);
    return {};
  }
}

export function getDefaults(settings: PiSettings): { provider: string; model: string } {
  return {
    provider: settings.defaultProvider || 'anthropic',
    model: settings.defaultModel || 'claude-sonnet-4-20250514'
  };
}
```

- [ ] **Step 3: Create path.ts helper**

```typescript
import { homedir } from 'os';

export function expandHomeDir(path: string): string {
  if (path.startsWith('~/')) {
    return join(homedir(), path.slice(2));
  }
  return path;
}

import { join } from 'path';
```

- [ ] **Step 4: Commit**

```bash
cd mnemosyne-web
git add src/config/auth.ts src/config/settings.ts src/config/path.ts
git commit -m "feat: add config loaders for pi auth and settings"
```

---

### Task 3: Chat API Endpoint

**Files:**
- Create: `mnemosyne-web/src/api/chat.ts`

- [ ] **Step 1: Create chat.ts**

```typescript
import { Hono } from 'hono';
import { stream } from 'hono/streaming';
import { getModel, type Context, type Model } from '@mariozechner/pi-ai';
import type { PiAuth } from '../config/auth.ts';

export function createChatRouter(auth: PiAuth) {
  const app = new Hono();
  
  // GET /api/providers - list available providers
  app.get('/providers', (c) => {
    const providers = Object.keys(auth);
    return c.json({ providers });
  });
  
  // POST /api/chat - send message and get response
  app.post('/chat', async (c) => {
    const body = await c.req.json();
    const { messages, provider, model } = body;
    
    if (!provider || !model) {
      return c.json({ error: 'Provider and model required' }, 400);
    }
    
    const providerAuth = auth[provider];
    if (!providerAuth) {
      return c.json({ error: `Provider ${provider} not configured` }, 400);
    }
    
    // Map provider names to pi-ai provider IDs
    const providerMap: Record<string, string> = {
      'github-copilot': 'github-copilot',
      'google-antigravity': 'google',
      'qwen-cli': 'openai', // Qwen uses OpenAI-compatible API
    };
    
    const piProvider = providerMap[provider] || provider;
    
    try {
      const llmModel = getModel(piProvider, model);
      
      const context: Context = {
        systemPrompt: 'You are a helpful assistant.',
        messages: [
          ...messages.map((m: { role: string; content: string }) => ({
            role: m.role,
            content: m.content,
            timestamp: Date.now()
          }))
        ],
        tools: []
      };
      
      // Use the access token from auth.json
      const apiKey = providerAuth.access;
      
      return stream(c, async (stream) => {
        const s = llmModel.api === 'anthropic-messages' 
          ? await import('@mariozechner/pi-ai').then(m => m.stream(llmModel, context, { apiKey }))
          : await import('@mariozechner/pi-ai').then(m => m.stream(llmModel, context, { apiKey }));
        
        for await (const event of s) {
          if (event.type === 'text_delta') {
            await stream.write(event.delta);
          } else if (event.type === 'error') {
            await stream.write(`\n[Error: ${event.error.errorMessage}]`);
          }
        }
      });
    } catch (e) {
      return c.json({ error: `LLM call failed: ${e}` }, 500);
    }
  });
  
  return app;
}
```

- [ ] **Step 2: Commit**

```bash
cd mnemosyne-web
git add src/api/chat.ts
git commit -m "feat: add chat API endpoint with pi-ai integration"
```

---

### Task 4: Server Entry Point

**Files:**
- Create: `mnemosyne-web/src/index.ts`

- [ ] **Step 1: Create index.ts**

```typescript
import { Hono } from 'hono';
import { serveStatic } from 'hono/bun';
import { loadAuth } from './config/auth.ts';
import { loadSettings, getDefaults } from './config/settings.ts';
import { createChatRouter } from './api/chat.ts';

const app = new Hono();

// Load config on startup
const auth = loadAuth();
const settings = loadSettings();
const defaults = getDefaults(settings);

console.log('[mnemosyne] Loaded providers:', Object.keys(auth));
console.log('[mnemosyne] Default provider:', defaults.provider, 'model:', defaults.model);

// API routes
app.route('/api', createChatRouter(auth));

// Serve UI
app.get('/', (c) => c.redirect('/index.html'));
app.get('/index.html', serveStatic({ path: './src/ui/index.html' }));
app.get('/style.css', serveStatic({ path: './src/ui/style.css' }));

// Get config for UI
app.get('/api/config', (c) => c.json({
  providers: Object.keys(auth),
  defaults
}));

const port = parseInt(process.env.PORT || '3000');
console.log(`[mnemosyne] Server starting on http://localhost:${port}`);

export default {
  port,
  fetch: app.fetch
};
```

- [ ] **Step 2: Commit**

```bash
cd mnemosyne-web
git add src/index.ts
git commit -m "feat: add server entry point with routing"
```

---

### Task 5: Web UI

**Files:**
- Create: `mnemosyne-web/src/ui/index.html`
- Create: `mnemosyne-web/src/ui/style.css`

- [ ] **Step 1: Create index.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mnemosyne</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <div class="container">
    <header>
      <h1>Mnemosyne</h1>
      <div class="model-selector">
        <select id="providerSelect">
          <option value="">Loading...</option>
        </select>
        <input type="text" id="modelInput" placeholder="Model" />
      </div>
    </header>
    
    <div id="chat" class="chat">
      <div class="message system">
        Welcome to Mnemosyne. Select a provider and model, then start chatting.
      </div>
    </div>
    
    <footer>
      <textarea id="input" placeholder="Type your message..." rows="3"></textarea>
      <button id="send">Send</button>
    </footer>
  </div>

  <script type="module">
    const providerSelect = document.getElementById('providerSelect');
    const modelInput = document.getElementById('modelInput');
    const chat = document.getElementById('chat');
    const input = document.getElementById('input');
    const sendBtn = document.getElementById('send');

    let config = null;
    let loading = false;

    // Load config on start
    fetch('/api/config')
      .then(r => r.json())
      .then(c => {
        config = c;
        providerSelect.innerHTML = config.providers.map(p => 
          `<option value="${p}" ${p === config.defaults.provider ? 'selected' : ''}>${p}</option>`
        ).join('');
        modelInput.value = config.defaults.model;
      });

    function addMessage(content, role = 'user') {
      const div = document.createElement('div');
      div.className = `message ${role}`;
      div.textContent = content;
      chat.appendChild(div);
      chat.scrollTop = chat.scrollHeight;
    }

    async function sendMessage() {
      if (loading) return;
      const message = input.value.trim();
      if (!message) return;

      addMessage(message, 'user');
      input.value = '';
      loading = true;

      const provider = providerSelect.value;
      const model = modelInput.value;
      const messages = [
        { role: 'user', content: message }
      ];

      try {
        const response = await fetch('/api/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ messages, provider, model })
        });

        if (!response.ok) {
          const err = await response.json();
          addMessage(`Error: ${err.error}`, 'error');
          return;
        }

        const reader = response.body.getReader();
        const decoder = new TextDecoder();
        
        const assistantMsg = document.createElement('div');
        assistantMsg.className = 'message assistant';
        chat.appendChild(assistantMsg);

        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          assistantMsg.textContent += decoder.decode(value);
          chat.scrollTop = chat.scrollHeight;
        }
      } catch (e) {
        addMessage(`Error: ${e}`, 'error');
      } finally {
        loading = false;
      }
    }

    sendBtn.addEventListener('click', sendMessage);
    input.addEventListener('keydown', e => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
      }
    });
  </script>
</body>
</html>
```

- [ ] **Step 2: Create style.css**

```css
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: #1a1a1a;
  color: #e0e0e0;
  height: 100vh;
}

.container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  max-width: 800px;
  margin: 0 auto;
  padding: 1rem;
}

header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 0;
  border-bottom: 1px solid #333;
}

header h1 {
  font-size: 1.5rem;
  font-weight: 600;
}

.model-selector {
  display: flex;
  gap: 0.5rem;
}

select, input {
  padding: 0.5rem;
  background: #2a2a2a;
  border: 1px solid #444;
  color: #e0e0e0;
  border-radius: 4px;
}

select {
  min-width: 150px;
}

input {
  width: 200px;
}

.chat {
  flex: 1;
  overflow-y: auto;
  padding: 1rem 0;
}

.message {
  padding: 0.75rem 1rem;
  margin-bottom: 0.5rem;
  border-radius: 8px;
  white-space: pre-wrap;
  word-wrap: break-word;
}

.message.user {
  background: #2a4a6a;
  margin-left: 2rem;
}

.message.assistant {
  background: #2a2a2a;
  margin-right: 2rem;
}

.message.system {
  background: #333;
  font-style: italic;
}

.message.error {
  background: #4a2a2a;
  color: #ff6b6b;
}

footer {
  display: flex;
  gap: 0.5rem;
  padding-top: 1rem;
  border-top: 1px solid #333;
}

textarea {
  flex: 1;
  padding: 0.75rem;
  background: #2a2a2a;
  border: 1px solid #444;
  color: #e0e0e0;
  border-radius: 4px;
  resize: none;
  font-family: inherit;
}

textarea:focus {
  outline: none;
  border-color: #5a5a5a;
}

button {
  padding: 0.75rem 1.5rem;
  background: #4a6a8a;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
}

button:hover {
  background: #5a7a9a;
}

button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
```

- [ ] **Step 3: Commit**

```bash
cd mnemosyne-web
git add src/ui/index.html src/ui/style.css
git commit -m "feat: add web UI with chat interface"
```

---

### Task 6: Test and Verify

**Files:**
- Test: Run server and verify functionality

- [ ] **Step 1: Install dependencies**

```bash
cd mnemosyne-web
bun install
```

- [ ] **Step 2: Start server**

```bash
cd mnemosyne-web
bun run dev
```

Expected: Server starts, loads providers from auth.json, logs them

- [ ] **Step 3: Test in browser**

Open http://localhost:3000 in browser

Check:
- Provider dropdown shows available providers from auth.json
- Default model is populated
- Can type a message and send
- Response streams back

- [ ] **Step 4: Commit**

```bash
cd mnemosyne-web
git add -A
git commit -m "feat: complete mnemosyne web UI phase 1"
```

---

## Acceptance Criteria

- [ ] Server starts without errors
- [ ] Auth.json is loaded and providers are available
- [ ] Settings.json is loaded and defaults are applied
- [ ] Web UI loads in browser
- [ ] Model selector shows configured providers
- [ ] Messages can be sent and responses received
- [ ] Response streams in real-time

---

**Plan complete and saved to `docs/superpowers/plans/2026-04-08-mnemosyne-web-ui-phase1-implementation.md`. Two execution options:**

1. **Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

2. **Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?