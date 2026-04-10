# Pi Web UI Integration — Spec Foundation

## Research Complete ✓

I've documented everything in `.agents/research/pi-web-ui-integration-research.md`. Here are the key findings:

### Three Viable Architectures

1. **Native Web Components** (RECOMMENDED for you)
   - Use `@mariozechner/pi-web-ui` package
   - Mount custom React/Vue/vanilla UI
   - Full control, IndexedDB storage, real artifacts
   - Fastest to MVP, most flexible

2. **RPC Bridge**
   - Run pi headless, bridge to WebSocket
   - Good for servers, multiple clients, isolation
   - More complex deployment

3. **MCP Integration**
   - Embed pi inside Claude/ChatGPT/VS Code
   - Overkill unless you need multi-client portability

---

## Before We Start the Spec: Key Questions

**Answer these and the spec will write itself:**

### 1. Primary Use Case
- Personal dev tool (interactive coding sessions)?
- Demo / showcase?
- Embedded feature in a larger app?
- Research / experimentation?

### 2. Features
- **Chat only**, or also:
  - File browser?
  - Terminal/bash execution?
  - Code editor?
  - Artifacts preview (HTML, SVG, etc.)?
  - Model/provider selector?
  - Session management?

### 3. Scope (MVP vs. Full)
- **MVP**: Chat UI + model selector + one provider (e.g., Anthropic)
- **Full**: All features, multiple providers, persistence, sharing

### 4. Deployment
- **Single-user** (localhost dev tool)?
- **Team** (internal server, self-hosted)?
- **Public** (SaaS, multi-user)?

### 5. UI Preference
- **Fully custom** (your own design)?
- **Use ChatPanel** (batteries-included, customize top-level)?
- **Use AgentInterface** (modular, compose yourself)?

### 6. Tech Stack
- **Framework**: React? Vue? Svelte? Vanilla?
- **Hosting**: Vite dev server? Deployed to cloud? Electron?
- **Backend**: Pure browser (IndexedDB), or Node.js bridge?

### 7. Tools & Integration
- **Built-in tools** (read, bash, write, edit) enabled by default?
- **Custom tools**? (Define special behaviors)
- **Extensions** from pi ecosystem, or custom only?

---

## Rough Estimation

| Scope | Time | Complexity |
|-------|------|-----------|
| **MVP** (chat + model selector) | 2-4 hours | Low |
| **Usable** (+ file browser, + think levels, + persistence) | 1-2 days | Medium |
| **Production** (+ all features, error handling, deployment) | 1-2 weeks | High |

---

## Recommended Path (If You Say "Just Build It")

1. **Hour 1**: Set up Vite + web components + AppStorage
2. **Hour 2**: Mount `AgentInterface`, wire up a model
3. **Hour 3**: Add custom styling, document
4. **Hour 4**: Deploy locally or to edge (Cloudflare, Vercel)

This gives you a working web UI you can iterate on.

---

## Next: Shape the Spec

Once you answer those 7 questions above, I'll:
1. Use `/spec-init` to create the spec structure
2. Generate EARS requirements based on your answers
3. Design the architecture (component diagram, data flow, tech stack)
4. Break into implementation tasks
5. Start building

**Your call — ready to answer the questions, or want to go straight to MVP and iterate?**
