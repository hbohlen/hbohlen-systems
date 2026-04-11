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

- `https://otlp.${PI_OBSERVABILITY_SITE:-datadoghq.com}`

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
- `PI_OBSERVABILITY_HTTPS_PROXY`
- `PI_OBSERVABILITY_HTTP_PROXY`
- `PI_OBSERVABILITY_NO_PROXY`
- fallback envs: `HTTPS_PROXY`, `HTTP_PROXY`, `NO_PROXY`

## Operational notes

- missing API key disables successful export but does not break `pi`
- Datadog direct OTLP traces intake is documented as preview-only; org-side enablement may be required
- the exporter expects a Datadog API key, not an application key or client token
- exports are serialized through an in-extension queue to avoid overlapping HTTP posts
- direct egress is the default when no proxy is configured
- `/observability-status` reports the effective config and last exporter error
- `/observability-status` redacts proxy credentials before showing configured proxy URLs

## Proxy configuration

The exporter now chooses outbound behavior explicitly instead of relying on ambient `fetch` proxy handling.

### Supported env vars

Preferred observability-specific settings:

- `PI_OBSERVABILITY_HTTPS_PROXY`
- `PI_OBSERVABILITY_HTTP_PROXY`
- `PI_OBSERVABILITY_NO_PROXY`

Fallback standard env vars:

- `HTTPS_PROXY`
- `HTTP_PROXY`
- `NO_PROXY`

Lowercase standard variants are also accepted as a final fallback:

- `https_proxy`
- `http_proxy`
- `no_proxy`

### Precedence rules

Proxy config is resolved in this order:

1. `PI_OBSERVABILITY_*`
2. uppercase standard proxy vars
3. lowercase standard proxy vars

For HTTPS Datadog OTLP export, the extension prefers `PI_OBSERVABILITY_HTTPS_PROXY`/`HTTPS_PROXY`. If no HTTPS-specific proxy is set, it falls back to `PI_OBSERVABILITY_HTTP_PROXY`/`HTTP_PROXY` for the HTTPS target.

If no matching proxy variable is configured, the exporter uses direct outbound HTTPS.

### NO_PROXY behavior

`PI_OBSERVABILITY_NO_PROXY`/`NO_PROXY` bypasses the proxy for matching hosts. Supported matching modes are:

- exact hostname match, e.g. `otlp-http-intake.logs.datadoghq.com`
- domain suffix match, e.g. `.datadoghq.com` or `datadoghq.eu`
- wildcard `*` to bypass the proxy for all destinations

Examples:

- `PI_OBSERVABILITY_NO_PROXY=otlp-http-intake.logs.datadoghq.com`
- `PI_OBSERVABILITY_NO_PROXY=.datadoghq.com`
- `PI_OBSERVABILITY_NO_PROXY=*`

When `NO_PROXY` matches the Datadog intake hostname, the exporter skips the proxy and uses direct egress.

### `/observability-status`

`/observability-status` shows the resolved proxy config via:

- `httpsProxy=`
- `httpProxy=`
- `noProxy=`

Credential material in proxy URLs is sanitized in status output. Example:

- `https://user:secret@proxy.internal:8443` is shown as `https://***:***@proxy.internal:8443/`

## Network compatibility guidance

The exporter uses outbound HTTPS only. It posts JSON to:

- `https://otlp.${PI_OBSERVABILITY_SITE:-datadoghq.com}/v1/traces`

For the current default config (`PI_OBSERVABILITY_SITE=datadoghq.com`), the target is:

- `https://otlp.datadoghq.com/v1/traces`

### Required egress

Observability export needs:

- DNS resolution for `otlp-http-intake.logs.<site>`
- outbound TCP 443 to the resolved Datadog intake address
- normal public internet routing from the host

No inbound ports are required for Datadog telemetry.

### Tailscale impact

Current host/network settings do not inherently block Datadog OTLP egress:

- `services.tailscale.openFirewall = true` opens Tailscale-related firewall handling, but does not block normal outbound HTTPS
- `services.tailscale.useRoutingFeatures = "server"` enables Tailscale server-mode routing features, but does not by itself force Datadog traffic through Tailscale
- current Tailscale prefs show `RouteAll: false` and no exit node configured, so public internet traffic keeps using the normal default route rather than a Tailscale exit node
- Tailscale SSH, `tailscale serve`, and the Caddy Tailscale listener affect inbound/tailnet access patterns, not outbound OTLP export to Datadog
- MagicDNS/CorpDNS do not conflict with the Datadog hostname; public DNS lookup still resolves the intake endpoint normally

A live connectivity check from this host succeeded at the network layer against Datadog OTLP hosts:

- `otlp.datadoghq.com` and `otlp.us5.datadoghq.com` resolve and accept HTTPS connections

Note: Datadog's direct OTLP traces intake is documented as preview-only. Successful DNS/TLS reachability does not by itself guarantee that direct trace ingestion is enabled for the organization.

### Firewall guidance

With the current NixOS config, no extra firewall rule is needed for Datadog export because the local firewall governs inbound traffic and outbound traffic is permitted by default.

If this host later moves behind restrictive egress controls, allow:

- destination: `otlp-http-intake.logs.<site>`
- protocol: HTTPS
- port: `443/tcp`

### Regional Datadog sites

The extension builds the endpoint from `PI_OBSERVABILITY_SITE`, so the hostname changes with the Datadog site. Examples:

- `datadoghq.com` -> `otlp.datadoghq.com`
- `datadoghq.eu` -> `otlp.datadoghq.eu`
- `us3.datadoghq.com` -> `otlp.us3.datadoghq.com`
- `us5.datadoghq.com` -> `otlp.us5.datadoghq.com`
- `ap1.datadoghq.com` -> `otlp.ap1.datadoghq.com`
- `ddog-gov.com` -> `otlp.ddog-gov.com`

When changing sites, verify that DNS and outbound 443 are allowed for the corresponding hostname.

### Proxy guidance

The exporter now supports explicit HTTP(S) proxy configuration for Datadog OTLP requests.

- direct outbound HTTPS remains the default when no proxy is configured
- configured HTTP or HTTPS proxies are used explicitly rather than relying on Node/undici ambient behavior
- if `NO_PROXY` matches the Datadog intake hostname, the exporter bypasses the proxy and uses direct egress

For proxy-required environments, set the `PI_OBSERVABILITY_*` proxy vars explicitly so behavior is deterministic. For direct-egress environments, leave them unset.

## Acceptance criteria

- extension is versioned in git
- extension auto-loads for the managed `hbohlen` environment
- Datadog API key comes from opnix/1Password-backed secret material
- no secret values are written to git or the Nix store
- `nix flake check` covers the new configuration surface
