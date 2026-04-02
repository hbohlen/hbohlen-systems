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
    services.caddy.opencodeHost = lib.mkOption {
      type = lib.types.str;
      default = "opencode.hbohlen.systems";
      description = "Tailscale hostname for opencode";
    };
  };

  config = lib.mkIf config.services.caddy.tailscaleEnable {
    services.caddy = {
      enable = true;
      environmentFile = "/var/lib/opnix/secrets/caddyTailscaleAuthKey";
      package = pkgs.caddy.withPlugins {
        plugins = [tailscalePlugin];
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
