# Research Findings: pi-web-ui-integration

**Date:** 2026-04-10  
**Researcher:** Agent Analysis  
**Status:** Complete

---

## Research Question 1: Provider Mapping (pi auth.json → pi-ai)

### Finding ✅

**Provider Names Match:**
- Your `auth.json` has: `github-copilot`
- pi-ai expects: `github-copilot` (built-in provider, NOT custom)
- Status: **Direct mapping works**

**Supported pi-ai providers (built-in):**
- `anthropic` (Claude)
- `openai` (GPT, o-series)
- `google` (Gemini)
- `github-copilot` (native support)
- `groq`, `cerebras`, `xai`, `openrouter` (others)

**No translation layer needed.** The provider ID in `auth.json` directly matches pi-ai's `getModel(provider, modelId)` function.

### Implementation Impact

**In ConfigLoader:**
```typescript
const providers = Object.keys(auth);  // ["github-copilot"]
// No mapping needed - use keys directly
```

**In ChatAPI:**
```typescript
const model = getModel(provider, modelId);
// provider = "github-copilot" works directly
const apiKey = (await getOAuthApiKey(provider, credentials)).apiKey;
```

### Decision

✅ **No provider mapping logic needed.** Use provider names as-is from `auth.json`.

---

## Research Question 2: Token Expiration & Refresh Handling

### Finding ✅

**pi-ai provides automatic refresh via `getOAuthApiKey()`:**
```typescript
// Before each stream() call:
const { newCredentials, apiKey } = await getOAuthApiKey(
  provider,
  storedCredentials
);
// Returns newCredentials if refreshed
// Returns apiKey ready for stream()
```

**Behavior:**
- Checks `credentials.expires` timestamp
- Automatically refreshes if expired
- Returns new credentials (which may have updated `access`, `refresh`, `expires`)
- Throws if refresh fails → re-authentication needed

**auth.json structure:**
- `access`: OAuth token string
- `refresh`: Refresh token (may be reused or rotate)
- `expires`: Unix timestamp in milliseconds

### Implementation Pattern

**Required flow:**
1. Load credentials from `~/.pi/agent/auth.json`
2. Call `getOAuthApiKey(provider, credentials)` BEFORE each stream
3. Persist `newCredentials` back to auth.json (credentials may have rotated)
4. Use returned `apiKey` in stream call

### Error Handling

- If `getOAuthApiKey()` throws → Token refresh failed → Need re-authentication
- Return 401 error to frontend with message like: "Provider {provider} token expired. Please re-authenticate via pi CLI: `pi /login`"

### Implementation Impact

**In ConfigLoader:**
```typescript
async refreshAndGetApiKey(provider: string): Promise<string> {
  const creds = auth[provider];
  const { newCredentials, apiKey } = await getOAuthApiKey(provider, creds);
  
  // IMPORTANT: Save refreshed credentials
  auth[provider] = newCredentials;
  saveAuthJson(auth);
  
  return apiKey;
}
```

### Decision

✅ **pi-ai handles refresh automatically.** We call `getOAuthApiKey()` before each stream, save updated credentials, and handle 401 gracefully.

---

## Research Question 3: Streaming Protocol Normalization

### Finding ✅

**pi-ai ALREADY normalizes streaming across all providers:**

pi-ai `stream()` emits unified events:
- `text_delta` → Partial text content
- `thinking_delta` → Reasoning/thinking output
- `toolcall_delta` → Partial tool call
- `text_start`, `text_end`, `toolcall_start`, `toolcall_end` → Lifecycle events
- `done` → Streaming complete
- `error` → Error occurred

**No provider-specific handling needed.** pi-ai abstracts:
- Anthropic's `content_block_delta` 
- OpenAI's `delta` with `choices`
- Google Gemini's streaming format
- All normalized to pi-ai's unified event model

### Implementation Impact

**In ChatAPI streaming:**
```typescript
for await (const event of stream(model, context, { apiKey })) {
  switch (event.type) {
    case "text_delta":
      // Send to frontend
      res.write(JSON.stringify({ type: "text", delta: event.delta }));
      break;
    case "done":
      res.end();
      break;
    // ... other events
  }
}
```

**Frontend receives normalized events**, regardless of provider.

### Decision

✅ **No provider-specific handling needed.** Use pi-ai's normalized stream events directly. Frontend treats all providers identically.

---

## Implementation Checklist

### ConfigLoader (auth.json parsing)
- ✅ No provider name mapping needed
- ✅ Parse OAuth expiration from `credentials.expires`
- ✅ Add `getOAuthApiKey()` call with auto-refresh
- ✅ Persist updated credentials back to auth.json

### ChatAPI (stream handling)
- ✅ Call `getOAuthApiKey()` before stream
- ✅ Catch token refresh errors → 401 response
- ✅ Forward pi-ai's normalized stream events to frontend
- ✅ No provider-specific response handling

### Frontend (message streaming)
- ✅ Handle `text_delta` events uniformly
- ✅ Handle `thinking_delta` if model supports it
- ✅ Display loading state for all providers identically

---

## Summary

| Gap | Finding | Action |
|-----|---------|--------|
| Provider Mapping | No translation needed; pi-ai uses names as-is | Use provider IDs directly |
| Token Refresh | pi-ai handles automatically via `getOAuthApiKey()` | Call before each stream, save new credentials |
| Streaming Format | pi-ai normalizes all providers to unified events | No provider-specific logic needed |

**Conclusion:** All 3 gaps are **resolved by design** in pi-ai. The library handles the complexity; we just need to use it correctly.

---

## No Design Blockers

✅ **Spec is ready for design phase.** Research confirms architecture is sound and pi-ai provides all necessary abstractions.

**Recommended Design Phase Actions:**
1. Map pi-ai concepts into component interfaces
2. Define error handling for token refresh failures
3. Design session/message storage (out of scope for MVP, but note in design)
4. Create sequence diagrams for auth refresh + streaming flows
