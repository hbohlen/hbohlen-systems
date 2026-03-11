## Context

This design covers the implementation of a native pi extension for web search and content fetching, integrated with Brave Search API. The extension will support the spec-driven research workflow by providing tools for:

1. **Web Search** - Query Brave Search API for relevant results
2. **Content Fetching** - Extract content from URLs for research
3. **Gap Analysis** - Analyze specs for knowledge gaps (future)
4. **Bead Integration** - Create research tasks in beads (future)

### Current State
- pi has built-in tools: `read`, `write`, `edit`, `bash`, `grep`, `find`, `ls`
- Extensions can register custom tools via `pi.registerTool()`
- Extensions support native `fetch` for HTTP requests (see antigravity-image-gen.ts example)
- 1Password CLI (`op`) available for secure credential retrieval

### Constraints
- No MCP tools - must be native pi extension
- Token efficient - compact JSON responses vs. bash stdout
- API key stored in 1Password, not in code or config files

## Goals / Non-Goals

**Goals:**
- Create `search_web` tool that wraps Brave Search API
- Create `fetch_content` tool for URL content extraction
- Handle API key via 1Password integration
- Make tools reusable and independently callable
- Follow pi extension patterns from existing examples

**Non-Goals:**
- Full spec validation workflow (separate change)
- Research output templates (documented here, implemented separately)
- AI summarization of search results (use LLM for that)
- Image/video/news search (web search only for now)

## Decisions

### 1. Extension Structure
**Decision**: Single directory extension with index.ts

```
~/.pi/agent/extensions/brave-search/
├── index.ts              # Main extension entry point
├── brave-search.ts       # Brave Search API wrapper
├── content-fetcher.ts   # URL content extraction
└── types.ts             # TypeScript interfaces
```

**Rationale**: Matches pi's extension patterns. Single file works for small extensions, but content-fetcher is complex enough to warrant separation.

### 2. API Key Handling
**Decision**: Execute `op read` via Node.js child_process in extension

```typescript
import { execSync } from "node:child_process";

function getApiKey(): string {
  return execSync("op read 'op://hbohlen-systems/brave-search/apiKey'", { encoding: "utf-8" }).trim();
}
```

**Alternatives considered**:
- Config file with `!op read` - Works but adds file management
- Environment variable - Less secure, requires user to set manually
- Prompt user on first use - Adds complexity, more code

**Rationale**: Direct execution is simple, secure (key never logged or stored), and leverages existing 1Password setup.

### 3. Tool Output Format
**Decision**: Compact JSON with essential fields only

```typescript
// search_web result
{
  results: [
    { title: string, url: string, description: string }
  ],
  total: number,
  query: string
}
```

**Alternatives considered**:
- Full Brave response - Too verbose, includes metadata
- Minimal (titles only) - Loses context for research

**Rationale**: Balance between token efficiency and useful context. LLM can request more detail via fetch_content if needed.

### 4. Content Fetching Strategy
**Decision**: Simple curl-based extraction with readability heuristics

```typescript
async function fetchContent(url: string): Promise<{
  title: string;
  content: string;
  relevantSnippets?: string[];
}>
```

**Alternatives considered**:
- Full HTML parsing library - Adds dependency
- Browser automation - Overkill, too heavy

**Rationale**: Use built-in tools where possible. The extension can use `fetch` + basic HTML parsing. For complex pages, can fall back to `bash` with `curl` and `grep`.

### 5. Error Handling
**Decision**: Graceful degradation with informative errors

- API errors: Return error in tool result, don't throw
- Rate limiting: Detect and notify user
- Network errors: Return partial results if possible

**Rationale**: Agent should continue working even if search fails. Errors should be actionable.

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|------------|
| Brave API key expires/rotates | Search stops working | Document key rotation process, consider caching with TTL |
| Rate limiting | Search blocked temporarily | Implement retry with backoff, notify user |
| Page content extraction fails | Research incomplete | Fall back to search results snippets |
| 1Password not available | Can't get API key | Detect and show clear error message |

## Open Questions

1. Should we cache search results to reduce API calls?
2. Should fetch_content use a library like `cheerio` or built-in HTML parsing?
3. Should we add a config option for result count (vs hardcoded default)?
4. How to handle Brave's AI summary feature (more token-efficient but less flexible)?
