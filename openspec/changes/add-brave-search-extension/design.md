## Context

This design covers the installation and configuration of the `pi-web-access` package for web search and content fetching in pi. The extension supports the spec-driven research workflow by providing tools for:

1. **Web Search** - Query Perplexity AI or Gemini (auto-selects best provider)
2. **Content Fetching** - Extract content from URLs, GitHub repos, YouTube videos, PDFs
3. **Stored Content Retrieval** - Access previous search results
4. **Video Understanding** - Full transcripts, visual descriptions, frame extraction

### Current State
- pi has built-in tools: `read`, `write`, `edit`, `bash`, `grep`, `find`, `ls`
- Extensions can be installed via `pi install npm:<package-name>`
- Extensions support native `fetch` for HTTP requests
- The project has a `.pi/` directory for local configuration

### Constraints
- No MCP tools - must be native pi extension
- Token efficient - compact JSON responses vs. bash stdout
- Package installed locally in project (not globally)
- API keys in config file or environment variables

## Goals / Non-Goals

**Goals:**
- Install `pi-web-access` package locally via npm
- Configure the package with local settings
- Verify `search_web`, `fetch_content`, `get_search_content` tools work
- Configure optional API keys (Perplexity, Gemini) if needed
- Document setup process for future reference
- Handle optional video dependencies (ffmpeg, yt-dlp)

**Non-Goals:**
- Full spec validation workflow (separate change)
- Research output templates (documented here, implemented separately)
- AI summarization of search results (use LLM for that)
- Implementing video frame extraction (out of scope for initial setup)

## Decisions

### 1. Package Installation Location
**Decision**: Install locally in project under `./node_modules/pi-web-access/`

```
/home/hbohlen/dev/hbohlen-systems/
├── node_modules/
│   └── pi-web-access/     # npm package
├── .pi/
│   └── web-search.json    # local config (gitignored)
```

**Alternatives considered**:
- Global installation (`~/.pi/agent/extensions/`) - Not project-specific
- Manual file copy - Loses npm update benefits

**Rationale**: Local installation keeps project self-contained and portable. The `.pi/` directory already exists for pi configuration.

### 2. Configuration Storage
**Decision**: Store config in `.pi/web-search.json` (gitignored)

```json
{
  "perplexityApiKey": "pplx-...",
  "geminiApiKey": "AIza...",
  "provider": "auto",
  "curateWindow": 10,
  "autoFilter": true,
  "githubClone": {
    "enabled": true,
    "maxRepoSizeMB": 350,
    "cloneTimeoutSeconds": 30,
    "clonePath": "/tmp/pi-github-repos"
  },
  "youtube": {
    "enabled": true,
    "preferredModel": "gemini-3-flash-preview"
  }
}
```

**Alternatives considered**:
- 1Password integration - More secure but adds complexity
- Environment variables - Less portable
- No config - Works with Chrome auth on macOS

**Rationale**: Config file is portable, gitignored for security, and supports all customization options. Can start empty (zero-config) and add keys as needed.

### 3. Package Loading
**Decision**: Use `pi install npm:pi-web-access` command

```bash
pi install npm:pi-web-access
```

**Alternatives considered**:
- Manual npm install + pi config - More steps
- Copy files manually - Loses package management

**Rationale**: Official installation method, handles dependencies automatically.

### 4. Authentication Strategy
**Decision**: Use API keys from config file for non-Chrome platforms

- macOS with Chrome: Zero-config (reads Chrome cookies)
- Other platforms: Use config file with API keys
- Environment variables override config (`GEMINI_API_KEY`, `PERPLEXITY_API_KEY`)

**Rationale**: Flexible approach - works out of box on macOS, configurable elsewhere.

### 5. Video Dependencies
**Decision**: Install ffmpeg and yt-dlp for full video capabilities

```bash
brew install ffmpeg yt-dlp
```

**Alternatives considered**:
- Skip video features - Reduced capability
- Install on-demand - Adds complexity

**Rationale**: Enables full video understanding. Can be skipped if not needed.

## Implementation Steps

### 1. Install pi-web-access package
```bash
pi install npm:pi-web-access
```

### 2. Create local config
Create `.pi/web-search.json` with appropriate settings.

### 3. Update .gitignore
Ensure `.pi/web-search.json` is gitignored (should already be).

### 4. Verify installation
Test tools in pi:
- `web_search({ query: "test" })`
- `fetch_content({ url: "https://example.com" })`

### 5. Optional: Install video dependencies
```bash
brew install ffmpeg yt-dlp
```

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|-------------|
| API keys expire/rotate | Search stops working | Document key rotation process |
| Rate limiting | Search blocked temporarily | Provider auto-retries, fallback chain |
| Page content extraction fails | Research incomplete | Multiple fallback strategies built-in |
| Chrome auth unavailable | Need API keys on non-macOS | Config file with keys |
| Package not found | Installation fails | Verify package name and npm connectivity |

## Open Questions

1. Should we commit the node_modules or use .gitignore for them?
2. Should we configure a specific provider (perplexity vs gemini)?
3. Should we enable auto-condense for multi-query searches?
4. Where should GitHub repos be cloned (temp vs project dir)?
