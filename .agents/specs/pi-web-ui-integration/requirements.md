# Requirements Document: pi-web-ui-integration

## Introduction

A web-based chat interface for interacting with authenticated LLM models via the `@mariozechner/pi-ai` SDK. 

**Scope (MVP):**
- React + Vite + TypeScript frontend serving a chat UI
- Node.js + Hono backend reading credentials from `~/.pi/agent/auth.json`
- Display authenticated LLM models as a dropdown selector
- Send messages, receive streaming responses
- Deploy behind Caddy reverse proxy with Tailscale access control (tailnet-only)

**Out of Scope (Phase 2+):**
- Session persistence / history
- Tool calling (bash, read, write, edit)
- File browser or code editor
- Artifact rendering

---

## Requirements

### Requirement 1: Frontend Chat Interface

**Objective:** As a user, I want a simple web-based chat interface, so that I can interact with LLM models through a browser.

#### Acceptance Criteria

1. When the user navigates to the application root URL (e.g., `https://mnemosyne.hbohlen.systems/`), the browser shall load and render a chat interface.
2. The chat interface shall display a message history area showing past and current messages in conversational format.
3. The chat interface shall include a text input field where the user can type a message.
4. The chat interface shall include a send button that the user can click to submit a message.
5. The chat interface shall use a dark theme with styling consistent with the pi CLI aesthetic.
6. Where the browser window is resized, the chat interface shall remain responsive and usable on desktop and tablet viewports.

### Requirement 2: Model Selection and Configuration

**Objective:** As a user, I want to see available authenticated models and select which one to use, so that I can choose the LLM provider that best fits my needs.

#### Acceptance Criteria

1. When the frontend loads, the application shall fetch the list of authenticated models from the backend `/api/config` endpoint.
2. The frontend shall display a dropdown selector showing all available authenticated models (e.g., "anthropic / claude-sonnet-4-5", "openai / gpt-4o").
3. When the user selects a model from the dropdown, the application shall store the selection (in browser memory for this MVP).
4. If the backend returns an empty model list, the frontend shall display a clear message indicating no models are configured.
5. The frontend shall display the currently selected model in the UI for user confirmation.

### Requirement 3: Message Sending and Streaming Responses

**Objective:** As a user, I want to send messages and receive streaming responses from the selected LLM model, so that I can have a real-time conversation.

#### Acceptance Criteria

1. When the user clicks the send button, the frontend shall send a POST request to `/api/chat` with the message text, selected provider, and selected model.
2. While the backend is streaming a response, the frontend shall display a loading indicator (e.g., "Agent thinking...").
3. When the backend streams response chunks, the frontend shall append each chunk to the message history in real-time (not waiting for full completion).
4. When the backend finishes streaming, the frontend shall clear the loading indicator and allow the user to send another message.
5. If the backend returns an error (4xx, 5xx), the frontend shall display the error message to the user and allow retry.
6. The frontend shall clear the input field after successfully sending a message.
7. The message history shall auto-scroll to show the latest message.

### Requirement 4: Backend Server Setup and Initialization

**Objective:** As a system administrator, I want the backend server to read credentials and start successfully, so that the application is ready to proxy LLM calls.

#### Acceptance Criteria

1. When the backend starts, the server shall read the configuration from `~/.pi/agent/auth.json`.
2. If `~/.pi/agent/auth.json` is missing or malformed, the server shall log a warning and continue with no authenticated models.
3. When the server initializes, it shall parse the auth.json file to extract available providers and their credentials.
4. The server shall start listening on a configurable port (default: 3000).
5. The server shall serve the built frontend (dist/) as static files.

### Requirement 5: Configuration API Endpoint

**Objective:** As a frontend, I want to query the backend for available models and default configuration, so that I can populate the model selector.

#### Acceptance Criteria

1. When the frontend sends a GET request to `/api/config`, the backend shall return a JSON response with an array of available providers and default model selection.
2. The response format shall include: `{ providers: string[], defaults: { provider: string, model: string } }`.
3. Each provider string shall be formatted as `"{provider}/{model_id}"` (e.g., "anthropic/claude-sonnet-4-5").
4. If no models are configured, the backend shall return an empty `providers` array.
5. The response shall be returned within 100ms (no external I/O required).

### Requirement 6: Chat API Endpoint with Streaming

**Objective:** As a frontend, I want to send a message with a specific model and receive a streaming response, so that I can display real-time LLM output.

#### Acceptance Criteria

1. When the frontend sends a POST request to `/api/chat` with `{ messages[], provider: string, model: string }`, the backend shall validate that the provider and model are configured.
2. If the provider is not in auth.json, the backend shall return a 400 Bad Request error with a descriptive message.
3. If the request is valid, the backend shall call the LLM via `@mariozechner/pi-ai` `stream()` function with the authenticated API key for that provider.
4. While the LLM is streaming a response, the backend shall forward each response chunk to the frontend as server-sent events (SSE) or chunked response body.
5. When the LLM finishes responding, the backend shall close the stream.
6. If the LLM API call fails (timeout, authentication error, rate limit), the backend shall return a 500 error with the error message from the LLM provider.

### Requirement 7: Integration with pi-ai SDK

**Objective:** As a developer, I want the backend to use the `@mariozechner/pi-ai` SDK to call LLM providers, so that all providers are supported uniformly.

#### Acceptance Criteria

1. The backend shall import `@mariozechner/pi-ai` (version ^0.66 or compatible).
2. The backend shall call `stream(model, context, { apiKey })` to request streaming responses from the LLM.
3. The backend shall map pi provider names to pi-ai provider identifiers (e.g., `github-copilot` → `github-copilot`, `google-antigravity` → `google`).
4. The backend shall pass the authenticated API key/token from auth.json to pi-ai as the `apiKey` option.
5. The backend shall handle all pi-ai supported providers (Anthropic, OpenAI, Google Gemini, GitHub Copilot, etc.).

### Requirement 8: Tailscale Network Access Control

**Objective:** As a system administrator, I want the application to be accessible only over Tailscale, so that the web UI is private to my tailnet.

#### Acceptance Criteria

1. Where the application is deployed, the backend shall run on an internal network address (not exposed to the public internet).
2. The application shall be accessible via a Tailscale-assigned domain (e.g., `mnemosyne.hbohlen.systems`).
3. When a request arrives at the Tailscale domain, the Caddy reverse proxy shall route it to the backend application.
4. If a request originates from outside the Tailscale tailnet, Caddy shall deny access (enforced via Tailscale ACLs).
5. All traffic between the browser and Caddy shall use HTTPS.

### Requirement 9: Technology Stack Specification

**Objective:** As a developer, I want the technology stack to be specified and reproducible, so that the project can be built and deployed consistently.

#### Acceptance Criteria

1. The frontend shall be built with React + Vite + TypeScript.
2. The backend shall be built with Node.js + Hono + TypeScript.
3. The project shall include a `package.json` with all dependencies pinned.
4. The project shall build successfully with `npm install && npm run build`.
5. The frontend shall be compatible with modern browsers (Chrome, Firefox, Safari, Edge from 2024+).
6. The backend shall run on Node.js 18.x or later.

### Requirement 10: Error Handling and User Feedback

**Objective:** As a user, I want clear error messages when something goes wrong, so that I can understand what happened and how to fix it.

#### Acceptance Criteria

1. If the backend is unreachable, the frontend shall display an error message like "Unable to connect to server".
2. If an LLM API call fails with a rate limit, the frontend shall display "Rate limit hit, please try again later".
3. If a provider is not authenticated, the frontend shall display "Provider {provider} is not configured. Please authenticate via pi CLI".
4. If the message input is empty, the frontend shall disable the send button until the user types a message.
5. All errors shall be logged to the browser console (frontend) and server logs (backend) for debugging.

---

## Research Validation ✅

All 3 critical research items completed. Key findings:

1. **Provider Mapping** — No translation layer needed. GitHub Copilot (and all providers) use native pi-ai identifiers.
2. **Token Refresh** — pi-ai's `getOAuthApiKey()` handles refresh automatically. We save updated credentials after each call.
3. **Streaming Normalization** — pi-ai abstracts all provider differences into unified events (`text_delta`, `thinking_delta`, etc.).

**Result:** All architectural assumptions validated. No design blockers.

See: `.agents/research/pi-web-ui-research-findings.md`

---

## Summary

**10 core requirements** covering:
- Frontend UI and interaction (Reqs 1–3)
- Backend initialization and API design (Reqs 4–6)
- SDK integration (Req 7)
- Network and deployment (Req 8)
- Tech stack (Req 9)
- Error handling (Req 10)

**Phase 1 scope: MVP chat with model selection and streaming responses**  
**Research validated. Ready for design phase approval.**
