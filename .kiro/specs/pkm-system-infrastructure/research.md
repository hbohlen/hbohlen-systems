# Research Log: pkm-system-infrastructure

**Date:** 2026-04-08  
**Feature:** pkm-system-infrastructure  
**Language:** en

## Summary

Research focused on building a simple web UI for Mnemosyne PKM system using pi-mono packages. Key findings:

1. **pi-ai package** provides unified LLM API with 15+ providers - direct use is optimal
2. **OAuth token handling** from auth.json requires understanding pi's auth structure
3. **Hono framework** is lightweight and well-suited for simple Node.js server

## Research Log

### Topic 1: pi-ai Package Integration

**Investigation:** How to use @mariozechner/pi-ai for LLM calls

**Sources:**
- https://github.com/badlogic/pi-mono/tree/main/packages/ai (README.md)
- https://github.com/badlogic/pi-mono/tree/main/packages/agent (Agent runtime)

**Findings:**
- `getModel(provider, modelId)` returns typed model
- `stream(model, context)` and `complete(model, context)` for LLM calls
- Context includes: systemPrompt, messages[], tools[]
- Supports all major providers: Anthropic, OpenAI, Google, GitHub Copilot, etc.

**Implications:** Direct use of pi-ai is straightforward; no need for RPC layer

---

### Topic 2: OAuth Token Handling from auth.json

**Investigation:** How pi stores OAuth tokens and how to use them

**Sources:**
- /home/hbohlen/.pi/agent/auth.json (actual config)
- /home/hbohlen/.pi/agent/settings.json

**Findings:**
- auth.json contains provider objects with: type ("oauth"), access, refresh, expires
- Providers in user's config: github-copilot, google-antigravity, qwen-cli
- Access token used directly as Bearer token for API calls

**Implications:** Server must read auth.json, extract provider tokens, pass to pi-ai

---

### Topic 3: Web Framework Selection

**Investigation:** Hono vs Express for simple server

**Sources:**
- https://hono.dev (official docs)

**Findings:**
- Hono: lightweight (no deps), fast, TypeScript-first, works with Bun/Node/Deno
- Similar API to Express but with better TypeScript support
- Built-in middleware for: cors, streaming, static files

**Implications:** Hono is ideal for this use case - simple, fast, TypeScript-native

---

## Architecture Pattern Evaluation

**Option A: Direct pi-ai calls (Selected)**
- Pros: Simple, direct use of pi packages, no additional complexity
- Cons: Server must handle token refresh

**Option B: pi-coding-agent RPC mode**
- Pros: Leverages existing tool infrastructure
- Cons: More complex, less flexible for custom UI

**Decision:** Use direct pi-ai calls for simplicity and flexibility

---

## Key Decisions

1. **Stack**: Node.js + Hono + pi-ai + plain HTML/CSS/JS
2. **Auth**: Read from ~/.pi/agent/auth.json at startup
3. **Provider mapping**: Map pi provider names to pi-ai provider IDs
4. **UI**: Simple chat interface with model selector dropdown

---

## Risks and Mitigations

1. **Risk**: OAuth token expiration
   - Mitigation: Check expires timestamp, warn user if expired

2. **Risk**: Provider not in auth.json
   - Mitigation: Show clear error, prompt to add provider via pi CLI

3. **Risk**: Streaming response handling
   - Mitigation: Use Hono's stream() helper, handle chunked responses

---

## Parallelization Considerations

- Frontend (HTML/CSS) can be developed independently from backend
- Config loaders (auth.ts, settings.ts) are independent of chat API
- Future: Tool calling, session persistence are separate workstreams