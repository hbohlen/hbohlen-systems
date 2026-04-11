import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { hostname } from "node:os";
import { basename } from "node:path";
import { readFile } from "node:fs/promises";
import { randomBytes } from "node:crypto";
import * as http from "node:http";
import * as https from "node:https";
import * as net from "node:net";
import * as tls from "node:tls";
import { buildObservabilityConfig, formatProxyStatus, selectProxyForUrl } from "./datadog-observability-config.mjs";

type Primitive = string | number | boolean;

type SpanState = {
  traceId: string;
  spanId: string;
  parentSpanId?: string;
  name: string;
  startTimeUnixNano: string;
  attributes: Record<string, Primitive | undefined>;
  kind?: number;
};

type ObservabilityConfig = {
  enabled: boolean;
  serviceName: string;
  serviceNamespace: string;
  environment: string;
  site: string;
  otlpBaseUrl: string;
  apiKey?: string;
  apiKeyFile?: string;
  includePromptText: boolean;
  includeToolArguments: boolean;
  httpsProxy?: string;
  httpProxy?: string;
  noProxy?: string;
};

const INTERNAL_SPAN_KIND = 1;
const CLIENT_SPAN_KIND = 3;
const STATUS_OK = 1;
const STATUS_ERROR = 2;
const EXTENSION_NAME = "datadog-observability";
const EXTENSION_VERSION = "0.1.0";

function randomHex(bytes: number): string {
  return randomBytes(bytes).toString("hex");
}

function toNanoTime(date = Date.now()): string {
  return `${BigInt(date) * 1_000_000n}`;
}

function truncate(value: string, maxLength = 512): string {
  return value.length > maxLength ? `${value.slice(0, maxLength - 1)}…` : value;
}

function stringifyValue(value: unknown, maxLength = 512): string {
  if (typeof value === "string") return truncate(value, maxLength);
  try {
    return truncate(JSON.stringify(value), maxLength);
  } catch {
    return truncate(String(value), maxLength);
  }
}

function scalarToAttribute(value: Primitive) {
  if (typeof value === "string") return { stringValue: value };
  if (typeof value === "boolean") return { boolValue: value };
  if (Number.isInteger(value)) return { intValue: String(value) };
  return { doubleValue: value };
}

function attributesToOtel(attributes: Record<string, Primitive | undefined>) {
  return Object.entries(attributes)
    .filter(([, value]) => value !== undefined)
    .map(([key, value]) => ({ key, value: scalarToAttribute(value as Primitive) }));
}

function buildConfig(): ObservabilityConfig {
  return buildObservabilityConfig(process.env) as ObservabilityConfig;
}

async function readApiKey(config: ObservabilityConfig): Promise<string | undefined> {
  if (config.apiKey) return config.apiKey;
  if (!config.apiKeyFile) return undefined;
  try {
    const value = (await readFile(config.apiKeyFile, "utf8")).trim();
    return value || undefined;
  } catch {
    return undefined;
  }
}

function repoName(cwd: string): string {
  return basename(cwd) || cwd;
}

function promptAttributes(prompt: string | undefined, includePromptText: boolean) {
  if (!prompt) return {};
  return {
    "pi.prompt.length": prompt.length,
    ...(includePromptText ? { "pi.prompt.preview": truncate(prompt, 240) } : {}),
  };
}

function safeErrorMessage(error: unknown): string {
  if (error instanceof Error) return truncate(error.message, 240);
  return truncate(String(error), 240);
}

function proxyAuthorizationHeader(proxyUrl: URL): string | undefined {
  if (!proxyUrl.username && !proxyUrl.password) return undefined;
  const auth = `${decodeURIComponent(proxyUrl.username)}:${decodeURIComponent(proxyUrl.password)}`;
  return `Basic ${Buffer.from(auth).toString("base64")}`;
}

function requestViaDirectConnection(targetUrl: URL, body: string, headers: Record<string, string>) {
  return new Promise<{ statusCode: number; statusMessage: string }>((resolve, reject) => {
    const transport = targetUrl.protocol === "https:" ? https : http;
    const request = transport.request(
      targetUrl,
      {
        method: "POST",
        headers: {
          ...headers,
          "content-length": Buffer.byteLength(body).toString(),
        },
      },
      (response) => {
        response.resume();
        response.on("end", () => {
          resolve({
            statusCode: response.statusCode ?? 0,
            statusMessage: response.statusMessage ?? "",
          });
        });
      },
    );

    request.on("error", reject);
    request.end(body);
  });
}

function connectTunnel(proxyUrl: URL, targetUrl: URL) {
  return new Promise<net.Socket>((resolve, reject) => {
    const transport = proxyUrl.protocol === "https:" ? https : http;
    const proxyHeaders: Record<string, string> = {
      host: `${targetUrl.hostname}:${targetUrl.port || 443}`,
    };
    const proxyAuth = proxyAuthorizationHeader(proxyUrl);
    if (proxyAuth) {
      proxyHeaders["proxy-authorization"] = proxyAuth;
    }

    const connectRequest = transport.request({
      protocol: proxyUrl.protocol,
      hostname: proxyUrl.hostname,
      port: proxyUrl.port || (proxyUrl.protocol === "https:" ? 443 : 80),
      method: "CONNECT",
      path: `${targetUrl.hostname}:${targetUrl.port || 443}`,
      headers: proxyHeaders,
    });

    connectRequest.on("connect", (response, socket) => {
      if (response.statusCode !== 200) {
        socket.destroy();
        reject(new Error(`Proxy CONNECT failed: ${response.statusCode} ${response.statusMessage ?? ""}`.trim()));
        return;
      }
      resolve(socket);
    });

    connectRequest.on("error", reject);
    connectRequest.end();
  });
}

function requestViaProxy(targetUrl: URL, proxy: string, body: string, headers: Record<string, string>) {
  return new Promise<{ statusCode: number; statusMessage: string }>(async (resolve, reject) => {
    try {
      const proxyUrl = new URL(proxy);
      const tunneledSocket = await connectTunnel(proxyUrl, targetUrl);
      const secureSocket = tls.connect({
        socket: tunneledSocket,
        servername: targetUrl.hostname,
      });

      secureSocket.on("error", reject);

      const request = https.request(
        {
          protocol: "https:",
          hostname: targetUrl.hostname,
          port: targetUrl.port || 443,
          path: `${targetUrl.pathname}${targetUrl.search}`,
          method: "POST",
          headers: {
            ...headers,
            host: targetUrl.host,
            "content-length": Buffer.byteLength(body).toString(),
          },
          agent: false,
          createConnection: () => secureSocket,
        },
        (response) => {
          response.resume();
          response.on("end", () => {
            resolve({
              statusCode: response.statusCode ?? 0,
              statusMessage: response.statusMessage ?? "",
            });
          });
        },
      );

      request.on("error", reject);
      request.end(body);
    } catch (error) {
      reject(error);
    }
  });
}

async function postJson(target: string, body: unknown, headers: Record<string, string>, proxyConfig: ObservabilityConfig) {
  const targetUrl = new URL(target);
  const serializedBody = JSON.stringify(body);
  const proxy = selectProxyForUrl(targetUrl, proxyConfig);

  if (proxy) {
    return requestViaProxy(targetUrl, proxy, serializedBody, headers);
  }

  return requestViaDirectConnection(targetUrl, serializedBody, headers);
}

export default function datadogObservability(pi: ExtensionAPI) {
  const config = buildConfig();
  const host = hostname();
  const project = repoName(process.cwd());

  let exportQueue = Promise.resolve();
  let lastExportStatus = "not_started";
  let lastExportError: string | undefined;
  let sessionTraceId = randomHex(16);
  let currentSessionReason = "startup";
  let currentAgentSpan: SpanState | undefined;
  let currentTurnSpan: SpanState | undefined;
  let currentAgentMetadata: Record<string, Primitive | undefined> = {};
  const turnSpans = new Map<number, SpanState>();
  const toolSpans = new Map<string, SpanState>();

  function queueExport(task: () => Promise<void>) {
    exportQueue = exportQueue.then(task, task);
    return exportQueue;
  }

  async function exportSpan(span: {
    traceId: string;
    spanId: string;
    parentSpanId?: string;
    name: string;
    startTimeUnixNano: string;
    endTimeUnixNano: string;
    attributes: Record<string, Primitive | undefined>;
    kind?: number;
    statusCode?: number;
    statusMessage?: string;
  }) {
    if (!config.enabled) return;

    const apiKey = await readApiKey(config);
    if (!apiKey) {
      lastExportStatus = "disabled_missing_api_key";
      return;
    }

    const payload = {
      resourceSpans: [
        {
          resource: {
            attributes: attributesToOtel({
              "service.name": config.serviceName,
              "service.namespace": config.serviceNamespace,
              "deployment.environment": config.environment,
              "host.name": host,
              "service.version": EXTENSION_VERSION,
            }),
          },
          scopeSpans: [
            {
              scope: {
                name: EXTENSION_NAME,
                version: EXTENSION_VERSION,
              },
              spans: [
                {
                  traceId: span.traceId,
                  spanId: span.spanId,
                  parentSpanId: span.parentSpanId,
                  name: span.name,
                  kind: span.kind ?? INTERNAL_SPAN_KIND,
                  startTimeUnixNano: span.startTimeUnixNano,
                  endTimeUnixNano: span.endTimeUnixNano,
                  attributes: attributesToOtel(span.attributes),
                  ...(span.statusCode
                    ? {
                        status: {
                          code: span.statusCode,
                          ...(span.statusMessage ? { message: span.statusMessage } : {}),
                        },
                      }
                    : {}),
                },
              ],
            },
          ],
        },
      ],
    };

    const response = await postJson(
      `${config.otlpBaseUrl.replace(/\/$/, "")}/v1/traces`,
      payload,
      {
        "content-type": "application/json",
        "DD-API-KEY": apiKey,
      },
      config,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw new Error(`Datadog OTLP export failed: ${response.statusCode} ${response.statusMessage}`.trim());
    }
  }

  function startSpan(
    name: string,
    attributes: Record<string, Primitive | undefined>,
    parentSpan?: SpanState,
    options?: { traceId?: string; kind?: number },
  ): SpanState {
    return {
      traceId: options?.traceId ?? parentSpan?.traceId ?? sessionTraceId,
      spanId: randomHex(8),
      parentSpanId: parentSpan?.spanId,
      name,
      kind: options?.kind,
      startTimeUnixNano: toNanoTime(),
      attributes,
    };
  }

  function finishSpan(
    span: SpanState | undefined,
    extraAttributes?: Record<string, Primitive | undefined>,
    options?: { statusCode?: number; statusMessage?: string },
  ) {
    if (!span) return Promise.resolve();

    return queueExport(async () => {
      try {
        await exportSpan({
          ...span,
          endTimeUnixNano: toNanoTime(),
          attributes: {
            ...span.attributes,
            ...extraAttributes,
          },
          statusCode: options?.statusCode,
          statusMessage: options?.statusMessage,
        });
        lastExportStatus = "ok";
        lastExportError = undefined;
      } catch (error) {
        lastExportStatus = "error";
        lastExportError = safeErrorMessage(error);
        console.error(`[${EXTENSION_NAME}] ${lastExportError}`);
      }
    });
  }

  function instantSpan(
    name: string,
    attributes: Record<string, Primitive | undefined>,
    parentSpan?: SpanState,
    options?: { traceId?: string; kind?: number; statusCode?: number; statusMessage?: string },
  ) {
    const span = startSpan(name, attributes, parentSpan, options);
    return finishSpan(span, undefined, options);
  }

  pi.registerCommand("observability-status", {
    description: "Show Datadog/OpenTelemetry extension status",
    handler: async (_args, ctx) => {
      const proxyStatus = formatProxyStatus(config);
      ctx.ui.notify(
        [
          `enabled=${config.enabled}`,
          `service=${config.serviceName}`,
          `env=${config.environment}`,
          `site=${config.site}`,
          `endpoint=${config.otlpBaseUrl}`,
          `apiKeyConfigured=${Boolean(config.apiKey || config.apiKeyFile)}`,
          `httpsProxy=${proxyStatus.httpsProxy}`,
          `httpProxy=${proxyStatus.httpProxy}`,
          `noProxy=${proxyStatus.noProxy}`,
          `lastExportStatus=${lastExportStatus}`,
          `lastExportError=${lastExportError ?? "none"}`,
        ].join("\n"),
        lastExportStatus === "error" ? "error" : "info",
      );
    },
  });

  pi.on("session_start", async (event, ctx) => {
    sessionTraceId = randomHex(16);
    currentSessionReason = event.reason;
    currentAgentSpan = undefined;
    currentTurnSpan = undefined;
    currentAgentMetadata = {};
    turnSpans.clear();
    toolSpans.clear();

    await instantSpan(
      "pi.session.start",
      {
        "pi.session.reason": event.reason,
        "pi.project": project,
        "pi.cwd.basename": repoName(ctx.cwd),
        "pi.session.file.present": Boolean(ctx.sessionManager.getSessionFile()),
      },
      undefined,
      { traceId: sessionTraceId, statusCode: STATUS_OK },
    );
  });

  pi.on("before_agent_start", async (event) => {
    currentAgentMetadata = {
      "pi.input.image_count": event.images?.length ?? 0,
      ...promptAttributes(event.prompt, config.includePromptText),
    };
  });

  pi.on("agent_start", async (_event, ctx) => {
    currentAgentSpan = startSpan(
      "pi.agent",
      {
        "pi.session.reason": currentSessionReason,
        "pi.project": project,
        "pi.cwd.basename": repoName(ctx.cwd),
        "pi.model.provider": ctx.model?.provider,
        "pi.model.id": ctx.model?.id,
        ...currentAgentMetadata,
      },
      undefined,
      { traceId: sessionTraceId },
    );
  });

  pi.on("turn_start", async (event, ctx) => {
    const parent = currentAgentSpan;
    currentTurnSpan = startSpan(
      "pi.turn",
      {
        "pi.turn.index": event.turnIndex,
        "pi.model.provider": ctx.model?.provider,
        "pi.model.id": ctx.model?.id,
      },
      parent,
    );
    turnSpans.set(event.turnIndex, currentTurnSpan);
  });

  pi.on("before_provider_request", async (event, ctx) => {
    const parent = currentTurnSpan ?? currentAgentSpan;
    await instantSpan(
      "pi.provider.request",
      {
        "pi.model.provider": ctx.model?.provider,
        "pi.model.id": ctx.model?.id,
        "pi.provider.payload_type": typeof event.payload,
        "pi.provider.payload_preview": truncate(JSON.stringify(Object.keys(event.payload ?? {})), 240),
      },
      parent,
      { kind: CLIENT_SPAN_KIND, statusCode: STATUS_OK },
    );
  });

  pi.on("tool_execution_start", async (event) => {
    const parent = currentTurnSpan ?? currentAgentSpan;

    toolSpans.set(
      event.toolCallId,
      startSpan(
        "pi.tool",
        {
          "pi.tool.name": event.toolName,
          "pi.tool.call_id": event.toolCallId,
          ...(config.includeToolArguments
            ? {
                "pi.tool.args": stringifyValue(event.args, 240),
              }
            : {
                "pi.tool.arg_keys": stringifyValue(Object.keys(event.args ?? {}), 240),
              }),
        },
        parent,
      ),
    );
  });

  pi.on("tool_execution_end", async (event) => {
    const span = toolSpans.get(event.toolCallId);
    toolSpans.delete(event.toolCallId);
    await finishSpan(
      span,
      {
        "pi.tool.name": event.toolName,
        "pi.tool.error": event.isError,
      },
      event.isError ? { statusCode: STATUS_ERROR, statusMessage: "tool execution failed" } : { statusCode: STATUS_OK },
    );
  });

  pi.on("turn_end", async (event) => {
    const span = turnSpans.get(event.turnIndex) ?? currentTurnSpan;
    turnSpans.delete(event.turnIndex);
    currentTurnSpan = undefined;
    await finishSpan(
      span,
      {
        "pi.turn.index": event.turnIndex,
        "pi.turn.tool_results": event.toolResults.length,
      },
      { statusCode: STATUS_OK },
    );
  });

  pi.on("agent_end", async (event) => {
    await finishSpan(
      currentAgentSpan,
      {
        "pi.agent.message_count": event.messages.length,
      },
      { statusCode: STATUS_OK },
    );
    currentAgentSpan = undefined;
    currentTurnSpan = undefined;
    currentAgentMetadata = {};
  });

  pi.on("session_shutdown", async (_event) => {
    await instantSpan(
      "pi.session.shutdown",
      {
        "pi.project": project,
      },
      undefined,
      { traceId: sessionTraceId, statusCode: STATUS_OK },
    );
    await exportQueue;
  });
}
