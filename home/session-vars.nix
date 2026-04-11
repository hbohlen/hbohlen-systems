_: {
  home.sessionVariables = {
    OP_SERVICE_ACCOUNT_TOKEN_FILE = "/etc/opnix-token";

    PI_OBSERVABILITY_ENABLE = "1";
    PI_OBSERVABILITY_SERVICE_NAME = "pi-observability";
    PI_OBSERVABILITY_SERVICE_NAMESPACE = "hbohlen-systems";
    PI_OBSERVABILITY_ENV = "prod";
    PI_OBSERVABILITY_SITE = "us5.datadoghq.com";
    PI_OBSERVABILITY_API_KEY_FILE = "/var/lib/opnix/secrets/datadogApiKey";
  };
}
