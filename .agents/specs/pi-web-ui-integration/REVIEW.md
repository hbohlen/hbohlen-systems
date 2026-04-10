# Pi Web UI Integration — Requirements Review

## ✅ Spec Created

**Location:** `.agents/specs/pi-web-ui-integration/`

**Phase:** requirements-generated (awaiting approval)

---

## Summary of Requirements

### 10 Requirements Across 3 Domains:

**Frontend (Reqs 1–3):**
- ✅ Chat interface with message history
- ✅ Model selector dropdown (populated from config)
- ✅ Message sending + real-time streaming responses

**Backend (Reqs 4–7):**
- ✅ Read auth.json on startup
- ✅ Serve frontend static files
- ✅ `/api/config` endpoint (list models)
- ✅ `/api/chat` endpoint (stream responses via pi-ai)

**Infrastructure & Integration (Reqs 8–10):**
- ✅ Tailscale-only access (via Caddy)
- ✅ Tech stack: React + Vite + TS / Node + Hono + TS
- ✅ Error handling + user feedback

---

## Tech Stack Specified

| Layer | Tech | Role |
|-------|------|------|
| Frontend | React + Vite + TypeScript | Chat UI |
| Backend | Node.js + Hono + TypeScript | HTTP server |
| LLM | @mariozechner/pi-ai | Provider abstraction |
| Auth | ~/.pi/agent/auth.json | Credentials |
| Network | Caddy + Tailscale | Access control |

---

## Scope (MVP)

✅ **Included:**
- Chat-only UI
- Model selection
- Streaming responses
- All authenticated providers from auth.json

❌ **Deferred to Phase 2+:**
- Session persistence
- Tool calling (bash, read, write)
- File browser
- Artifact rendering

---

## Next Steps

### Option A: Approve & Move to Design
If the requirements look good, I'll:
1. Mark requirements as `approved`
2. Generate **design.md** with:
   - Architecture diagram (component layout)
   - Data flow diagram (message → LLM → response)
   - Frontend component structure
   - Backend route structure
   - Deployment architecture
3. Then move to task generation

### Option B: Request Changes
If you want to modify requirements, let me know:
- Add/remove features
- Change tech stack
- Adjust acceptance criteria
- Clarify scope

---

## Questions for Approval:

1. **Model selector format** — Should it show `"provider/model"` or just `"model_id"`?
   - Current: `"anthropic/claude-sonnet-4-5"`
   - Alternative: `"claude-sonnet-4-5 (Anthropic)"`

2. **Session persistence** — Keep deferred to Phase 2?
   - (MVP: in-memory only, lose history on refresh)

3. **Error scenarios** — Anything else we should handle?
   - Current: Rate limits, auth failures, network errors

4. **UI framework choice** — React confirmed?
   - Could also be Vue/Svelte, but React + Vite is standard

5. **Deployment path** — Any NixOS integration for this MVP?
   - (Can add later; for now: `npm install && npm run build` for dev)

---

## Ready to Approve?

**Answer: "Looks good! Approve requirements" or "I'd like to change X"**

Once approved, we move straight to `/spec-design` to architecture it out. 🚀
