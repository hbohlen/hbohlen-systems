{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  opencodePkg = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
  opencodeCfg = config.services.opencode;
in {
  options.services.opencode = {
    enable = lib.mkEnableOption "opencode web UI";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8081;
      description = "Port for opencode web UI";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "hbohlen";
      description = "User to run opencode web service as";
    };
    homeDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/hbohlen";
      description = "Home directory for opencode web service";
    };
  };

  config = lib.mkIf opencodeCfg.enable {
    systemd.services.opencode-web = {
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${lib.getExe opencodePkg} web --port ${toString opencodeCfg.port} --hostname 127.0.0.1";
        User = opencodeCfg.user;
        WorkingDirectory = opencodeCfg.homeDir;
        Environment = ["HOME=${opencodeCfg.homeDir}"];
        Restart = "on-failure";
        RestartSec = "5s";
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };
  };
}
