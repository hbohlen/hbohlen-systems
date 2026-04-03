{
  config,
  pkgs,
  lib,
  ...
}: {
  home-manager.users.hbohlen = {pkgs, ...}: {
    home = {
      stateVersion = "24.11";
      homeDirectory = "/home/hbohlen";
      username = "hbohlen";
      sessionVariables = {
        OP_SERVICE_ACCOUNT_TOKEN_FILE = "/etc/opnix-token";
      };
    };

    programs.ssh = {
      enable = true;
      extraConfig = ''
        IdentityAgent ~/.ssh/agent.sock
      '';
    };

    programs.tmux = {
      enable = true;
      extraConfig = ''
        set -g extended-keys on
        set -g extended-keys-format csi-u
      '';
    };
  };
}
