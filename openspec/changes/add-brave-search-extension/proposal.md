## Why

The pi-coding-agent currently lacks native web search capabilities. When performing research for spec-driven development (as part of the `spec-driven-research` workflow), agents need to search for package documentation, code snippets, best practices, and standards. Currently, this requires external MCP tools which are not token-efficient or context-efficient. The `pi-web-access` package provides a native pi extension with zero-config Chrome-based authentication or optional API keys, web search, content extraction, and video understanding.

## What Changes

- Install the `npm:pi-web-access` package locally in the project
- Configure the package with local settings in `.pi/web-search.json`
- Register the `search_web` tool for performing web searches
- Register the `fetch_content` tool for extracting content from URLs
- Register the `get_search_content` tool for retrieving stored content
- Create GitHub integration for cloning repos during research
- Optional: Install ffmpeg and yt-dlp for video frame extraction

## Capabilities

### New Capabilities

- **web_search**: Native web search via Perplexity AI or Gemini (auto-selects best provider)
- **fetch_content**: URL content extraction for research, GitHub repos, YouTube videos, PDFs
- **get_search_content**: Retrieve stored content from previous searches
- **YouTube understanding**: Full video transcripts, visual descriptions via Gemini
- **GitHub cloning**: Clone repos locally for real file exploration
- **Video frame extraction**: Extract frames at specific timestamps (requires ffmpeg/yt-dlp)

### Modified Capabilities

- (none - this is a new capability set)

## Impact

- New npm package: `pi-web-access` installed locally
- New config file: `.pi/web-search.json` (gitignored)
- New tools available to pi: `search_web`, `fetch_content`, `get_search_content`
- Optional: Local binaries for video processing (`ffmpeg`, `yt-dlp`)
- Zero-config with Chrome (macOS) or API keys (perplexity/gemini)

## Non-Goals

- Implementing the full spec validation workflow (separate change)
- Creating research output templates (documented in design)
- MCP-based integrations (explicitly avoided for token efficiency)
