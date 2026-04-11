{
  pkgs,
  lib,
  config,
  ...
}: let
  tailscalePlugin = "github.com/tailscale/caddy-tailscale@v0.0.0-20250207163903-69a970c84556";
  cfg = config.services.caddy;
in {
  options.services.caddy = {
    tailscaleEnable = lib.mkEnableOption "Enable caddy tailscale integration";

    tailnetSuffix = lib.mkOption {
      type = lib.types.str;
      default = "taile0585b.ts.net";
      description = "Tailscale tailnet suffix for MagicDNS names";
    };

    opencodeHost = lib.mkOption {
      type = lib.types.str;
      default = "opencode.${cfg.tailnetSuffix}";
      description = "Tailscale hostname for opencode";
    };

    piWebUiHost = lib.mkOption {
      type = lib.types.str;
      default = "pi-web-ui.${cfg.tailnetSuffix}";
      description = "Tailscale hostname for pi-web-ui";
    };

    enablePiWebUi = lib.mkOption {
      type = lib.types.bool;
      default = config.services.pi-web-ui.enable or false;
      description = "Enable Caddy reverse proxy for pi-web-ui";
    };
  };

  config = lib.mkIf cfg.tailscaleEnable {
    # Service to prepare Tailscale auth key for Caddy
    systemd.services.caddy-tailscale-env = {
      description = "Format Tailscale auth key for Caddy EnvironmentFile";
      before = ["caddy.service"];
      after = ["opnix-secrets.service"];
      wants = ["opnix-secrets.service"];
      wantedBy = ["caddy.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c 'KEY=$(< /var/lib/opnix/secrets/caddyTailscaleAuthKey); [[ \"$$KEY\" == TS_AUTHKEY=* ]] || echo \"TS_AUTHKEY=$$KEY\" > /var/lib/opnix/secrets/caddyTailscaleAuthKey'";
      };
    };

    services.caddy = {
      enable = true;
      environmentFile = "/var/lib/opnix/secrets/caddyTailscaleAuthKey";
      package = pkgs.caddy.withPlugins {
        plugins = [tailscalePlugin];
        hash = "sha256-JergBCe1TiZY2yn/trW9e24uwVoUt0UcLzgfQ+ONpJY=";
      };

      virtualHosts = lib.mkMerge [
        {
          # opencode virtual host
          "${cfg.opencodeHost}" = {
            extraConfig = ''
              bind tailscale/opencode
              reverse_proxy 127.0.0.1:8081
            '';
          };
        }

        (lib.mkIf cfg.enablePiWebUi {
          # pi-web-ui virtual host
          "${cfg.piWebUiHost}" = {
            extraConfig = ''
              bind tailscale/pi-web-ui
              reverse_proxy 127.0.0.1:${toString (config.services.pi-web-ui.port or 3000)}

              # Headers
              header {
                # Security headers
                Strict-Transport-Security "max-age=31536000; includeSubDomains"
                X-Content-Type-Options "nosniff"
                X-Frame-Options "DENY"
                X-XSS-Protection "1; mode=block"
                Referrer-Policy "strict-origin-when-cross-origin"

                # Remove server header
                -Server
              }

              # Timeouts for streaming responses
              reverse_proxy {
                header_up Host {host}
                header_up X-Real-IP {remote}
                header_up X-Forwarded-For {remote}
                header_up X-Forwarded-Proto {scheme}

                # Support for SSE streaming
                flush_interval -1
              }
            '';
          };
        })
      ];
    };
  };
}
