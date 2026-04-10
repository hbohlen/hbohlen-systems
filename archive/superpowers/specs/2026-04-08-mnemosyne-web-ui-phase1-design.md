# Mnemosyne Web UI - Phase 1 Design

**Date:** 2026-04-08  
**Feature:** pkm-system-infrastructure  
**Phase:** Design

## 1. Overview

Build a simple web-based chat interface for Mnemosyne that reads authentication and settings from the local pi configuration (`~/.pi/agent/`). This is the first phase - a minimal viable chat UI with model selection.

## 2. Tech Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Runtime | Node.js | Native access to filesystem for pi config |
| Framework | Hono | Lightweight, fast, TypeScript-first |
| UI | Plain HTML/CSS/JS | Simple, minimal, no build complexity |
| LLM SDK | @mariozechner/pi-ai | Direct use of pi packages for API calls |
| Config | Read from `~/.pi/agent/` | Reuse existing pi auth and settings |

## 3. Architecture

```
┌─────────────┐     Tailscale      ┌─────────────────┐
│  Browser    │ ──────────────────> │   Node.js       │
│  (Chat UI)  │ <────────────────── │   Server        │
└─────────────┘                     │   - Hono        │
                                     │   - pi-ai       │
                                     │   - Config      │
                                     └─────────────────┘
                                            │
                                     ┌──────┴──────┐
                                     │ ~/.pi/agent │
                                     │ - auth.json │
                                     │ - settings  │
                                     └─────────────┘
```

## 4. Components

### 4.1 Server (`src/index.ts`)
- HTTP server on configurable port (default: 3000)
- Serves static UI files
- Provides `/api/chat` endpoint for LLM calls
- Reads pi config on startup

### 4.2 Auth Loader (`src/auth.ts`)
- Reads `~/.pi/agent/auth.json`
- Parses OAuth tokens and API keys
- Extracts provider-specific credentials
- Exposes: `getProviders()`, `getAuth(provider)`

### 4.3 Settings Loader (`src/settings.ts`)
- Reads `~/.pi/agent/settings.json`
- Extracts default provider and model
- Exposes: `getDefaults()`, `getProvider()`

### 4.4 Chat API (`src/api/chat.ts`)
- POST endpoint `/api/chat`
- Request: `{ messages: [], model: string, provider: string }`
- Uses `@mariozechner/pi-ai` to call LLM
- Streams response back to client

### 4.5 Web UI (`src/ui/index.html`)
- Simple chat interface
- Message list (scrollable)
- Input field (multiline support)
- Model selector dropdown
- Send button

## 5. Data Flow

1. **Startup**: Server loads auth.json and settings.json
2. **Page Load**: Browser fetches UI, server sends configured providers
3. **Model Selection**: User picks from available providers (from auth.json)
4. **Send Message**: POST to `/api/chat` with message + model
5. **LLM Call**: Server uses pi-ai with credentials from auth.json
6. **Response**: Server streams response to browser

## 6. Security

- Access via Tailscale only (Caddy handles this at network level)
- No API keys exposed to browser - all LLM calls are server-side
- Credentials stay in pi's existing auth.json

## 7. Phase 1 Scope

**In Scope:**
- Simple chat interface (messages + input)
- Model selector showing configured providers
- Message send/receive
- Streaming responses
- Dark theme

**Out of Scope (Future):**
- Session persistence
- Tool calling
- File attachments
- Knowledge base integration

## 8. Acceptance Criteria

1. Server starts and reads pi config successfully
2. Web UI loads with model selector showing available providers
3. User can send a message and receive a response
4. Response streams in real-time
5. Server handles errors gracefully (invalid API key, etc.)

## 9. Deployment

- Add to Home Manager user services or NixOS systemd
- Caddy reverse proxy handles Tailscale-only access
- Config path: `~/.pi/agent/` (read from user's home)