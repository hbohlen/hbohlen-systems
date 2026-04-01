{ config, lib, pkgs, inputs, ... }:

let
  opencodePkg = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
in
{
  options.services.opencode = {
    enable = lib.mkEnableOption "opencode web UI";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for opencode web UI";
    };
  };

  config = lib.mkIf config.services.opencode.enable {
    systemd.services.opencode-web = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe opencodePkg} web --port ${toString config.services.opencode.port} --hostname 127.0.0.1";
        Restart = "on-failure";
        RestartSec = "5s";
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };
  };
}
