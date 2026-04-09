# Requirements Document

## Introduction

This document defines the requirements for the **Mnemosyne PKM System Infrastructure** - a personal knowledge management system that stores notes in a dedicated directory, serves a web UI via Tailscale-protected reverse proxy, and provides AI agent integration for task management and knowledge retrieval.

## Requirements

### Requirement 1: PKM Data Storage

**Objective:** As a system administrator, I want the PKM data directory to be managed through Home Manager, so that notes are stored in a consistent, version-controlled location accessible to the application.

#### Acceptance Criteria

1. When the user configures the PKM system, the Mnemosyne shall store all notes in the `~/mnemosyne` directory.
2. While Home Manager is active, the Mnemosyne shall maintain the directory structure for note organization.
3. If the `~/mnemosyne` directory does not exist, the system shall create it with appropriate permissions.

### Requirement 2: Application Deployment Infrastructure

**Objective:** As a system administrator, I want the `pi` TypeScript application to be deployed through NixOS, so that the application is reproducible and integrated with the system configuration.

#### Acceptance Criteria

1. When the NixOS configuration is applied, the `pi` application shall be available in the system's application directory.
2. Where the NixOS configuration includes custom applications, the `pi` application shall be built from the TypeScript source.
3. The system shall provide the necessary runtime dependencies (Node.js) for the TypeScript SDK to function correctly.
4. The pi-mono packages (`@mariozechner/pi-ai`, `@mariozechner/pi-agent-core`, `@mariozechner/pi-web-ui`) shall be available for the application to import.
5. The system shall configure API key storage for the LLM providers (Anthropic, OpenAI, Google, etc.).

### Requirement 3: Web UI Access Control

**Objective:** As a user, I want to access the Mnemosyne web interface through a Tailscale-protected domain, so that my notes are accessible only through my private network.

#### Acceptance Criteria

1. When a request arrives at `mnemosyne.hbohlen.systems`, the Caddy reverse proxy shall route it to the `pi` web application.
2. While the request originates from within the Tailscale tailnet, the reverse proxy shall allow access to the web UI.
3. If a request originates from outside the Tailscale tailnet, the system shall deny access.
4. The system shall provide HTTPS encryption for all authenticated connections.

### Requirement 4: Agent Task Integration

**Objective:** As a user, I want to assign implementation tasks to AI agents and have them reference accumulated knowledge, so that I can delegate work while ensuring agents access accurate context.

#### Acceptance Criteria

1. When a user creates a task in Mnemosyne, the system shall store the task with full context and requirements.
2. While an agent queries the knowledge base, the system shall return relevant prior implementations and decisions.
3. If an agent searches for completed work, the system shall provide searchable access to historical tasks and their outcomes.
4. The system shall support linking new tasks to existing knowledge entries for context continuity.

### Requirement 5: Knowledge Search and Retrieval

**Objective:** As an AI agent, I want to search and retrieve information from the PKM system, so that I can understand prior work and make informed decisions.

#### Acceptance Criteria

1. When an agent submits a search query, the system shall return matching notes and tasks.
2. While the agent is operating within the authorized context, the system shall provide access to the full knowledge base.
3. If the search query yields no results, the system shall return an empty result set with no error.

### Requirement 6: System Configuration Management

**Objective:** As a system administrator, I want the PKM infrastructure to be defined in NixOS configuration, so that the entire system is declarative and reproducible.

#### Acceptance Criteria

1. When the NixOS configuration is rebuilt, the PKM system infrastructure shall be deployed consistently.
2. The system shall maintain separation between the Home Manager user configuration and the NixOS system configuration.
3. Where the deployment includes both VPS and local environments, each shall have appropriate configuration for its role.