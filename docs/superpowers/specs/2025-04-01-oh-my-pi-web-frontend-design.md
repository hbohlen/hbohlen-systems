# oh-my-pi Web Frontend Design

**Date:** 2025-04-01  
**Status:** Approved for implementation  
**Scope:** Browser-based interface for oh-my-pi SDK running on NixOS VPS

---

## Overview

A web-based frontend for the oh-my-pi coding agent SDK, served via tailscale on a private NixOS VPS. Provides a chat interface with streaming responses, session management, and tool execution visibility.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Tailscale Network                        │
│  ┌──────────────┐         ┌──────────────────────────────┐  │
│  │   Browser    │◄───────►│  oh-my-pi Web Frontend       │  │
│  │  (React UI)  │  HTTP   │  - Hono backend (Bun)        │  │
│  └──────────────┘         │  - SDK integration           │  │
│                           │  - WebSocket for streaming   │  │
│                           │  - Session management        │  │
│                           └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Backend | Hono (Bun) | Lightweight, native TypeScript, excellent WebSocket support |
| Frontend | React + Vite | Modern dev experience, fast HMR, minimal bundle |
| SDK | `@oh-my-pi/pi-coding-agent` | Official SDK, event streaming, session management |
| Session Storage | File-backed | Leverages SDK's `SessionManager.create()`, survives restarts |
| Auth | Simple token (env) | Basic protection without complexity; tailscale provides network security |
| Serving | `tailscale serve` | Native HTTPS, no reverse proxy needed |

---

## Components

### Backend (`apps/oh-my-pi-web/backend/`)

#### `src/index.ts`
- Hono HTTP server
- WebSocket endpoint for streaming events
- Static file serving for production
- Auth middleware (bearer token check)

#### `src/session-manager.ts`
- SDK session lifecycle management
- Maps WebSocket connections to SDK sessions
- Handles `createAgentSession()`, `session.prompt()`, `session.subscribe()`
- Session listing, resuming, forking via `SessionManager` helpers

#### `src/api/routes.ts`
- `GET /api/sessions` - List available sessions
- `POST /api/sessions` - Create new session
- `GET /api/sessions/:id` - Get session details
- `POST /api/sessions/:id/fork` - Fork session
- `DELETE /api/sessions/:id` - Delete session
- `GET /api/models` - List available models

#### WebSocket Protocol
- `connection` → server sends current session state
- `client:prompt` → `{ text, sessionId? }`
- `server:event` → `{ type, data }` (mirrors SDK events)
- `client:abort` → abort current turn
- `client:steer` → steer/follow-up during streaming

### Frontend (`apps/oh-my-pi-web/frontend/`)

#### `src/App.tsx`
- Main layout: sidebar + chat area
- Session provider context
- WebSocket connection management

#### `src/components/Chat.tsx`
- Message list with user/assistant distinction
- Streaming text display (markdown rendering)
- Tool execution cards (expandable)
- Input area with send/abort/steer buttons

#### `src/components/SessionList.tsx`
- List of available sessions
- New session button
- Session actions (resume, fork, delete)
- Timestamp and preview

#### `src/components/ToolOutput.tsx`
- Collapsible tool execution display
- Tool name, arguments, result
- Loading state during execution

#### `src/hooks/useSession.ts`
- WebSocket connection management
- Event subscription and state updates
- Prompt sending, aborting, steering
- Session switching

#### `src/hooks/useStreaming.ts`
- Text delta accumulation
- Markdown incremental rendering
- Typing indicator

---

## Data Flow

### Starting a New Chat

1. User clicks "New Session" in sidebar
2. Frontend sends `POST /api/sessions`
3. Backend creates in-memory session manager + SDK session
4. WebSocket connection established
5. Frontend shows empty chat interface

### Sending a Message

1. User types message, clicks send
2. Frontend sends `client:prompt` via WebSocket
3. Backend calls `session.prompt(text)`
4. SDK starts agent turn, emits events
5. Backend forwards events via WebSocket
6. Frontend receives `server:event` messages:
   - `turn_start` → show typing indicator
   - `message_update` with `text_delta` → append to message
   - `tool_execution_start` → show tool card
   - `tool_execution_end` → update tool card with result
   - `turn_end` → hide typing indicator

### Resuming a Session

1. User clicks existing session in sidebar
2. Frontend loads session via `GET /api/sessions/:id`
3. Backend uses `SessionManager.open(path)` to restore
4. WebSocket connection established
5. Frontend displays conversation history

### Session Persistence

- Backend uses `SessionManager.create(cwd)` for file-backed sessions
- Sessions stored in `~/.omp/sessions/` or configured path
- SDK handles persistence automatically
- Backend maintains in-memory map of sessionId → AgentSession

---

## Authentication

Simple bearer token authentication:

```
Authorization: Bearer <TOKEN>
```

- Token configured via `OMP_WEB_TOKEN` environment variable
- Checked on all API routes and WebSocket upgrade
- Tailscale provides network-level security (mTLS)
- Token auth is defense-in-depth

---

## Error Handling

| Error | Behavior |
|-------|----------|
| SDK initialization failure | Log error, return 503 on health check |
| Invalid auth token | Return 401 |
| Session not found | Return 404 |
| Model unavailable | Show fallback message in UI |
| WebSocket disconnect | Auto-reconnect with exponential backoff |
| Stream interruption | Show error, allow retry/resume |

---

## NixOS Integration

### Package

Flake output: `packages.oh-my-pi-web`

- Builds backend with `bun build`
- Builds frontend with `vite build`
- Combines into single derivation

### Service

```nix
services.oh-my-pi-web = {
  enable = true;
  port = 3000;
  dataDir = "/var/lib/oh-my-pi-web";
  environmentFile = config.sops.secrets.oh-my-pi-web-env.path;
};
```

### Tailscale Serve

```nix
services.tailscale.serve = {
  enable = true;
  port = 3000;
};
```

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `OMP_WEB_TOKEN` | Yes | Bearer token for auth |
| `OMP_DATA_DIR` | No | Session storage path (default: `~/.omp/`) |
| `OMP_PORT` | No | Server port (default: 3000) |
| `OMP_MODEL` | No | Default model to use |
| `OMP_THINKING_LEVEL` | No | `none`, `low`, `medium`, `high` |

---

## Future Enhancements (Out of Scope)

- Multi-user support with proper auth
- File attachment/upload
- Custom tool UI rendering
- Settings/configuration UI
- Search across sessions
- Export/import conversations

---

## Acceptance Criteria

- [ ] Can create new chat session
- [ ] Can send messages and receive streaming responses
- [ ] Can see tool execution in real-time
- [ ] Can list and resume previous sessions
- [ ] Can fork sessions
- [ ] Sessions persist across server restarts
- [ ] Works via tailscale serve with HTTPS
- [ ] Protected by bearer token auth
