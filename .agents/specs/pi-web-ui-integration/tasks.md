# Implementation Plan: pi-web-ui-integration

## Overview

This plan implements a web-based chat interface for pi-authenticated LLM providers. The feature delivers a React SPA frontend with a Hono backend that proxies LLM calls through the pi-ai SDK, deployed behind Tailscale with Caddy.

---

## Phase 1: Project Setup and Core Infrastructure

- [x] 1. Initialize project structure with frontend and backend workspaces
  - Create root `package.json` with npm workspaces configuration
  - Initialize `frontend/` directory with Vite + React + TypeScript template
  - Initialize `backend/` directory with TypeScript and Hono dependencies
  - Configure TypeScript with strict settings for both workspaces
  - Set up shared types package for API contracts
  - _Requirements: 9.1, 9.2, 9.3_

- [x] 1.1 (P) Configure frontend build tooling and UI framework
  - Install and configure Tailwind CSS with dark theme tokens
  - Install shadcn/ui CLI and initialize component library
  - Configure Vite build output to `dist/` directory
  - Add development proxy configuration for API calls
  - _Requirements: 1.5, 9.1, 9.5_

- [x] 1.2 (P) Configure backend server foundation
  - Install Hono framework with TypeScript types
  - Install `@mariozechner/pi-ai` SDK dependency
  - Create basic Hono app with health check endpoint
  - Configure serveStatic middleware for frontend assets
  - Set up environment configuration (port, auth file path)
  - _Requirements: 4.4, 4.5, 9.2, 9.6_

---

## Phase 2: Backend Services and API Implementation

- [x] 2. Implement configuration service for auth.json parsing
  - Create ConfigService class to read `~/.pi/agent/auth.json`
  - Implement provider parsing with error handling for missing files
  - Format provider strings as `"provider/model"` pairs
  - Return empty providers array when auth.json is absent or malformed
  - Add caching to avoid re-reading file on every request
  - _Requirements: 4.1, 4.2, 4.3, 5.3, 5.4, 7.3_

- [x] 2.1 Implement GET /api/config endpoint
  - Create ConfigController with getConfig handler
  - Return providers array and default selection from ConfigService
  - Ensure response time under 100ms
  - Add structured logging for requests
  - _Requirements: 2.1, 5.1, 5.2, 5.5_

- [x] 2.2 Implement chat service with pi-ai SDK integration
  - Create ChatService class to handle LLM streaming
  - Implement provider validation against ConfigService
  - Call `stream()` with model, messages context, and API key
  - Yield normalized stream chunks (text_delta, error, done)
  - Handle pi-ai OAuth token refresh transparently
  - _Requirements: 6.2, 6.3, 7.1, 7.2, 7.4, 7.5_

- [x] 2.3 Implement POST /api/chat endpoint with SSE streaming
  - Create ChatController with postChat handler
  - Validate request body (messages array, provider, model)
  - Return 400 Bad Request for invalid or unconfigured providers
  - Stream response via Server-Sent Events format
  - Close stream gracefully on completion or error
  - Return 500 error with descriptive message on LLM failures
  - _Requirements: 3.1, 6.1, 6.4, 6.5, 6.6, 10.2, 10.3_

- [ ] 2.4 (P)* Add backend unit tests for core services
  - Test ConfigService with valid, missing, and malformed auth.json
  - Test ChatService provider validation logic
  - Test API endpoints with mocked dependencies
  - _Requirements: 4.1, 4.2, 6.2_

---

## Phase 3: Frontend State Management and Core Components

- [x] 3. Implement Zustand store for chat state management
  - Create useChatStore with messages array
  - Add selected provider and model state
  - Implement addMessage and appendToLastMessage actions
  - Add streaming state flag with setStreaming action
  - Include clearMessages action for reset functionality
  - _Requirements: 2.3, 3.3, 3.6_

- [x] 3.1 (P) Create chat page layout and container components
  - Build ChatPage component with header, main, footer sections
  - Implement responsive flexbox layout with max-width constraint
  - Create MessageList component with auto-scroll behavior
  - Build MessageBubble component with user/assistant styling
  - Apply dark theme consistent with pi CLI aesthetic
  - _Requirements: 1.1, 1.2, 1.5, 1.6, 3.7_

- [x] 3.2 (P) Implement chat input component with validation
  - Build ChatInput with textarea and send button
  - Disable send button when input is empty
  - Clear input field after successful message send
  - Handle Enter key for submission (Shift+Enter for newline)
  - _Requirements: 1.3, 1.4, 10.4_

- [x] 3.3 (P) Implement model selector component
  - Build ModelSelector dropdown component
  - Fetch configuration from GET /api/config on mount
  - Display providers formatted as "provider / model"
  - Show empty state message when no providers configured
  - Display currently selected model in UI
  - _Requirements: 2.1, 2.2, 2.4, 2.5_

---

## Phase 4: Frontend API Integration and Streaming

- [x] 4. Implement API client for backend communication
  - Create apiClient with fetch wrappers for config and chat endpoints
  - Add base URL configuration from environment
  - Implement error handling with descriptive messages
  - Add request/response logging for debugging
  - _Requirements: 2.1, 3.1, 10.1_

- [x] 4.1 Integrate message sending with streaming response
  - Connect ChatInput send action to POST /api/chat
  - Add user message to store immediately on send
  - Display loading indicator while awaiting first chunk
  - Parse SSE stream and append chunks to assistant message
  - Clear loading state when done event received
  - Handle stream errors and display in ErrorToast
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [x] 4.2 Implement error handling and feedback components
  - Create ErrorToast component for displaying errors
  - Handle backend unreachable state with retry guidance
  - Display rate limit errors with specific messaging
  - Show unconfigured provider errors with CLI guidance
  - Log all errors to browser console
  - _Requirements: 3.5, 10.1, 10.2, 10.3, 10.5_

- [ ] 4.3 (P)* Add frontend component tests
  - Test MessageList rendering with mock messages
  - Test ChatInput validation and submission
  - Test ModelSelector with mock config data
  - _Requirements: 1.2, 1.3, 2.2_

---

## Phase 5: NixOS Integration and Deployment

- [x] 5. Create NixOS module for pi-web-ui service
  - Define systemd service with Node.js runtime
  - Configure service to run on internal network (localhost:3000)
  - Set up proper working directory and environment variables
  - Add hardening options (restrict network, filesystem)
  - Include service dependency ordering
  - _Requirements: 8.1, 9.2_

- [x] 5.1 Configure Caddy reverse proxy for Tailscale domain
  - Add Caddy virtual host for `mnemosyne.hbohlen.systems`
  - Route traffic to localhost:3000 backend
  - Enable HTTPS with Tailscale certificates
  - Configure headers and timeouts
  - _Requirements: 8.2, 8.3, 8.5_

- [x] 5.2 Verify Tailscale network access control
  - Confirm Tailscale ACLs restrict access to tailnet
  - Validate no public internet exposure
  - Test access from tailnet vs external network
  - _Requirements: 8.4_

- [ ] 5.3 (P)* Add integration tests for full stack
  - Test end-to-end message flow with mocked LLM
  - Verify SSE streaming behavior
  - Test error handling paths
  - _Requirements: 3.1, 3.3, 6.1_

---

## Phase 6: Build and Validation

- [x] 6. Create build scripts and verify production build
  - Add npm build script that builds frontend then backend
  - Verify frontend dist/ is properly generated
  - Confirm backend can serve static files from dist/
  - Test build command completes successfully
  - _Requirements: 9.4_

- [x] 6.1 Validate all acceptance criteria
  - Verify all 10 requirements have passing acceptance criteria
  - Run through complete user flow manually
  - Confirm Tailscale-only access enforcement
  - Validate dark theme and responsive layout
  - _Requirements: All_

---

## Requirements Traceability Summary

| Requirement | Task Coverage |
|-------------|---------------|
| 1.1 | 3.1 |
| 1.2 | 3.1 |
| 1.3 | 3.2 |
| 1.4 | 3.2 |
| 1.5 | 1.1, 3.1 |
| 1.6 | 3.1 |
| 2.1 | 2.1, 3.3, 4 |
| 2.2 | 3.3 |
| 2.3 | 3 |
| 2.4 | 3.3 |
| 2.5 | 3.3 |
| 3.1 | 2.3, 4, 4.1 |
| 3.2 | 4.1 |
| 3.3 | 3, 4.1 |
| 3.4 | 2.3, 4.1 |
| 3.5 | 2.3, 4.2 |
| 3.6 | 3, 3.2, 4.1 |
| 3.7 | 3.1 |
| 4.1 | 2, 2.4 |
| 4.2 | 2, 2.4 |
| 4.3 | 2 |
| 4.4 | 1.2, 5 |
| 4.5 | 1.2, 5 |
| 5.1 | 2.1 |
| 5.2 | 2.1 |
| 5.3 | 2 |
| 5.4 | 2 |
| 5.5 | 2.1 |
| 6.1 | 2.3 |
| 6.2 | 2.2, 2.4 |
| 6.3 | 2.2 |
| 6.4 | 2.3 |
| 6.5 | 2.3 |
| 6.6 | 2.3 |
| 7.1 | 1.2, 2.2 |
| 7.2 | 2.2 |
| 7.3 | 2 |
| 7.4 | 2.2 |
| 7.5 | 1.2, 2.2 |
| 8.1 | 5 |
| 8.2 | 5.1 |
| 8.3 | 5.1 |
| 8.4 | 5.2 |
| 8.5 | 5.1 |
| 9.1 | 1, 1.1, 3.1 |
| 9.2 | 1, 1.2, 5 |
| 9.3 | 1 |
| 9.4 | 6 |
| 9.5 | 1.1 |
| 9.6 | 1.2, 5 |
| 10.1 | 4, 4.2 |
| 10.2 | 2.3, 4.2 |
| 10.3 | 2.3, 4.2 |
| 10.4 | 3.2 |
| 10.5 | 2.1, 4.2 |

---

## Execution Notes

### Parallel Tasks (P)
Tasks marked with `(P)` can be executed in parallel:
- 1.1 and 1.2: Frontend and backend setup are independent
- 2.4: Backend tests can be written while implementing services
- 3.1, 3.2, 3.3: UI components can be built in parallel after store exists
- 4.3: Frontend tests parallel to integration work
- 5.3: Integration tests parallel to NixOS work

### Deferrable Tests (*)
Tasks marked with `*` are test coverage that can be deferred if needed:
- 2.4: Backend unit tests
- 4.3: Frontend component tests  
- 5.3: Full stack integration tests

### Prerequisites by Phase
- Phase 2 requires Phase 1 completion (project structure)
- Phase 3 requires Phase 1 completion (build tooling ready)
- Phase 4 requires Phase 2 and Phase 3 (API and UI ready)
- Phase 5 requires Phase 4 completion (working application)
- Phase 6 requires all prior phases

---

*Tasks generated: April 9, 2026*
*Status: Pending approval for implementation*
