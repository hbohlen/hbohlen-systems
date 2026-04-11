import test from "node:test";
import assert from "node:assert/strict";

import {
  buildObservabilityConfig,
  defaultOtlpBaseUrl,
  formatProxyStatus,
  noProxyMatches,
  resolveProxyConfig,
  sanitizeProxyValue,
  selectProxyForUrl,
} from "./datadog-observability-config.mjs";

test("default OTLP base URL follows Datadog site naming", () => {
  assert.equal(defaultOtlpBaseUrl("datadoghq.com"), "https://otlp.datadoghq.com");
  assert.equal(defaultOtlpBaseUrl("us5.datadoghq.com"), "https://otlp.us5.datadoghq.com");
  assert.equal(defaultOtlpBaseUrl("datadoghq.eu"), "https://otlp.datadoghq.eu");
});

test("PI_OBSERVABILITY proxy variables override standard proxy env vars", () => {
  const config = buildObservabilityConfig({
    PI_OBSERVABILITY_HTTPS_PROXY: "https://pi-user:pi-pass@pi-proxy.internal:8443",
    PI_OBSERVABILITY_HTTP_PROXY: "http://pi-http.internal:8080",
    PI_OBSERVABILITY_NO_PROXY: "localhost,.svc",
    HTTPS_PROXY: "https://default-proxy.internal:9443",
    HTTP_PROXY: "http://default-http.internal:9080",
    NO_PROXY: "127.0.0.1",
  });

  assert.equal(config.httpsProxy, "https://pi-user:pi-pass@pi-proxy.internal:8443");
  assert.equal(config.httpProxy, "http://pi-http.internal:8080");
  assert.equal(config.noProxy, "localhost,.svc");
});

test("standard proxy env vars are used when PI_OBSERVABILITY overrides are absent", () => {
  const proxy = resolveProxyConfig({
    HTTPS_PROXY: "https://default-proxy.internal:9443",
    HTTP_PROXY: "http://default-http.internal:9080",
    NO_PROXY: "127.0.0.1,localhost",
  });

  assert.deepEqual(proxy, {
    httpsProxy: "https://default-proxy.internal:9443",
    httpProxy: "http://default-http.internal:9080",
    noProxy: "127.0.0.1,localhost",
  });
});

test("lowercase standard proxy env vars are supported as a final fallback", () => {
  const proxy = resolveProxyConfig({
    https_proxy: "https://lowercase-proxy.internal:9443",
    http_proxy: "http://lowercase-http.internal:9080",
    no_proxy: "example.internal",
  });

  assert.deepEqual(proxy, {
    httpsProxy: "https://lowercase-proxy.internal:9443",
    httpProxy: "http://lowercase-http.internal:9080",
    noProxy: "example.internal",
  });
});

test("NO_PROXY exact host matching bypasses proxy", () => {
  assert.equal(noProxyMatches("otlp-http-intake.logs.datadoghq.com", "otlp-http-intake.logs.datadoghq.com"), true);
  assert.equal(
    selectProxyForUrl("https://otlp-http-intake.logs.datadoghq.com/v1/traces", {
      httpsProxy: "http://proxy.internal:8080",
      noProxy: "otlp-http-intake.logs.datadoghq.com",
    }),
    undefined,
  );
});

test("NO_PROXY suffix matching bypasses proxy for subdomains", () => {
  assert.equal(noProxyMatches("otlp-http-intake.logs.datadoghq.com", ".datadoghq.com"), true);
  assert.equal(noProxyMatches("api.datadoghq.eu", "datadoghq.eu"), true);
  assert.equal(noProxyMatches("example.com", ".datadoghq.com"), false);
});

test("NO_PROXY wildcard bypasses all proxies", () => {
  assert.equal(noProxyMatches("otlp-http-intake.logs.datadoghq.com", "*"), true);
  assert.equal(
    selectProxyForUrl("https://otlp-http-intake.logs.datadoghq.com/v1/traces", {
      httpsProxy: "http://proxy.internal:8080",
      noProxy: "*",
    }),
    undefined,
  );
});

test("proxy selection is explicit by target protocol", () => {
  assert.equal(
    selectProxyForUrl("https://otlp-http-intake.logs.datadoghq.com/v1/traces", {
      httpsProxy: "https://secure-proxy.internal:8443",
      httpProxy: "http://fallback-proxy.internal:8080",
    }),
    "https://secure-proxy.internal:8443",
  );

  assert.equal(
    selectProxyForUrl("https://otlp-http-intake.logs.datadoghq.com/v1/traces", {
      httpProxy: "http://fallback-proxy.internal:8080",
    }),
    "http://fallback-proxy.internal:8080",
  );

  assert.equal(
    selectProxyForUrl("http://example.internal/health", {
      httpsProxy: "https://secure-proxy.internal:8443",
      httpProxy: "http://fallback-proxy.internal:8080",
    }),
    "http://fallback-proxy.internal:8080",
  );
});

test("proxy status output redacts credentials", () => {
  const status = formatProxyStatus({
    httpsProxy: "https://user:super-secret@proxy.internal:8443",
    httpProxy: "http://token-only@proxy.internal:8080",
    noProxy: "localhost,.svc",
  });

  assert.equal(status.httpsProxy, "https://***:***@proxy.internal:8443/");
  assert.equal(status.httpProxy, "http://***:***@proxy.internal:8080/");
  assert.equal(status.noProxy, "localhost,.svc");
  assert.ok(!status.httpsProxy.includes("super-secret"));
  assert.ok(!status.httpsProxy.includes("user"));
  assert.ok(!status.httpProxy.includes("token-only"));
});

test("sanitizeProxyValue preserves non-credential proxy values", () => {
  assert.equal(sanitizeProxyValue("http://proxy.internal:8080"), "http://proxy.internal:8080/");
  assert.equal(sanitizeProxyValue("socks5://proxy.internal:1080"), "socks5://proxy.internal:1080");
  assert.equal(sanitizeProxyValue(undefined), undefined);
});
