# GNU General Public License v3.0
# GNO Web UI - NixOS Module
# Provides systemd service for running gno serve and tailscale serve
{ config, lib, pkgs, ... }:

let
  cfg = config.services.gno-serve;
in
{
  options.services.gno-serve = {
    enable = lib.mkEnableOption "GNO web UI served via Tailscale";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8081;
      description = "Port for gno serve to listen on (8080 is used by opencode)";
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "gno.hbohlen.systems.ts.net";
      description = "Tailscale Magic DNS hostname";
    };
  };

  config = lib.mkIf cfg.enable {
    # GNO serve service
    systemd.services.gno-serve = {
      description = "GNO web UI server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "tailscaled.service" "gno-daemon.service" ];
      wants = [ "network-online.target" "tailscaled.service" ];
      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = [
          "HOME=/home/hbohlen"
        ];
        ExecStart = "${lib.getExe pkgs.gno} serve --port ${toString cfg.port} --hostname 127.0.0.1";
        # Only listen on localhost
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    };

    # Tailscale serve configuration
    systemd.services.tailscale-serve-gno = {
      description = "Configure Tailscale serve for GNO";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "tailscaled.service" "gno-serve.service" ];
      wants = [ "gno-serve.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Serve the GNO web UI on the specified port via Tailscale HTTPS
        ExecStart = "${lib.getExe pkgs.tailscale} serve --bg ${toString cfg.port}";
        ExecStop = "${lib.getExe pkgs.tailscale} serve reset";
      };
    };
  };
}
