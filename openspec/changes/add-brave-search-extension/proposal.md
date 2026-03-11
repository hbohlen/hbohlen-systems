## Why

The pi-coding-agent currently lacks native web search capabilities. When performing research for spec-driven development (as part of the `spec-driven-research` workflow), agents need to search for package documentation, code snippets, best practices, and standards. Currently, this requires external MCP tools which are not token-efficient or context-efficient. A native pi extension using Brave Search API will provide reusable, efficient web search without MCP overhead.

## What Changes

- Create a new pi extension: `brave-search` at `~/.pi/agent/extensions/brave-search/`
- Register the `search_web` tool for performing web searches via Brave Search API
- Register the `fetch_content` tool for extracting content from URLs
- Store Brave API key in 1Password and retrieve via `op` CLI
- Create integration with beads for research task management
- Create integration with OpenSpec for spec validation and gap analysis

## Capabilities

### New Capabilities

- **brave-search-api**: Native Brave Search API integration for web search
- **content-fetcher**: URL content extraction for research
- **research-gap-analysis**: LLM-driven analysis of specs to identify knowledge gaps
- **research-bead-creation**: Integration with beads for creating research tasks from gaps

### Modified Capabilities

- (none - this is a new capability set)

## Impact

- New extension directory: `~/.pi/agent/extensions/brave-search/`
- New tools available to pi: `search_web`, `fetch_content`
- Integration with beads CLI for research task management
- Integration with OpenSpec for spec validation workflow
- Uses Brave Search Web API with API key from 1Password

## Non-Goals

- Implementing the full spec validation workflow (separate change)
- Creating research output templates (documented in design)
- MCP-based integrations (explicitly avoided for token efficiency)
