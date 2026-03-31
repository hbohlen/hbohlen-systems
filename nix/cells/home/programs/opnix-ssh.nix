# SSH keys fetched from 1Password via opnix
{ config, pkgs, ... }:

{
  # Required Home Manager state version
  home.stateVersion = "24.11";

  # Note: opnix integration requires OP_SERVICE_ACCOUNT_TOKEN
  # This is set via the opnix-bootstrap service which stores token at /etc/opnix-token

  programs.ssh = {
    enable = true;
    extraConfig = ''
      # Use SSH agent socket if available
      IdentityAgent ~/.ssh/agent.sock
    '';
  };

  home.sessionVariables = {
    OP_SERVICE_ACCOUNT_TOKEN_FILE = "/etc/opnix-token";
  };
}
