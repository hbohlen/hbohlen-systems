# GNU General Public License v3.0
# GNO Knowledge Engine - NixOS Module
# Provides systemd service for running gno daemon

{ config, lib, pkgs, ... }:

let
  cfg = config.services.gno-daemon;
in
{
  options.services.gno-daemon = {
    enable = lib.mkEnableOption "GNO knowledge engine daemon";
    user = lib.mkOption {
      type = lib.types.str;
      default = "hbohlen";
      description = "User to run gno daemon as";
    };
    homeDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/hbohlen";
      description = "Home directory for gno configuration and data";
    };
    collectionPath = lib.mkOption {
      type = lib.types.path;
      default = "/home/hbohlen/mnemosyne";
      description = "Path to the directory to index";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure the collection directory exists on boot
    systemd.tmpfiles.rules = [
      "d ${cfg.collectionPath} 0755 ${cfg.user} ${cfg.user} -"
    ];

    systemd.services.gno-daemon = {
      description = "GNO knowledge engine daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "tailscaled.service" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.user;
        Restart = "on-failure";
        RestartSec = "5s";
        TimeoutStartSec = "30s";
        Environment = [
          "HOME=${cfg.homeDir}"
        ];
        ExecStart = "${lib.getExe pkgs.nix} run github:numtide/llm-agents.nix#gno -- daemon";
        WorkingDirectory = cfg.homeDir;
        # Security hardening
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.collectionPath ];
      };
    };
  };
}
