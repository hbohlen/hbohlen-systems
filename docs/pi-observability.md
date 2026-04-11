# pi observability design

This repository ships a `pi` extension that emits OpenTelemetry-style trace spans to Datadog over OTLP/HTTP.

## Goals

- instrument the `pi` lifecycle without patching upstream `pi`
- keep deployment reproducible in Nix
- avoid putting Datadog secrets directly in git or the Nix store
- default to metadata-only telemetry, with prompt/tool payload capture disabled
- make the extension available automatically in the target Home Manager environment

## Extension placement

The canonical implementation lives at:

- `pi/extensions/datadog-observability.ts`

A thin project-local shim lives at:

- `.pi/extensions/datadog-observability.ts`

Home Manager installs the canonical file into:

- `~/.pi/agent/extensions/datadog-observability.ts`

That gives two supported activation paths:

1. project-local auto-discovery when running `pi` inside this repo
2. global auto-discovery for the managed `hbohlen` user environment

## Event model

The extension maps `pi` lifecycle events to spans:

- `session_start` -> `pi.session.start`
- `agent_start`/`agent_end` -> `pi.agent`
- `turn_start`/`turn_end` -> `pi.turn`
- `tool_execution_start`/`tool_execution_end` -> `pi.tool`
- `before_provider_request` -> `pi.provider.request`
- `session_shutdown` -> `pi.session.shutdown`

### Captured attributes

By default the extension records only low-risk metadata, including:

- project/repo basename
- session reason
- model provider and model id
- turn index
- tool name / tool call id
- prompt length and image count
- provider payload top-level keys
- success/error flags

### Redaction policy

Default behavior avoids exporting:

- full prompt text
- full tool arguments
- tool results
- raw provider payloads
- API keys or secret file contents
- absolute session contents

Optional debugging capture exists behind env flags:

- `PI_OBSERVABILITY_INCLUDE_PROMPT_TEXT=1`
- `PI_OBSERVABILITY_INCLUDE_TOOL_ARGUMENTS=1`

These should stay disabled for normal use.

## Datadog transport

The extension sends OTLP/HTTP JSON to:

- `PI_OBSERVABILITY_OTLP_BASE_URL/v1/traces`

Default base URL:

- `https://otlp-http-intake.logs.${PI_OBSERVABILITY_SITE:-datadoghq.com}`

Headers:

- `content-type: application/json`
- `DD-API-KEY: <api key>`

## Secret management

The Datadog API key is sourced at runtime from a file path, not embedded in Nix.

- NixOS/opnix materializes `/var/lib/opnix/secrets/datadogApiKey`
- Home Manager exports `PI_OBSERVABILITY_API_KEY_FILE` pointing at that file
- the extension reads the file at export time

Expected 1Password reference:

- `op://hbohlen-systems/datadog/apiKey`

## Runtime configuration

Default Home Manager session variables:

- `PI_OBSERVABILITY_ENABLE=1`
- `PI_OBSERVABILITY_SERVICE_NAME=pi-coding-agent`
- `PI_OBSERVABILITY_SERVICE_NAMESPACE=hbohlen-systems`
- `PI_OBSERVABILITY_ENV=prod`
- `PI_OBSERVABILITY_SITE=datadoghq.com`
- `PI_OBSERVABILITY_API_KEY_FILE=/var/lib/opnix/secrets/datadogApiKey`

Useful optional overrides:

- `PI_OBSERVABILITY_OTLP_BASE_URL`
- `PI_OBSERVABILITY_INCLUDE_PROMPT_TEXT`
- `PI_OBSERVABILITY_INCLUDE_TOOL_ARGUMENTS`

## Operational notes

- missing API key disables successful export but does not break `pi`
- exports are serialized through an in-extension queue to avoid overlapping HTTP posts
- `/observability-status` reports the effective config and last exporter error

## Acceptance criteria

- extension is versioned in git
- extension auto-loads for the managed `hbohlen` environment
- Datadog API key comes from opnix/1Password-backed secret material
- no secret values are written to git or the Nix store
- `nix flake check` covers the new configuration surface
