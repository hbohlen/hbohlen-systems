# oh-my-pi Web Frontend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a browser-based chat interface for the oh-my-pi SDK with session management, streaming responses, and tool execution display.

**Architecture:** Hono backend with WebSocket streaming, React frontend with Vite, file-backed sessions via SDK's SessionManager. Served via tailscale on NixOS VPS.

**Tech Stack:** Bun + Hono + @oh-my-pi/pi-coding-agent SDK, React + Vite + TypeScript, tailscale serve

---

## Project Structure

```
apps/oh-my-pi-web/
├── backend/
│   ├── src/
│   │   ├── index.ts              # Hono server + WebSocket + static files
│   │   ├── session-manager.ts    # SDK session lifecycle management
│   │   └── api/
│   │       └── routes.ts         # REST API routes
│   ├── package.json
│   ├── tsconfig.json
│   └── .env.example
├── frontend/
│   ├── src/
│   │   ├── main.tsx              # Entry point
│   │   ├── App.tsx               # Main layout with sidebar + chat
│   │   ├── components/
│   │   │   ├── Chat.tsx          # Message list + input
│   │   │   ├── SessionList.tsx   # Sidebar session management
│   │   │   ├── Message.tsx       # Individual message display
│   │   │   └── ToolOutput.tsx    # Tool execution display
│   │   └── hooks/
│   │       ├── useSession.ts     # WebSocket + session state
│   │       └── useStreaming.ts   # Text delta accumulation
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   └── index.html
└── flake.nix                      # Nix packaging
```

---

## Task 1: Backend Project Setup

**Files:**
- Create: `apps/oh-my-pi-web/backend/package.json`
- Create: `apps/oh-my-pi-web/backend/tsconfig.json`
- Create: `apps/oh-my-pi-web/backend/.env.example`

- [ ] **Step 1: Create backend package.json**

```json
{
  "name": "oh-my-pi-web-backend",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "bun run --hot src/index.ts",
    "build": "bun build src/index.ts --outdir dist --target node",
    "start": "bun run dist/index.js",
    "check": "tsc --noEmit"
  },
  "dependencies": {
    "@oh-my-pi/pi-coding-agent": "latest",
    "hono": "^4.0.0",
    "@hono/node-ws": "^1.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.3.0",
    "bun-types": "latest"
  }
}
```

- [ ] **Step 2: Create backend tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "outDir": "dist",
    "rootDir": "src",
    "types": ["bun-types"]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

- [ ] **Step 3: Create backend .env.example**

```bash
OMP_WEB_TOKEN=your-secret-token-here
OMP_DATA_DIR=/var/lib/oh-my-pi-web
OMP_PORT=3000
OMP_MODEL=
OMP_THINKING_LEVEL=medium
```

- [ ] **Step 4: Install dependencies**

```bash
cd apps/oh-my-pi-web/backend
bun install
```

Expected: Dependencies install without errors.

- [ ] **Step 5: Commit**

```bash
git add apps/oh-my-pi-web/backend/
git commit -m "feat(oh-my-pi-web): add backend project setup"
```

---

## Task 2: Backend Session Manager

**Files:**
- Create: `apps/oh-my-pi-web/backend/src/session-manager.ts`
- Create: `apps/oh-my-pi-web/backend/src/types.ts`

- [ ] **Step 1: Create types.ts**

```typescript
export interface SessionInfo {
  id: string;
  path: string;
  createdAt: number;
  updatedAt: number;
  messageCount: number;
  preview?: string;
}

export interface WSMessage {
  type: 'prompt' | 'abort' | 'steer' | 'fork';
  data?: unknown;
}

export interface WSEvent {
  type: 'connected' | 'event' | 'error' | 'session_loaded';
  data?: unknown;
}
```

- [ ] **Step 2: Create session-manager.ts**

```typescript
import { createAgentSession, SessionManager, AgentSession, AgentSessionEvent } from '@oh-my-pi/pi-coding-agent';
import type { ServerWebSocket } from 'bun';
import { SessionInfo, WSEvent } from './types.js';

interface SessionEntry {
  session: AgentSession;
  ws: ServerWebSocket<unknown>;
  info: SessionInfo;
}

export class SDKSessionManager {
  private sessions = new Map<string, SessionEntry>();
  private sessionManager: SessionManager;
  private dataDir: string;

  constructor(dataDir: string) {
    this.dataDir = dataDir;
    this.sessionManager = SessionManager.create(dataDir);
  }

  async createSession(ws: ServerWebSocket<unknown>): Promise<SessionInfo> {
    const id = crypto.randomUUID();
    const path = `${this.dataDir}/session-${id}.jsonl`;
    
    const { session } = await createAgentSession({
      sessionManager: this.sessionManager,
    });

    const info: SessionInfo = {
      id,
      path,
      createdAt: Date.now(),
      updatedAt: Date.now(),
      messageCount: 0,
    };

    this.sessions.set(id, { session, ws, info });
    this.subscribeToSession(id, session, ws);

    return info;
  }

  async loadSession(sessionId: string, ws: ServerWebSocket<unknown>): Promise<SessionInfo | null> {
    const sessions = await SessionManager.list(this.dataDir);
    const existing = sessions.find(s => s.path.includes(sessionId));
    
    if (!existing) return null;

    const session = await SessionManager.open(existing.path);
    
    const info: SessionInfo = {
      id: sessionId,
      path: existing.path,
      createdAt: existing.createdAt?.getTime() || Date.now(),
      updatedAt: existing.updatedAt?.getTime() || Date.now(),
      messageCount: session.messages.length,
      preview: session.messages[0]?.content?.toString().slice(0, 100),
    };

    this.sessions.set(sessionId, { session, ws, info });
    this.subscribeToSession(sessionId, session, ws);

    return info;
  }

  async listSessions(): Promise<SessionInfo[]> {
    const sessions = await SessionManager.list(this.dataDir);
    return sessions.map(s => ({
      id: s.path.split('/').pop()?.replace('.jsonl', '') || s.path,
      path: s.path,
      createdAt: s.createdAt?.getTime() || 0,
      updatedAt: s.updatedAt?.getTime() || 0,
      messageCount: 0,
    }));
  }

  async forkSession(sessionId: string, ws: ServerWebSocket<unknown>): Promise<SessionInfo | null> {
    const entry = this.sessions.get(sessionId);
    if (!entry) return null;

    const newId = crypto.randomUUID();
    const newPath = `${this.dataDir}/session-${newId}.jsonl`;
    
    // Use SDK's session forking if available, otherwise create fresh
    const { session: newSession } = await createAgentSession({
      sessionManager: this.sessionManager,
    });

    const info: SessionInfo = {
      id: newId,
      path: newPath,
      createdAt: Date.now(),
      updatedAt: Date.now(),
      messageCount: entry.info.messageCount,
      preview: entry.info.preview,
    };

    this.sessions.set(newId, { session: newSession, ws, info });
    this.subscribeToSession(newId, newSession, ws);

    return info;
  }

  async deleteSession(sessionId: string): Promise<boolean> {
    const entry = this.sessions.get(sessionId);
    if (entry) {
      await entry.session.dispose();
      this.sessions.delete(sessionId);
    }
    // Note: Actual file deletion would require filesystem access
    return true;
  }

  getSession(sessionId: string): AgentSession | null {
    return this.sessions.get(sessionId)?.session || null;
  }

  updateWebSocket(sessionId: string, ws: ServerWebSocket<unknown>): boolean {
    const entry = this.sessions.get(sessionId);
    if (!entry) return false;
    
    entry.ws = ws;
    this.subscribeToSession(sessionId, entry.session, ws);
    return true;
  }

  private subscribeToSession(
    sessionId: string, 
    session: AgentSession, 
    ws: ServerWebSocket<unknown>
  ): void {
    session.subscribe((event: AgentSessionEvent) => {
      if (ws.readyState === 1) { // WebSocket.OPEN
        ws.send(JSON.stringify({
          type: 'event',
          data: { sessionId, event }
        } as WSEvent));
      }

      // Update message count on turn end
      if (event.type === 'turn_end') {
        const entry = this.sessions.get(sessionId);
        if (entry) {
          entry.info.messageCount = session.messages.length;
          entry.info.updatedAt = Date.now();
        }
      }
    });
  }

  async dispose(): Promise<void> {
    for (const [, entry] of this.sessions) {
      await entry.session.dispose();
    }
    this.sessions.clear();
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add apps/oh-my-pi-web/backend/src/
git commit -m "feat(oh-my-pi-web): add session manager with SDK integration"
```

---

## Task 3: Backend API Routes

**Files:**
- Create: `apps/oh-my-pi-web/backend/src/api/routes.ts`

- [ ] **Step 1: Create API routes**

```typescript
import { Hono } from 'hono';
import { SDKSessionManager } from '../session-manager.js';

export function createApiRoutes(sessionManager: SDKSessionManager) {
  const api = new Hono();

  // Auth middleware
  api.use('*', async (c, next) => {
    const token = c.req.header('Authorization')?.replace('Bearer ', '');
    const expectedToken = process.env.OMP_WEB_TOKEN;
    
    if (expectedToken && token !== expectedToken) {
      return c.json({ error: 'Unauthorized' }, 401);
    }
    
    await next();
  });

  // List sessions
  api.get('/sessions', async (c) => {
    const sessions = await sessionManager.listSessions();
    return c.json({ sessions });
  });

  // Create new session
  api.post('/sessions', async (c) => {
    // Note: actual session creation happens on WebSocket connect
    // This just returns a new ID
    const id = crypto.randomUUID();
    return c.json({ id, status: 'created' });
  });

  // Get session details
  api.get('/sessions/:id', async (c) => {
    const id = c.req.param('id');
    const sessions = await sessionManager.listSessions();
    const session = sessions.find(s => s.id === id);
    
    if (!session) {
      return c.json({ error: 'Session not found' }, 404);
    }
    
    return c.json({ session });
  });

  // Fork session
  api.post('/sessions/:id/fork', async (c) => {
    const id = c.req.param('id');
    // Note: forking requires WebSocket context, handled via WS
    return c.json({ error: 'Use WebSocket to fork sessions' }, 400);
  });

  // Delete session
  api.delete('/sessions/:id', async (c) => {
    const id = c.req.param('id');
    const success = await sessionManager.deleteSession(id);
    
    if (!success) {
      return c.json({ error: 'Session not found' }, 404);
    }
    
    return c.json({ status: 'deleted' });
  });

  // Health check
  api.get('/health', (c) => {
    return c.json({ status: 'ok', timestamp: Date.now() });
  });

  return api;
}
```

- [ ] **Step 2: Commit**

```bash
git add apps/oh-my-pi-web/backend/src/api/
git commit -m "feat(oh-my-pi-web): add REST API routes"
```

---

## Task 4: Backend Main Server

**Files:**
- Create: `apps/oh-my-pi-web/backend/src/index.ts`

- [ ] **Step 1: Create main server with WebSocket**

```typescript
import { Hono } from 'hono';
import { serveStatic } from 'hono/bun';
import { SDKSessionManager } from './session-manager.js';
import { createApiRoutes } from './api/routes.js';
import type { WSMessage, WSEvent } from './types.js';

const DATA_DIR = process.env.OMP_DATA_DIR || `${process.env.HOME}/.omp/sessions`;
const PORT = parseInt(process.env.OMP_PORT || '3000', 10);
const TOKEN = process.env.OMP_WEB_TOKEN;

const sessionManager = new SDKSessionManager(DATA_DIR);
const app = new Hono();

// API routes
app.route('/api', createApiRoutes(sessionManager));

// Static files (frontend build)
app.use('/*', serveStatic({ root: './frontend/dist' }));

// Bun WebSocket server
const server = Bun.serve({
  port: PORT,
  fetch(req, server) {
    const url = new URL(req.url);
    
    // WebSocket upgrade
    if (url.pathname === '/ws') {
      // Check auth
      if (TOKEN) {
        const authHeader = req.headers.get('Authorization');
        const token = authHeader?.replace('Bearer ', '');
        if (token !== TOKEN) {
          return new Response('Unauthorized', { status: 401 });
        }
      }
      
      const sessionId = url.searchParams.get('sessionId');
      const success = server.upgrade(req, { data: { sessionId } });
      return success 
        ? undefined 
        : new Response('WebSocket upgrade failed', { status: 400 });
    }
    
    // HTTP requests
    return app.fetch(req, server);
  },
  
  websocket: {
    async open(ws) {
      const { sessionId } = ws.data as { sessionId?: string };
      
      let info;
      if (sessionId) {
        // Try to resume existing session
        info = await sessionManager.loadSession(sessionId, ws);
        if (!info) {
          ws.send(JSON.stringify({
            type: 'error',
            data: { message: 'Session not found, creating new' }
          } as WSEvent));
          info = await sessionManager.createSession(ws);
        }
      } else {
        // Create new session
        info = await sessionManager.createSession(ws);
      }
      
      ws.send(JSON.stringify({
        type: 'connected',
        data: { sessionId: info.id, info }
      } as WSEvent));
    },
    
    async message(ws, message) {
      try {
        const { type, data }: WSMessage = JSON.parse(message.toString());
        const { sessionId } = ws.data as { sessionId: string };
        const session = sessionManager.getSession(sessionId);
        
        if (!session) {
          ws.send(JSON.stringify({
            type: 'error',
            data: { message: 'Session not found' }
          } as WSEvent));
          return;
        }
        
        switch (type) {
          case 'prompt':
            const { text } = data as { text: string };
            await session.prompt(text);
            break;
            
          case 'abort':
            session.abort();
            break;
            
          case 'steer':
            const { steerText } = data as { steerText: string };
            await session.steer(steerText);
            break;
            
          case 'fork':
            const newInfo = await sessionManager.forkSession(sessionId, ws);
            ws.send(JSON.stringify({
              type: 'session_loaded',
              data: { sessionId: newInfo?.id, info: newInfo }
            } as WSEvent));
            break;
            
          default:
            ws.send(JSON.stringify({
              type: 'error',
              data: { message: `Unknown message type: ${type}` }
            } as WSEvent));
        }
      } catch (error) {
        ws.send(JSON.stringify({
          type: 'error',
          data: { message: error instanceof Error ? error.message : 'Unknown error' }
        } as WSEvent));
      }
    },
    
    async close(ws) {
      // Session persists, just note disconnect
      console.log('WebSocket closed');
    },
  },
});

console.log(`Server running on port ${PORT}`);

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('Shutting down...');
  await sessionManager.dispose();
  server.stop();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('Shutting down...');
  await sessionManager.dispose();
  server.stop();
  process.exit(0);
});
```

- [ ] **Step 2: Test backend starts**

```bash
cd apps/oh-my-pi-web/backend
export OMP_WEB_TOKEN=test-token
bun run src/index.ts &
sleep 2
curl -H "Authorization: Bearer test-token" http://localhost:3000/api/health
kill %1
```

Expected: `{"status":"ok","timestamp":...}`

- [ ] **Step 3: Commit**

```bash
git add apps/oh-my-pi-web/backend/src/index.ts
git commit -m "feat(oh-my-pi-web): add main server with WebSocket support"
```

---

## Task 5: Frontend Project Setup

**Files:**
- Create: `apps/oh-my-pi-web/frontend/package.json`
- Create: `apps/oh-my-pi-web/frontend/tsconfig.json`
- Create: `apps/oh-my-pi-web/frontend/vite.config.ts`
- Create: `apps/oh-my-pi-web/frontend/index.html`

- [ ] **Step 1: Create frontend package.json**

```json
{
  "name": "oh-my-pi-web-frontend",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "check": "tsc --noEmit"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-markdown": "^9.0.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "@vitejs/plugin-react": "^4.2.0",
    "typescript": "^5.3.0",
    "vite": "^5.0.0"
  }
}
```

- [ ] **Step 2: Create frontend tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

- [ ] **Step 3: Create vite.config.ts**

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
      '/ws': {
        target: 'ws://localhost:3000',
        ws: true,
      },
    },
  },
  build: {
    outDir: 'dist',
  },
});
```

- [ ] **Step 4: Create index.html**

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>oh-my-pi Web</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

- [ ] **Step 5: Install dependencies**

```bash
cd apps/oh-my-pi-web/frontend
bun install
```

- [ ] **Step 6: Commit**

```bash
git add apps/oh-my-pi-web/frontend/
git commit -m "feat(oh-my-pi-web): add frontend project setup"
```

---

## Task 6: Frontend Session Hook

**Files:**
- Create: `apps/oh-my-pi-web/frontend/src/hooks/useSession.ts`
- Create: `apps/oh-my-pi-web/frontend/src/types.ts`

- [ ] **Step 1: Create types.ts**

```typescript
export interface SessionInfo {
  id: string;
  path: string;
  createdAt: number;
  updatedAt: number;
  messageCount: number;
  preview?: string;
}

export interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  isStreaming?: boolean;
  tools?: ToolExecution[];
}

export interface ToolExecution {
  id: string;
  name: string;
  arguments: unknown;
  result?: unknown;
  status: 'running' | 'completed' | 'error';
}

export interface WSEvent {
  type: 'connected' | 'event' | 'error' | 'session_loaded';
  data?: {
    sessionId?: string;
    info?: SessionInfo;
    event?: {
      type: string;
      assistantMessageEvent?: {
        type: string;
        delta?: string;
      };
    };
  };
}
```

- [ ] **Step 2: Create useSession.ts**

```typescript
import { useState, useEffect, useCallback, useRef } from 'react';
import type { SessionInfo, Message, ToolExecution, WSEvent } from '../types';

const TOKEN = import.meta.env.VITE_API_TOKEN || '';

export function useSession() {
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [sessionInfo, setSessionInfo] = useState<SessionInfo | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [isConnected, setIsConnected] = useState(false);
  const [isStreaming, setIsStreaming] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const wsRef = useRef<WebSocket | null>(null);
  const currentMessageRef = useRef<Message | null>(null);

  const connect = useCallback((existingSessionId?: string) => {
    const wsUrl = new URL('/ws', window.location.origin);
    wsUrl.protocol = wsUrl.protocol === 'https:' ? 'wss:' : 'ws:';
    if (existingSessionId) {
      wsUrl.searchParams.set('sessionId', existingSessionId);
    }

    const ws = new WebSocket(wsUrl.toString());
    
    ws.onopen = () => {
      setIsConnected(true);
      setError(null);
    };

    ws.onmessage = (event) => {
      const msg: WSEvent = JSON.parse(event.data);
      
      switch (msg.type) {
        case 'connected':
          if (msg.data?.sessionId) {
            setSessionId(msg.data.sessionId);
            setSessionInfo(msg.data.info || null);
          }
          break;
          
        case 'session_loaded':
          if (msg.data?.sessionId) {
            setSessionId(msg.data.sessionId);
            setSessionInfo(msg.data.info || null);
            setMessages([]);
          }
          break;
          
        case 'event':
          handleSDKEvent(msg.data?.event);
          break;
          
        case 'error':
          setError(msg.data?.message || 'Unknown error');
          break;
      }
    };

    ws.onclose = () => {
      setIsConnected(false);
    };

    ws.onerror = () => {
      setError('WebSocket error');
      setIsConnected(false);
    };

    wsRef.current = ws;
  }, []);

  const handleSDKEvent = useCallback((event: WSEvent['data']['event']) => {
    if (!event) return;

    switch (event.type) {
      case 'turn_start':
        setIsStreaming(true);
        currentMessageRef.current = {
          id: crypto.randomUUID(),
          role: 'assistant',
          content: '',
          isStreaming: true,
          tools: [],
        };
        break;
        
      case 'message_update':
        if (event.assistantMessageEvent?.type === 'text_delta') {
          const delta = event.assistantMessageEvent.delta || '';
          if (currentMessageRef.current) {
            currentMessageRef.current.content += delta;
            setMessages(prev => {
              const filtered = prev.filter(m => m.id !== currentMessageRef.current!.id);
              return [...filtered, { ...currentMessageRef.current! }];
            });
          }
        }
        break;
        
      case 'tool_execution_start':
        if (currentMessageRef.current) {
          currentMessageRef.current.tools = currentMessageRef.current.tools || [];
          currentMessageRef.current.tools.push({
            id: crypto.randomUUID(),
            name: '',
            arguments: {},
            status: 'running',
          });
        }
        break;
        
      case 'turn_end':
        setIsStreaming(false);
        if (currentMessageRef.current) {
          currentMessageRef.current.isStreaming = false;
          setMessages(prev => {
            const filtered = prev.filter(m => m.id !== currentMessageRef.current!.id);
            return [...filtered, { ...currentMessageRef.current! }];
          });
          currentMessageRef.current = null;
        }
        break;
    }
  }, []);

  const sendMessage = useCallback((text: string) => {
    if (!wsRef.current || wsRef.current.readyState !== WebSocket.OPEN) {
      setError('Not connected');
      return;
    }

    // Add user message locally
    const userMessage: Message = {
      id: crypto.randomUUID(),
      role: 'user',
      content: text,
    };
    setMessages(prev => [...prev, userMessage]);

    // Send to server
    wsRef.current.send(JSON.stringify({
      type: 'prompt',
      data: { text }
    }));
  }, []);

  const abort = useCallback(() => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ type: 'abort' }));
    }
  }, []);

  const fork = useCallback(() => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify({ type: 'fork' }));
    }
  }, []);

  const disconnect = useCallback(() => {
    wsRef.current?.close();
  }, []);

  useEffect(() => {
    return () => {
      disconnect();
    };
  }, [disconnect]);

  return {
    sessionId,
    sessionInfo,
    messages,
    isConnected,
    isStreaming,
    error,
    connect,
    disconnect,
    sendMessage,
    abort,
    fork,
  };
}
```

- [ ] **Step 3: Commit**

```bash
git add apps/oh-my-pi-web/frontend/src/
git commit -m "feat(oh-my-pi-web): add useSession hook for WebSocket management"
```

---

## Task 7: Frontend Components

**Files:**
- Create: `apps/oh-my-pi-web/frontend/src/components/SessionList.tsx`
- Create: `apps/oh-my-pi-web/frontend/src/components/Chat.tsx`
- Create: `apps/oh-my-pi-web/frontend/src/components/Message.tsx`

- [ ] **Step 1: Create SessionList.tsx**

```tsx
import { useState, useEffect } from 'react';
import type { SessionInfo } from '../types';

interface SessionListProps {
  currentSessionId: string | null;
  onSelectSession: (id: string) => void;
  onNewSession: () => void;
  token: string;
}

export function SessionList({ currentSessionId, onSelectSession, onNewSession, token }: SessionListProps) {
  const [sessions, setSessions] = useState<SessionInfo[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    loadSessions();
  }, []);

  const loadSessions = async () => {
    setIsLoading(true);
    try {
      const res = await fetch('/api/sessions', {
        headers: { Authorization: `Bearer ${token}` },
      });
      const data = await res.json();
      setSessions(data.sessions || []);
    } catch (err) {
      console.error('Failed to load sessions:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const formatDate = (timestamp: number) => {
    return new Date(timestamp).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <div className="session-list">
      <div className="session-list-header">
        <h2>Sessions</h2>
        <button onClick={onNewSession} className="new-session-btn">
          + New
        </button>
      </div>
      
      {isLoading ? (
        <div className="loading">Loading...</div>
      ) : (
        <div className="sessions">
          {sessions.map(session => (
            <div
              key={session.id}
              className={`session-item ${session.id === currentSessionId ? 'active' : ''}`}
              onClick={() => onSelectSession(session.id)}
            >
              <div className="session-preview">
                {session.preview || 'New conversation'}
              </div>
              <div className="session-meta">
                {formatDate(session.updatedAt)} · {session.messageCount} msgs
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Create Message.tsx**

```tsx
import ReactMarkdown from 'react-markdown';
import type { Message as MessageType } from '../types';

interface MessageProps {
  message: MessageType;
}

export function Message({ message }: MessageProps) {
  return (
    <div className={`message ${message.role}`}>
      <div className="message-header">
        {message.role === 'user' ? 'You' : 'Assistant'}
      </div>
      <div className="message-content">
        <ReactMarkdown>{message.content}</ReactMarkdown>
        {message.isStreaming && <span className="typing-indicator">▋</span>}
      </div>
      {message.tools && message.tools.length > 0 && (
        <div className="tool-executions">
          {message.tools.map(tool => (
            <div key={tool.id} className={`tool-item ${tool.status}`}>
              <div className="tool-name">{tool.name}</div>
              <div className="tool-status">{tool.status}</div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 3: Create Chat.tsx**

```tsx
import { useState, useRef, useEffect } from 'react';
import { Message } from './Message';
import type { Message as MessageType } from '../types';

interface ChatProps {
  messages: MessageType[];
  isStreaming: boolean;
  onSendMessage: (text: string) => void;
  onAbort: () => void;
  onFork: () => void;
}

export function Chat({ messages, isStreaming, onSendMessage, onAbort, onFork }: ChatProps) {
  const [input, setInput] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (input.trim() && !isStreaming) {
      onSendMessage(input.trim());
      setInput('');
    }
  };

  return (
    <div className="chat">
      <div className="chat-header">
        <h1>oh-my-pi</h1>
        <button onClick={onFork} disabled={isStreaming} className="fork-btn">
          Fork Session
        </button>
      </div>
      
      <div className="messages">
        {messages.length === 0 ? (
          <div className="empty-state">
            <p>Start a conversation with the oh-my-pi coding agent.</p>
          </div>
        ) : (
          messages.map(message => (
            <Message key={message.id} message={message} />
          ))
        )}
        <div ref={messagesEndRef} />
      </div>
      
      <form onSubmit={handleSubmit} className="input-area">
        <textarea
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Type your message..."
          rows={3}
          disabled={isStreaming}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
              e.preventDefault();
              handleSubmit(e);
            }
          }}
        />
        <div className="input-actions">
          {isStreaming ? (
            <button type="button" onClick={onAbort} className="abort-btn">
              Stop
            </button>
          ) : (
            <button type="submit" disabled={!input.trim()} className="send-btn">
              Send
            </button>
          )}
        </div>
      </form>
    </div>
  );
}
```

- [ ] **Step 4: Commit**

```bash
git add apps/oh-my-pi-web/frontend/src/components/
git commit -m "feat(oh-my-pi-web): add chat and session list components"
```

---

## Task 8: Frontend Main App

**Files:**
- Create: `apps/oh-my-pi-web/frontend/src/App.tsx`
- Create: `apps/oh-my-pi-web/frontend/src/main.tsx`
- Create: `apps/oh-my-pi-web/frontend/src/App.css`

- [ ] **Step 1: Create main.tsx**

```tsx
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './App.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
```

- [ ] **Step 2: Create App.tsx**

```tsx
import { useEffect } from 'react';
import { useSession } from './hooks/useSession';
import { SessionList } from './components/SessionList';
import { Chat } from './components/Chat';

const TOKEN = import.meta.env.VITE_API_TOKEN || '';

function App() {
  const {
    sessionId,
    messages,
    isConnected,
    isStreaming,
    error,
    connect,
    disconnect,
    sendMessage,
    abort,
    fork,
  } = useSession();

  useEffect(() => {
    connect();
    return () => disconnect();
  }, [connect, disconnect]);

  const handleNewSession = () => {
    disconnect();
    connect();
  };

  const handleSelectSession = (id: string) => {
    disconnect();
    connect(id);
  };

  if (error) {
    return (
      <div className="error-screen">
        <h2>Error</h2>
        <p>{error}</p>
        <button onClick={() => connect()}>Retry</button>
      </div>
    );
  }

  return (
    <div className="app">
      <aside className="sidebar">
        <SessionList
          currentSessionId={sessionId}
          onSelectSession={handleSelectSession}
          onNewSession={handleNewSession}
          token={TOKEN}
        />
      </aside>
      <main className="main">
        <Chat
          messages={messages}
          isStreaming={isStreaming}
          onSendMessage={sendMessage}
          onAbort={abort}
          onFork={fork}
        />
      </main>
      {!isConnected && (
        <div className="connection-status disconnected">Disconnected</div>
      )}
    </div>
  );
}

export default App;
```

- [ ] **Step 3: Create App.css**

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
  overflow: hidden;
}

.app {
  display: flex;
  height: 100vh;
}

.sidebar {
  width: 260px;
  background: #252525;
  border-right: 1px solid #333;
  display: flex;
  flex-direction: column;
}

.session-list {
  flex: 1;
  overflow-y: auto;
}

.session-list-header {
  padding: 16px;
  border-bottom: 1px solid #333;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.session-list-header h2 {
  font-size: 14px;
  font-weight: 600;
  text-transform: uppercase;
  color: #888;
}

.new-session-btn {
  padding: 6px 12px;
  background: #4a9eff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
}

.new-session-btn:hover {
  background: #3a8eef;
}

.sessions {
  padding: 8px;
}

.session-item {
  padding: 12px;
  border-radius: 6px;
  cursor: pointer;
  margin-bottom: 4px;
}

.session-item:hover {
  background: #333;
}

.session-item.active {
  background: #3a3a3a;
}

.session-preview {
  font-size: 14px;
  color: #e0e0e0;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.session-meta {
  font-size: 11px;
  color: #666;
  margin-top: 4px;
}

.main {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.chat {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.chat-header {
  padding: 16px 24px;
  border-bottom: 1px solid #333;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.chat-header h1 {
  font-size: 18px;
  font-weight: 600;
}

.fork-btn {
  padding: 6px 12px;
  background: transparent;
  color: #888;
  border: 1px solid #444;
  border-radius: 4px;
  cursor: pointer;
  font-size: 12px;
}

.fork-btn:hover {
  background: #333;
}

.messages {
  flex: 1;
  overflow-y: auto;
  padding: 24px;
}

.empty-state {
  text-align: center;
  color: #666;
  padding: 64px;
}

.message {
  margin-bottom: 24px;
  max-width: 800px;
}

.message.user {
  margin-left: auto;
}

.message-header {
  font-size: 12px;
  font-weight: 600;
  color: #888;
  margin-bottom: 8px;
  text-transform: uppercase;
}

.message-content {
  background: #252525;
  padding: 16px;
  border-radius: 8px;
  line-height: 1.6;
}

.message.user .message-content {
  background: #4a9eff;
  color: white;
}

.message-content p {
  margin-bottom: 12px;
}

.message-content p:last-child {
  margin-bottom: 0;
}

.typing-indicator {
  animation: blink 1s infinite;
}

@keyframes blink {
  0%, 50% { opacity: 1; }
  51%, 100% { opacity: 0; }
}

.tool-executions {
  margin-top: 12px;
  padding-left: 16px;
}

.tool-item {
  padding: 8px 12px;
  background: #1a1a1a;
  border-radius: 4px;
  margin-bottom: 4px;
  display: flex;
  justify-content: space-between;
  font-size: 12px;
}

.tool-item.running {
  border-left: 2px solid #f0ad4e;
}

.tool-item.completed {
  border-left: 2px solid #5cb85c;
}

.tool-item.error {
  border-left: 2px solid #d9534f;
}

.input-area {
  padding: 24px;
  border-top: 1px solid #333;
}

.input-area textarea {
  width: 100%;
  background: #252525;
  color: #e0e0e0;
  border: 1px solid #444;
  border-radius: 8px;
  padding: 12px;
  font-family: inherit;
  font-size: 14px;
  resize: none;
}

.input-area textarea:focus {
  outline: none;
  border-color: #4a9eff;
}

.input-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 12px;
  gap: 8px;
}

.send-btn, .abort-btn {
  padding: 8px 24px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
}

.send-btn {
  background: #4a9eff;
  color: white;
}

.send-btn:hover:not(:disabled) {
  background: #3a8eef;
}

.send-btn:disabled {
  background: #333;
  cursor: not-allowed;
}

.abort-btn {
  background: #d9534f;
  color: white;
}

.abort-btn:hover {
  background: #c9302c;
}

.connection-status {
  position: fixed;
  bottom: 16px;
  right: 16px;
  padding: 8px 16px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 500;
}

.connection-status.disconnected {
  background: #d9534f;
  color: white;
}

.error-screen {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100vh;
  text-align: center;
}

.error-screen h2 {
  margin-bottom: 16px;
  color: #d9534f;
}

.error-screen button {
  margin-top: 24px;
  padding: 12px 24px;
  background: #4a9eff;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}
```

- [ ] **Step 4: Test frontend build**

```bash
cd apps/oh-my-pi-web/frontend
bun run build
```

Expected: Build completes without errors, creates `dist/` folder.

- [ ] **Step 5: Commit**

```bash
git add apps/oh-my-pi-web/frontend/src/
git commit -m "feat(oh-my-pi-web): add main app with full UI"
```

---

## Task 9: Nix Flake Integration

**Files:**
- Create: `apps/oh-my-pi-web/flake.nix`
- Modify: `flake.nix` (root)

- [ ] **Step 1: Create flake.nix**

```nix
{
  description = "oh-my-pi Web Frontend";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        packages = {
          oh-my-pi-web = pkgs.stdenv.mkDerivation {
            pname = "oh-my-pi-web";
            version = "0.1.0";
            src = ./.;

            nativeBuildInputs = with pkgs; [
              bun
              nodejs
            ];

            buildPhase = ''
              # Build frontend
              cd frontend
              bun install
              bun run build
              cd ..

              # Build backend
              cd backend
              bun install
              bun run build
              cd ..
            '';

            installPhase = ''
              mkdir -p $out/{bin,lib,share}
              
              # Copy backend
              cp -r backend/dist $out/lib/backend
              cp -r backend/node_modules $out/lib/backend/
              
              # Copy frontend
              cp -r frontend/dist $out/share/frontend
              
              # Create wrapper script
              cat > $out/bin/oh-my-pi-web << 'EOF'
              #!/bin/sh
              cd $out/lib/backend
              exec ${pkgs.bun}/bin/bun run dist/index.js "$@"
              EOF
              chmod +x $out/bin/oh-my-pi-web
            '';
          };
        };
      };
    };
}
```

- [ ] **Step 2: Modify root flake.nix to include the app**

Add to the imports:

```nix
imports = [
  ./nix/cells/devshells
  ./nix/cells/nixos
  ./apps/oh-my-pi-web/flake.nix  # Add this
];
```

- [ ] **Step 3: Commit**

```bash
git add apps/oh-my-pi-web/flake.nix flake.nix
git commit -m "feat(oh-my-pi-web): add Nix flake for packaging"
```

---

## Task 10: NixOS Service Module

**Files:**
- Create: `nix/cells/nixos/oh-my-pi-web.nix`

- [ ] **Step 1: Create NixOS service module**

```nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.oh-my-pi-web;
in
{
  options.services.oh-my-pi-web = {
    enable = mkEnableOption "oh-my-pi web frontend";

    port = mkOption {
      type = types.port;
      default = 3000;
      description = "Port to listen on";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/oh-my-pi-web";
      description = "Directory for session storage";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Environment file with OMP_WEB_TOKEN and other secrets";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall port (usually not needed with tailscale)";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.oh-my-pi-web = {
      description = "oh-my-pi Web Frontend";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.oh-my-pi-web}/bin/oh-my-pi-web";
        Restart = "always";
        RestartSec = 5;
        
        # Security hardening
        DynamicUser = true;
        StateDirectory = "oh-my-pi-web";
        WorkingDirectory = cfg.dataDir;
        
        # Environment
        Environment = [
          "OMP_PORT=${toString cfg.port}"
          "OMP_DATA_DIR=${cfg.dataDir}"
        ];
        
        # Secrets via environment file
        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;
        
        # Resource limits
        MemoryMax = "1G";
        CPUQuota = "200%";
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add nix/cells/nixos/oh-my-pi-web.nix
git commit -m "feat(oh-my-pi-web): add NixOS service module"
```

---

## Task 11: Tailscale Serve Configuration

**Files:**
- Create: `nix/cells/nixos/tailscale-serve.nix` (or add to existing host config)

- [ ] **Step 1: Add tailscale serve configuration**

Add to your NixOS host configuration:

```nix
{ config, pkgs, ... }:

{
  # Enable tailscale
  services.tailscale.enable = true;

  # Configure tailscale serve for oh-my-pi-web
  services.tailscale.serve = {
    enable = true;
    port = 3000;
  };

  # Enable the oh-my-pi-web service
  services.oh-my-pi-web = {
    enable = true;
    port = 3000;
    dataDir = "/var/lib/oh-my-pi-web";
    environmentFile = config.sops.secrets.oh-my-pi-web-env.path; # If using sops
  };
}
```

- [ ] **Step 2: Create secrets file template**

```bash
cat > examples/oh-my-pi-web.env << 'EOF'
# oh-my-pi-web environment variables
# Copy to your secrets management system (e.g., sops, agenix)

OMP_WEB_TOKEN=your-secure-random-token-here
OMP_MODEL=  # Optional: default model
OMP_THINKING_LEVEL=medium
EOF
```

- [ ] **Step 3: Commit**

```bash
git add examples/oh-my-pi-web.env
git commit -m "docs(oh-my-pi-web): add tailscale serve config and secrets template"
```

---

## Verification Steps

- [ ] **Backend starts and responds to health check**

```bash
cd apps/oh-my-pi-web/backend
export OMP_WEB_TOKEN=test
bun run src/index.ts &
curl -H "Authorization: Bearer test" http://localhost:3000/api/health
```

Expected: `{"status":"ok",...}`

- [ ] **Frontend builds successfully**

```bash
cd apps/oh-my-pi-web/frontend
bun run build
```

Expected: No errors, `dist/` created.

- [ ] **WebSocket connection works**

```bash
# In browser console or using wscat
wscat -c "ws://localhost:3000/ws" -H "Authorization: Bearer test"
> {"type":"prompt","data":{"text":"hello"}}
```

Expected: Connection opens, can send messages.

- [ ] **Nix build works**

```bash
nix build .#oh-my-pi-web
```

Expected: Build succeeds.

---

## Summary

This plan implements:
1. **Backend**: Hono server with WebSocket, SDK integration, session management
2. **Frontend**: React chat UI with streaming, session list, tool display
3. **Nix**: Packaging, NixOS service module, tailscale serve integration

Total tasks: 11
Estimated time: 2-3 hours
