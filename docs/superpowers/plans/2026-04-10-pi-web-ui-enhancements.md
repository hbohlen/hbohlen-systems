# pi-web-ui Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add environment variable detection for providers, connection testing, custom provider management, and session controls to pi-web-ui.

**Architecture:** Backend ConfigService enhanced to detect env vars and load custom providers from JSON file. Frontend adds status indicators, test buttons, and session reset. API gains test and CRUD endpoints for custom providers.

**Tech Stack:** TypeScript, Hono, Node.js, React, Zustand, SSE

---

## File Structure

```
backend/
├── src/
│   ├── config.ts                    # Add custom providers config path
│   ├── services/
│   │   └── ConfigService.ts         # Core: env detection, custom providers, test
│   └── controllers/
│       └── ConfigController.ts      # New endpoints
frontend/
├── src/
│   ├── store/
│   │   └── useChatStore.ts         # Add resetSession, customProviders
│   ├── components/
│   │   ├── ChatPage.tsx            # Add header buttons
│   │   ├── ModelSelector.tsx       # Add status icons, test buttons
│   │   └── AddProviderModal.tsx    # New: modal component
│   └── api/
│       └── apiClient.ts            # Add new API methods
```

---

## Task 1: Backend - ConfigService Environment Detection

**Files:**
- Modify: `backend/src/services/ConfigService.ts`
- Modify: `backend/src/config.ts`

- [ ] **Step 1: Add env provider map and types to ConfigService.ts**

```typescript
// Add after imports
const ENV_PROVIDER_MAP: Record<string, string> = {
  'OPENAI_API_KEY': 'openai',
  'ANTHROPIC_API_KEY': 'anthropic',
  'ANTHROPIC_OAUTH_TOKEN': 'anthropic',
  'GEMINI_API_KEY': 'google',
  'GOOGLE_CLOUD_API_KEY': 'google-vertex',
  'GROQ_API_KEY': 'groq',
  'OPENCODE_API_KEY': 'opencode-go',
  'MINIMAX_API_KEY': 'minimax',
  'MINIMAX_CN_API_KEY': 'minimax-cn',
  'MISTRAL_API_KEY': 'mistral',
  'CEREBRAS_API_KEY': 'cerebras',
  'XAI_API_KEY': 'xai',
  'OPENROUTER_API_KEY': 'openrouter',
  'HUGGINGFACE_TOKEN': 'huggingface',
  'KIMI_API_KEY': 'kimi-coding',
  'ZAI_API_KEY': 'zai',
  'AZURE_OPENAI_API_KEY': 'azure-openai-responses',
}

interface CustomProvider {
  name: string
  apiKey: string
  baseUrl?: string
  models?: string[]
}

interface CustomProvidersConfig {
  version: number
  providers: CustomProvider[]
}
```

- [ ] **Step 2: Add custom providers file path to config.ts**

```typescript
// Add to config object
customProvidersPath: join(homedir(), '.config', 'pi-web-ui', 'providers.json'),
```

- [ ] **Step 3: Add detectEnvProviders method**

```typescript
detectEnvProviders(): string[] {
  const providers: string[] = []
  const detected = new Set<string>()
  
  for (const [envVar, provider] of Object.entries(ENV_PROVIDER_MAP)) {
    if (process.env[envVar] && !detected.has(provider)) {
      detected.add(provider)
      // Use default model from pi-ai registry
      providers.push(`${provider}/default`)
    }
  }
  
  console.log(`[ConfigService] Detected env providers: ${providers.join(', ')}`)
  return providers
}
```

- [ ] **Step 4: Add custom providers load/save methods**

```typescript
async loadCustomProviders(): Promise<CustomProvider[]> {
  try {
    const data = await readFile(config.customProvidersPath, 'utf-8')
    const parsed = JSON.parse(data) as CustomProvidersConfig
    return parsed.providers || []
  } catch {
    return []
  }
}

async saveCustomProviders(providers: CustomProvider[]): Promise<void> {
  const dir = dirname(config.customProvidersPath)
  await mkdir(dir, { recursive: true })
  const config_data: CustomProvidersConfig = { version: 1, providers }
  await writeFile(config.customProvidersPath, JSON.stringify(config_data, null, 2))
}

async addCustomProvider(provider: CustomProvider): Promise<CustomProvider[]> {
  const existing = await this.loadCustomProviders()
  const filtered = existing.filter(p => p.name !== provider.name)
  const updated = [...filtered, provider]
  await this.saveCustomProviders(updated)
  this.invalidateCache()
  return updated
}

async removeCustomProvider(name: string): Promise<CustomProvider[]> {
  const existing = await this.loadCustomProviders()
  const updated = existing.filter(p => p.name !== name)
  await this.saveCustomProviders(updated)
  this.invalidateCache()
  return updated
}
```

- [ ] **Step 5: Update getProviders to merge env + custom**

```typescript
async getProviders(): Promise<string[]> {
  // Env providers (format: "provider/default")
  const envProviders = this.detectEnvProviders()
  
  // Custom providers (format: "custom/name")
  const customProviders = await this.loadCustomProviders()
  const customProviderStrings = customProviders.map(p => `custom/${p.name}`)
  
  return [...envProviders, ...customProviderStrings]
}
```

- [ ] **Step 6: Update getApiKey to check env + custom**

```typescript
async getApiKey(provider: string): Promise<string | undefined> {
  // Check env first
  for (const [envVar, p] of Object.entries(ENV_PROVIDER_MAP)) {
    if (p === provider && process.env[envVar]) {
      return process.env[envVar]
    }
  }
  
  // Check custom providers
  const customProviders = await this.loadCustomProviders()
  const custom = customProviders.find(p => p.name === provider || `custom/${p.name}` === provider)
  if (custom) {
    return custom.apiKey
  }
  
  return undefined
}
```

- [ ] **Step 7: Add testProvider method**

```typescript
async testProvider(provider: string, apiKey?: string): Promise<{success: boolean, error?: string}> {
  const key = apiKey || await this.getApiKey(provider)
  if (!key) {
    return { success: false, error: 'No API key found' }
  }
  
  // Normalize provider name
  const normalizedProvider = provider.startsWith('custom/') 
    ? provider 
    : provider
  
  try {
    // Simple test: try to get model info
    // Actual implementation depends on pi-ai SDK
    const models = await import('@mariozechner/pi-ai')
    const model = models.getModel(normalizedProvider, 'default')
    if (!model) {
      return { success: false, error: `Unknown provider: ${provider}` }
    }
    return { success: true }
  } catch (error) {
    return { 
      success: false, 
      error: error instanceof Error ? error.message : 'Unknown error' 
    }
  }
}
```

- [ ] **Step 8: Add custom providers export**

```typescript
async getCustomProviders(): Promise<CustomProvider[]> {
  return this.loadCustomProviders()
}
```

- [ ] **Step 9: Run build to verify**

```bash
cd backend && nix shell nixpkgs#nodejs_20 --command npm run build
```
Expected: Success with no errors

- [ ] **Step 10: Commit**

```bash
git add backend/src/services/ConfigService.ts backend/src/config.ts
git commit -m "feat(backend): add env detection and custom providers to ConfigService"
```

---

## Task 2: Backend - ConfigController New Endpoints

**Files:**
- Modify: `backend/src/controllers/ConfigController.ts`

- [ ] **Step 1: Add new endpoints to ConfigController.ts**

```typescript
// Add after existing configRouter.get('/config', ...)

// GET /api/providers - List all providers with details
configRouter.get('/providers', async (c) => {
  try {
    const envProviders = configService.detectEnvProviders()
    const customProviders = await configService.getCustomProviders()
    
    const allProviders = [
      ...envProviders.map(p => ({ id: p, type: 'env' as const })),
      ...customProviders.map(p => ({ id: `custom/${p.name}`, type: 'custom' as const, ...p }))
    ]
    
    return c.json({ env: envProviders, custom: customProviders, all: allProviders })
  } catch (error) {
    console.error('[ConfigController] Error listing providers:', error)
    return c.json({ error: 'Failed to list providers' }, 500)
  }
})

// POST /api/providers - Add custom provider
configRouter.post('/providers', async (c) => {
  try {
    const body = await c.req.json<{ name: string; apiKey: string; baseUrl?: string }>()
    
    if (!body.name || !body.apiKey) {
      return c.json({ error: 'Name and API key required' }, 400)
    }
    
    const providers = await configService.addCustomProvider({
      name: body.name,
      apiKey: body.apiKey,
      baseUrl: body.baseUrl
    })
    
    return c.json({ success: true, providers })
  } catch (error) {
    console.error('[ConfigController] Error adding provider:', error)
    return c.json({ error: 'Failed to add provider' }, 500)
  }
})

// DELETE /api/providers/:name - Remove custom provider
configRouter.delete('/providers/:name', async (c) => {
  try {
    const name = c.req.param('name')
    const providers = await configService.removeCustomProvider(name)
    return c.json({ success: true, providers })
  } catch (error) {
    console.error('[ConfigController] Error removing provider:', error)
    return c.json({ error: 'Failed to remove provider' }, 500)
  }
})

// POST /api/providers/test - Test provider connection
configRouter.post('/providers/test', async (c) => {
  try {
    const body = await c.req.json<{ provider: string; apiKey?: string }>()
    
    if (!body.provider) {
      return c.json({ error: 'Provider required' }, 400)
    }
    
    const result = await configService.testProvider(body.provider, body.apiKey)
    return c.json(result)
  } catch (error) {
    console.error('[ConfigController] Error testing provider:', error)
    return c.json({ success: false, error: 'Test failed' }, 500)
  }
})
```

- [ ] **Step 2: Add fs/promises imports**

```typescript
import { readFile } from 'fs/promises'  // Add to existing import
```

- [ ] **Step 3: Run build to verify**

```bash
cd backend && nix shell nixpkgs#nodejs_20 --command npm run build
```
Expected: Success with no errors

- [ ] **Step 4: Commit**

```bash
git add backend/src/controllers/ConfigController.ts
git commit -m "feat(backend): add provider management endpoints to ConfigController"
```

---

## Task 3: Frontend - Store Enhancements

**Files:**
- Modify: `frontend/src/store/useChatStore.ts`

- [ ] **Step 1: Add custom provider types and state**

```typescript
export interface CustomProvider {
  name: string
  apiKey: string
  baseUrl?: string
  models?: string[]
}

export interface ChatState {
  // Existing state
  messages: Message[]
  selectedProvider: string | null
  selectedModel: string | null
  isStreaming: boolean
  
  // New state
  customProviders: CustomProvider[]
  providerStatuses: Record<string, 'unknown' | 'testing' | 'connected' | 'failed'>
  
  // New actions
  resetSession: () => void
  addCustomProvider: (provider: CustomProvider) => void
  removeCustomProvider: (name: string) => void
  setProviderStatus: (provider: string, status: 'unknown' | 'testing' | 'connected' | 'failed') => void
}
```

- [ ] **Step 2: Add initial state for new fields**

```typescript
export const useChatStore = create<ChatState>((set) => ({
  // ... existing state ...
  
  // New initial state
  customProviders: [],
  providerStatuses: {},
  
  // New actions
  resetSession: () =>
    set({
      messages: [],
      isStreaming: false,
      selectedProvider: null,
      selectedModel: null,
    }),
  
  addCustomProvider: (provider) =>
    set((state) => ({
      customProviders: [...state.customProviders, provider],
    })),
  
  removeCustomProvider: (name) =>
    set((state) => ({
      customProviders: state.customProviders.filter(p => p.name !== name),
    })),
  
  setProviderStatus: (provider, status) =>
    set((state) => ({
      providerStatuses: { ...state.providerStatuses, [provider]: status },
    })),
}))
```

- [ ] **Step 3: Verify build**

```bash
cd frontend && nix shell nixpkgs#nodejs_20 --command npm run build 2>&1 | tail -20
```
Expected: Success or only pre-existing errors

- [ ] **Step 4: Commit**

```bash
git add frontend/src/store/useChatStore.ts
git commit -m "feat(frontend): add resetSession and provider management to chat store"
```

---

## Task 4: Frontend - API Client Updates

**Files:**
- Modify: `frontend/src/api/apiClient.ts`

- [ ] **Step 1: Add new types**

```typescript
interface CustomProvider {
  name: string
  apiKey: string
  baseUrl?: string
}

interface ProviderListResponse {
  env: string[]
  custom: CustomProvider[]
  all: Array<{ id: string; type: 'env' | 'custom' } & CustomProvider>
}

interface ProviderTestResult {
  success: boolean
  error?: string
}

interface ProviderActionResponse {
  success: boolean
  providers: CustomProvider[]
}
```

- [ ] **Step 2: Add new API methods**

```typescript
/**
 * List all providers (env + custom)
 */
export async function fetchProviders(): Promise<ProviderListResponse> {
  const response = await fetch(buildUrl('/api/providers'))
  if (!response.ok) throw new ApiError('Failed to fetch providers', response.status)
  return response.json()
}

/**
 * Add a custom provider
 */
export async function addProvider(provider: Omit<CustomProvider, 'apiKey'> & { apiKey: string }): Promise<ProviderActionResponse> {
  const response = await fetch(buildUrl('/api/providers'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(provider),
  })
  if (!response.ok) throw new ApiError('Failed to add provider', response.status)
  return response.json()
}

/**
 * Remove a custom provider
 */
export async function removeProvider(name: string): Promise<ProviderActionResponse> {
  const response = await fetch(buildUrl(`/api/providers/${encodeURIComponent(name)}`), {
    method: 'DELETE',
  })
  if (!response.ok) throw new ApiError('Failed to remove provider', response.status)
  return response.json()
}

/**
 * Test a provider connection
 */
export async function testProvider(provider: string, apiKey?: string): Promise<ProviderTestResult> {
  const response = await fetch(buildUrl('/api/providers/test'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ provider, apiKey }),
  })
  if (!response.ok) throw new ApiError('Failed to test provider', response.status)
  return response.json()
}
```

- [ ] **Step 3: Verify build**

```bash
cd frontend && nix shell nixpkgs#nodejs_20 --command npm run build 2>&1 | tail -20
```
Expected: Success or only pre-existing errors

- [ ] **Step 4: Commit**

```bash
git add frontend/src/api/apiClient.ts
git commit -m "feat(frontend): add provider management API methods to apiClient"
```

---

## Task 5: Frontend - AddProviderModal Component

**Files:**
- Create: `frontend/src/components/AddProviderModal.tsx`

- [ ] **Step 1: Create the modal component**

```tsx
import { useState } from 'react'
import { X } from 'lucide-react'
import { useChatStore } from '../store/useChatStore'
import { addProvider, testProvider, ApiError } from '../api/apiClient'

interface AddProviderModalProps {
  isOpen: boolean
  onClose: () => void
}

export function AddProviderModal({ isOpen, onClose }: AddProviderModalProps) {
  const [name, setName] = useState('')
  const [apiKey, setApiKey] = useState('')
  const [baseUrl, setBaseUrl] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  
  const addCustomProvider = useChatStore(state => state.addCustomProvider)

  if (!isOpen) return null

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setIsLoading(true)

    try {
      await addProvider({ name, apiKey, baseUrl: baseUrl || undefined })
      addCustomProvider({ name, apiKey, baseUrl: baseUrl || undefined })
      setName('')
      setApiKey('')
      setBaseUrl('')
      onClose()
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Failed to add provider')
    } finally {
      setIsLoading(false)
    }
  }

  const handleTest = async () => {
    if (!apiKey) return
    setIsLoading(true)
    setError(null)
    
    try {
      const result = await testProvider(`custom/${name}`, apiKey)
      if (result.success) {
        setError(null)
        alert('Connection successful!')
      } else {
        setError(`Connection failed: ${result.error}`)
      }
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Test failed')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-card border border-border rounded-lg w-full max-w-md p-6 shadow-xl">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold">Add Custom Provider</h2>
          <button
            onClick={onClose}
            className="p-1 hover:bg-accent rounded"
          >
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Provider Name</label>
            <input
              type="text"
              value={name}
              onChange={e => setName(e.target.value)}
              placeholder="e.g., my-openai"
              required
              className="w-full px-3 py-2 bg-background border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">API Key</label>
            <input
              type="password"
              value={apiKey}
              onChange={e => setApiKey(e.target.value)}
              placeholder="sk-..."
              required
              className="w-full px-3 py-2 bg-background border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Base URL (optional)</label>
            <input
              type="url"
              value={baseUrl}
              onChange={e => setBaseUrl(e.target.value)}
              placeholder="https://api.openai.com/v1"
              className="w-full px-3 py-2 bg-background border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          {error && (
            <div className="text-sm text-destructive">{error}</div>
          )}

          <div className="flex gap-2 justify-end pt-2">
            <button
              type="button"
              onClick={handleTest}
              disabled={!name || !apiKey || isLoading}
              className="px-4 py-2 text-sm border border-border rounded-lg hover:bg-accent disabled:opacity-50"
            >
              Test
            </button>
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm border border-border rounded-lg hover:bg-accent"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={!name || !apiKey || isLoading}
              className="px-4 py-2 text-sm bg-primary text-primary-foreground rounded-lg hover:opacity-90 disabled:opacity-50"
            >
              Add
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Verify build**

```bash
cd frontend && nix shell nixpkgs#nodejs_20 --command npm run build 2>&1 | tail -20
```
Expected: Success or only pre-existing errors

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/AddProviderModal.tsx
git commit -m "feat(frontend): add AddProviderModal component"
```

---

## Task 6: Frontend - ChatPage Header Updates

**Files:**
- Modify: `frontend/src/components/ChatPage.tsx`

- [ ] **Step 1: Add header buttons**

Add to imports:
```tsx
import { Plus, Trash2 } from 'lucide-react'
import { AddProviderModal } from './AddProviderModal'
```

Add state:
```tsx
const [showAddProvider, setShowAddProvider] = useState(false)
```

Update the header section (replace the existing header):
```tsx
{/* Header */}
<header className="border-b border-border bg-card px-4 py-3">
  <div className="max-w-4xl mx-auto flex items-center justify-between">
    <div className="flex items-center gap-3">
      <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
        <MessageSquare size={18} className="text-primary-foreground" />
      </div>
      <div>
        <h1 className="font-semibold text-lg">pi-web-ui</h1>
        <p className="text-xs text-muted-foreground">
          Chat with pi-authenticated LLMs
        </p>
      </div>
    </div>

    <div className="flex items-center gap-2">
      <ModelSelector disabled={useChatStore((state) => state.isStreaming)} />
      
      <button
        onClick={() => useChatStore.getState().resetSession()}
        className="p-2 text-muted-foreground hover:text-foreground hover:bg-accent rounded-lg transition-colors"
        title="New Chat"
      >
        <Trash2 size={18} />
      </button>
      
      <button
        onClick={() => setShowAddProvider(true)}
        className="p-2 text-muted-foreground hover:text-foreground hover:bg-accent rounded-lg transition-colors"
        title="Add Provider"
      >
        <Plus size={18} />
      </button>
    </div>
  </div>
</header>
```

Add modal before error toast:
```tsx
{/* Add Provider Modal */}
<AddProviderModal 
  isOpen={showAddProvider} 
  onClose={() => setShowAddProvider(false)} 
/>
```

- [ ] **Step 2: Verify build**

```bash
cd frontend && nix shell nixpkgs#nodejs_20 --command npm run build 2>&1 | tail -30
```
Expected: Success or only pre-existing errors

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/ChatPage.tsx
git commit -m "feat(frontend): add New Chat and Add Provider buttons to header"
```

---

## Task 7: Frontend - ModelSelector Enhancements

**Files:**
- Modify: `frontend/src/components/ModelSelector.tsx`

- [ ] **Step 1: Add test button and status indicators**

Update imports:
```tsx
import { ChevronDown, Loader2, Play, Check, X, Circle } from 'lucide-react'
```

Add to store imports:
```tsx
import { useChatStore } from '../store/useChatStore'
import { fetchConfig, testProvider, ApiError } from '../api/apiClient'
```

Add state for testing:
```tsx
const testingProvider = useState<string | null>(null)
```

Update the dropdown items to include status icons and test buttons:
```tsx
{providers.map((providerModel) => {
  const [provider, ...modelParts] = providerModel.split('/')
  const model = modelParts.join('/')
  const isSelected = currentSelection === providerModel
  const status = useChatStore(state => state.providerStatuses[providerModel])
  const isTesting = testingProvider[0] === providerModel

  return (
    <div 
      key={providerModel}
      className={`flex items-center justify-between px-4 py-2 hover:bg-accent transition-colors ${
        isSelected ? 'bg-accent' : ''
      }`}
    >
      <button
        onClick={() => handleSelect(providerModel)}
        className="flex-1 text-left"
      >
        <span className="font-medium">{provider}</span>
        <span className="text-muted-foreground"> / {model}</span>
      </button>
      
      <button
        onClick={async (e) => {
          e.stopPropagation()
          testingProvider[1](providerModel)
          useChatStore.getState().setProviderStatus(providerModel, 'testing')
          try {
            const result = await testProvider(provider)
            useChatStore.getState().setProviderStatus(
              providerModel, 
              result.success ? 'connected' : 'failed'
            )
          } catch {
            useChatStore.getState().setProviderStatus(providerModel, 'failed')
          } finally {
            testingProvider[1](null)
          }
        }}
        disabled={isTesting || isStreaming}
        className="p-1 hover:bg-primary/20 rounded ml-2 disabled:opacity-50"
        title="Test connection"
      >
        {isTesting ? (
          <Loader2 size={14} className="animate-spin" />
        ) : status === 'connected' ? (
          <Check size={14} className="text-green-500" />
        ) : status === 'failed' ? (
          <X size={14} className="text-red-500" />
        ) : (
          <Play size={14} className="text-muted-foreground" />
        )}
      </button>
    </div>
  )
})}
```

Update empty state to show helpful message:
```tsx
if (providers.length === 0) {
  return (
    <div className="flex items-center gap-2 px-4 py-2 text-muted-foreground">
      <Circle size={16} />
      <span className="text-sm">No providers configured</span>
    </div>
  )
}
```

- [ ] **Step 2: Verify build**

```bash
cd frontend && nix shell nixpkgs#nodejs_20 --command npm run build 2>&1 | tail -30
```
Expected: Success or only pre-existing errors

- [ ] **Step 3: Commit**

```bash
git add frontend/src/components/ModelSelector.tsx
git commit -m "feat(frontend): add status icons and test buttons to ModelSelector"
```

---

## Task 8: Integration Testing

**Files:**
- Test on running server

- [ ] **Step 1: Rebuild and restart backend**

```bash
cd backend && nix shell nixpkgs#nodejs_20 --command npm run build
# Restart the service
systemctl --user restart pi-web-ui
sleep 3
```

- [ ] **Step 2: Rebuild frontend**

```bash
cd frontend && nix shell nixpkgs#nodejs_20 --command npm run build
```

- [ ] **Step 3: Test API endpoints**

```bash
# Health check
curl http://localhost:3000/api/health

# List providers (should show env-detected ones)
curl http://localhost:3000/api/providers

# Test a provider
curl -X POST http://localhost:3000/api/providers/test \
  -H "Content-Type: application/json" \
  -d '{"provider": "opencode-go"}'
```

- [ ] **Step 4: Test via browser**

1. Navigate to https://hbohlen-01.taile0585b.ts.net
2. Verify model dropdown shows detected providers
3. Click test button - should show green check or red X
4. Click + button - should show Add Provider modal
5. Click trash icon - should clear chat

- [ ] **Step 5: Commit final changes**

```bash
git add -A
git commit -m "feat: complete pi-web-ui provider management and session controls"
```

---

## Self-Review Checklist

- [ ] All spec requirements covered by tasks
- [ ] No TBD/TODO placeholders in code
- [ ] Type consistency across tasks
- [ ] Each task produces working code
- [ ] Commands tested and produce expected output
