export function env(envMap, name) {
  const value = envMap[name]?.trim();
  return value ? value : undefined;
}

export function envBool(envMap, name, fallback = false) {
  const value = env(envMap, name);
  if (!value) return fallback;
  return ["1", "true", "yes", "on"].includes(value.toLowerCase());
}

export function resolveProxyConfig(envMap = process.env) {
  return {
    httpsProxy:
      env(envMap, "PI_OBSERVABILITY_HTTPS_PROXY") ?? env(envMap, "HTTPS_PROXY") ?? env(envMap, "https_proxy"),
    httpProxy:
      env(envMap, "PI_OBSERVABILITY_HTTP_PROXY") ?? env(envMap, "HTTP_PROXY") ?? env(envMap, "http_proxy"),
    noProxy: env(envMap, "PI_OBSERVABILITY_NO_PROXY") ?? env(envMap, "NO_PROXY") ?? env(envMap, "no_proxy"),
  };
}

export function parseNoProxy(noProxy) {
  if (!noProxy) return [];

  return noProxy
    .split(",")
    .map((entry) => entry.trim().toLowerCase())
    .filter(Boolean);
}

export function noProxyMatches(hostname, noProxy) {
  const normalizedHost = hostname.trim().toLowerCase();
  if (!normalizedHost) return false;

  return parseNoProxy(noProxy).some((entry) => {
    if (entry === "*") return true;

    const normalizedEntry = entry.startsWith(".") ? entry.slice(1) : entry;
    if (!normalizedEntry) return false;

    if (normalizedHost === normalizedEntry) return true;
    return normalizedHost.endsWith(`.${normalizedEntry}`);
  });
}

export function selectProxyForUrl(targetUrl, proxyConfig) {
  const url = targetUrl instanceof URL ? targetUrl : new URL(targetUrl);

  if (noProxyMatches(url.hostname, proxyConfig?.noProxy)) {
    return undefined;
  }

  if (url.protocol === "https:") {
    return proxyConfig?.httpsProxy ?? proxyConfig?.httpProxy;
  }

  if (url.protocol === "http:") {
    return proxyConfig?.httpProxy;
  }

  return undefined;
}

export function sanitizeProxyValue(value) {
  if (!value) return undefined;

  try {
    const url = new URL(value);
    if (url.username || url.password) {
      url.username = "***";
      url.password = "***";
    }
    return url.toString();
  } catch {
    return value.replace(/\/\/([^/@]*)@/, "//***:***@");
  }
}

export function defaultOtlpBaseUrl(site) {
  return `https://otlp.${site}`;
}

export function buildObservabilityConfig(envMap = process.env) {
  const site = env(envMap, "PI_OBSERVABILITY_SITE") ?? env(envMap, "DD_SITE") ?? "datadoghq.com";
  const otlpBaseUrl = env(envMap, "PI_OBSERVABILITY_OTLP_BASE_URL") ?? defaultOtlpBaseUrl(site);
  const apiKey = env(envMap, "PI_OBSERVABILITY_API_KEY") ?? env(envMap, "DD_API_KEY");
  const apiKeyFile = env(envMap, "PI_OBSERVABILITY_API_KEY_FILE") ?? env(envMap, "DD_API_KEY_FILE");
  const enabled = envBool(envMap, "PI_OBSERVABILITY_ENABLE", Boolean(apiKey || apiKeyFile));
  const proxy = resolveProxyConfig(envMap);

  return {
    enabled,
    serviceName: env(envMap, "PI_OBSERVABILITY_SERVICE_NAME") ?? "pi-coding-agent",
    serviceNamespace: env(envMap, "PI_OBSERVABILITY_SERVICE_NAMESPACE") ?? "hbohlen-systems",
    environment: env(envMap, "PI_OBSERVABILITY_ENV") ?? env(envMap, "DD_ENV") ?? "dev",
    site,
    otlpBaseUrl,
    apiKey,
    apiKeyFile,
    includePromptText: envBool(envMap, "PI_OBSERVABILITY_INCLUDE_PROMPT_TEXT", false),
    includeToolArguments: envBool(envMap, "PI_OBSERVABILITY_INCLUDE_TOOL_ARGUMENTS", false),
    ...proxy,
  };
}

export function formatProxyStatus(config) {
  return {
    httpsProxy: sanitizeProxyValue(config.httpsProxy) ?? "none",
    httpProxy: sanitizeProxyValue(config.httpProxy) ?? "none",
    noProxy: config.noProxy ?? "none",
  };
}
