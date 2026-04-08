{
  pkgs,
  lib,
  config,
  ...
}: let
  tailscalePlugin = "github.com/tailscale/caddy-tailscale@v0.0.0-20250207163903-69a970c84556";
in {
  options = with lib.types; {
    services.caddy.tailscaleEnable = lib.mkEnableOption "Enable caddy tailscale integration";
    services.caddy.tailnetSuffix = lib.mkOption {
      type = lib.types.str;
      default = "taile0585b.ts.net";
      description = "Tailscale tailnet suffix for MagicDNS names";
    };
    services.caddy.opencodeHost = lib.mkOption {
      type = lib.types.str;
      default = "opencode.${config.services.caddy.tailnetSuffix}";
      description = "Tailscale hostname for opencode";
    };
  };

  config = lib.mkIf config.services.caddy.tailscaleEnable {
    systemd.services.caddy-tailscale-env = {
      description = "Format Tailscale auth key for Caddy EnvironmentFile";
      before = ["caddy.service"];
      after = ["opnix-secrets.service"];
      wants = ["opnix-secrets.service"];
      wantedBy = ["caddy.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c 'KEY=$(< /var/lib/opnix/secrets/caddyTailscaleAuthKey); [[ \"$KEY\" == TS_AUTHKEY=* ]] || echo \"TS_AUTHKEY=$KEY\" > /var/lib/opnix/secrets/caddyTailscaleAuthKey'";
      };
    };

    services.caddy = {
      enable = true;
      environmentFile = "/var/lib/opnix/secrets/caddyTailscaleAuthKey";
      package = pkgs.caddy.withPlugins {
        plugins = [tailscalePlugin];
        hash = "sha256-JergBCe1TiZY2yn/trW9e24uwVoUt0UcLzgfQ+ONpJY=";
      };

      virtualHosts = {
        "${config.services.caddy.opencodeHost}" = {
          extraConfig = ''
            bind tailscale/opencode
            reverse_proxy 127.0.0.1:8081
          '';
        };
      };
    };
  };
}
