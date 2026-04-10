# Design: pi-web-ui Enhancements

## Overview

Add provider management, connection testing, and session management to the pi-web-ui application.

## Problem Statement

1. **Auth detection is broken**: Backend reads `auth.json` but pi-ai SDK uses environment variables
2. **No provider management**: Users can't see what's configured, test connections, or add custom providers
3. **No session management**: Users can't start new chats or clear current chat

## Architecture

### Backend Changes

#### ConfigService Enhancement

```typescript
// Environment variable to provider mapping
const ENV_PROVIDER_MAP = {
  'OPENAI_API_KEY': 'openai',
  'ANTHROPIC_API_KEY': 'anthropic',
  'ANTHROPIC_OAUTH_TOKEN': 'anthropic',
  'GEMINI_API_KEY': 'google',
  'GOOGLE_CLOUD_API_KEY': 'google-vertex',
  'GROQ_API_KEY': 'groq',
  'OPENCODE_API_KEY': 'opencode-go',
  'MINIMAX_API_KEY': 'minimax',
  // ... etc
}

// Custom providers storage
interface CustomProvider {
  name: string;
  apiKey: string;
  baseUrl?: string;  // Optional custom endpoint
  models?: string[]; // Optional model list
}

class ConfigService {
  // Existing methods enhanced:
  async loadConfig(): Promise<AgentConfig>
  async getProviders(): Promise<string[]>
  async getDefaultProvider(): Promise<ProviderInfo | null>
  
  // New methods:
  detectEnvProviders(): string[]              // Parse env vars, return ["opencode-go/minimax-m2.7"]
  loadCustomProviders(): CustomProvider[]     // Read from providers.json
  saveCustomProvider(provider: CustomProvider): void
  removeCustomProvider(name: string): void
  testProvider(provider: string, apiKey?: string): Promise<{success: boolean, error?: string}>
}
```

#### Custom Providers Storage

File: `~/.config/pi-web-ui/providers.json`

```json
{
  "providers": [
    {
      "name": "my-openai",
      "apiKey": "sk-...",
      "baseUrl": "https://api.openai.com/v1"
    }
  ]
}
```

#### Provider Testing

Test method makes a minimal API call:
- OpenAI: `POST /chat/completions` with `max_tokens=1`
- Anthropic: `POST /messages` with `max_tokens=1`
- Generic: Detect based on provider type

### API Changes

| Endpoint | Method | Request | Response |
|----------|--------|---------|----------|
| `/api/config` | GET | - | `{providers: [], defaults: null}` |
| `/api/providers` | GET | - | `{env: [], custom: [], all: []}` |
| `/api/providers` | POST | `{name, apiKey, baseUrl?}` | `{success, providers}` |
| `/api/providers/:name` | DELETE | - | `{success, providers}` |
| `/api/providers/test` | POST | `{provider, apiKey?}` | `{success, error?}` |

### Frontend Changes

#### Store (useChatStore)

```typescript
interface ChatState {
  messages: Message[]
  selectedProvider: string | null
  selectedModel: string | null
  isStreaming: boolean
  customProviders: CustomProvider[]
  
  // Actions
  addMessage(role, content)
  appendToLastMessage(chunk)
  setSelectedModel(provider, model)
  setStreaming(streaming)
  clearMessages()          // Clear chat only
  resetSession()           // Clear chat + deselect model
  addCustomProvider(provider)
  removeCustomProvider(name)
}
```

#### Header UI

```
┌─────────────────────────────────────────────────────────────┐
│ [Logo] pi-web-ui              [New Chat] [+ Add Provider] │
└─────────────────────────────────────────────────────────────┘
```

- **New Chat**: Clears messages and deselects model (resetSession)
- **+ Add Provider**: Opens modal to add custom provider

#### Model Selector Enhancement

```
┌─────────────────────────────────────────────┐
│ 🔴 opencode-go / minimax-m2.7           ▼   │
├─────────────────────────────────────────────┤
│ 🔴 opencode-go / minimax-m2.7          [T]  │
│ 🔴 anthropic / claude-sonnet-4-5       [T]  │
│ 🟡 my-openai / gpt-4o                  [T]  │
│ 🟢 custom / ollama (connected)          [T]  │
└─────────────────────────────────────────────┘

Legend:
- 🔴 Red: Env var, not tested
- 🟡 Yellow: Custom, not tested
- 🟢 Green: Tested and working
- [T] = Test button
```

#### Add Provider Modal

```
┌─────────────────────────────────────────────┐
│ Add Custom Provider                    [X]   │
├─────────────────────────────────────────────┤
│ Provider Name:                              │
│ [________________________________]          │
│                                             │
│ API Key:                                    │
│ [________________________________]          │
│                                             │
│ Base URL (optional):                        │
│ [________________________________]          │
│                                             │
│                               [Cancel] [Add] │
└─────────────────────────────────────────────┘
```

## Data Flow

### 1. Initial Load

```
Frontend → GET /api/config
Backend → ConfigService.getProviders()
Backend → Detect env vars + load custom providers
Backend → Merge into provider list
Frontend → Populate dropdown
```

### 2. Test Connection

```
User clicks Test on "opencode-go"
Frontend → POST /api/providers/test {provider: "opencode-go"}
Backend → Get API key from env/custom
Backend → Make test API call
Backend → Return {success: true} or {success: false, error: "..."}
Frontend → Update status icon to green/red
```

### 3. Add Custom Provider

```
User fills modal
Frontend → POST /api/providers {name, apiKey, baseUrl}
Backend → Validate input
Backend → Save to providers.json
Backend → Return updated list
Frontend → Update store, close modal, show in dropdown
```

## Files to Modify

### Backend

| File | Changes |
|------|---------|
| `backend/src/services/ConfigService.ts` | Add env detection, custom providers, test/add/remove |
| `backend/src/controllers/ConfigController.ts` | Add new endpoints |
| `backend/src/config.ts` | Add providers config path |

### Frontend

| File | Changes |
|------|---------|
| `frontend/src/store/useChatStore.ts` | Add resetSession, customProviders |
| `frontend/src/components/ChatPage.tsx` | Add header buttons |
| `frontend/src/components/ModelSelector.tsx` | Add status icons, test buttons |
| `frontend/src/components/AddProviderModal.tsx` | New component |
| `frontend/src/api/apiClient.ts` | Add new API methods |

## Implementation Priority

1. Fix env detection (critical - makes app functional)
2. Provider test endpoint (lets users verify setup)
3. Model selector status icons (visual feedback)
4. New Chat / Clear Chat (session management)
5. Add Custom Provider (modal + endpoints)

## Error Handling

- Env var detection failure: Log warning, continue with empty list
- Provider test failure: Return error message, keep status as failed
- Add provider validation: Require name + apiKey, validate format
- File system errors: Log and return appropriate HTTP status
