{
  config,
  lib,
  pkgs,
  ...
}: let
  daemonCfg = config.services.gno-daemon;
  serveCfg = config.services.gno-serve;
in {
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

  options.services.gno-serve = {
    enable = lib.mkEnableOption "GNO web UI served via Tailscale";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8082;
      description = "Port for gno serve to listen on (8080 is used by opencode, 8081 by opencode web)";
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "gno.hbohlen.systems.ts.net";
      description = "Tailscale Magic DNS hostname";
    };
  };

  config = {
    # GNO daemon
    systemd.services.gno-daemon = lib.mkIf daemonCfg.enable {
      description = "GNO knowledge engine daemon";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target" "tailscaled.service"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "simple";
        User = daemonCfg.user;
        Group = daemonCfg.user;
        Restart = "on-failure";
        RestartSec = "5s";
        TimeoutStartSec = "30s";
        Environment = [
          "HOME=${daemonCfg.homeDir}"
        ];
        ExecStart = "${lib.getExe pkgs.nix} run github:numtide/llm-agents.nix#gno -- daemon";
        WorkingDirectory = daemonCfg.homeDir;
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [daemonCfg.collectionPath];
      };
    };

    # GNO serve service
    systemd.services.gno-serve = lib.mkIf serveCfg.enable {
      description = "GNO web UI server";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target" "tailscaled.service" "gno-daemon.service"];
      wants = ["network-online.target" "tailscaled.service"];
      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "5s";
        Environment = [
          "HOME=/home/hbohlen"
        ];
        ExecStart = "${lib.getExe pkgs.nix} run github:numtide/llm-agents.nix#gno -- serve --port ${toString serveCfg.port}";
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    };

    # Tailscale serve configuration
    systemd.services.tailscale-serve-gno = lib.mkIf serveCfg.enable {
      description = "Configure Tailscale serve for GNO";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target" "tailscaled.service" "gno-serve.service"];
      wants = ["gno-serve.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${lib.getExe pkgs.tailscale} serve --bg ${toString serveCfg.port}";
        ExecStop = "${lib.getExe pkgs.tailscale} serve reset";
      };
    };

    # Ensure collection directory exists
    systemd.tmpfiles.rules = lib.mkIf daemonCfg.enable [
      "d ${daemonCfg.collectionPath} 0755 ${daemonCfg.user} ${daemonCfg.user} -"
    ];
  };
}
