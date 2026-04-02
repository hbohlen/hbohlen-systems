{
  config,
  pkgs,
  inputs,
  ...
}: {
  # NixOS: user creation
  users.users.hbohlen = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICP6MnCIoDGFnx42wAmVgoNxaHxEtRnOF10d3q/xOIZG hbohlen@hetzner"
    ];
  };

  programs.fish.enable = true;

  security.sudo.wheelNeedsPassword = false;

  # Home Manager: user-level config
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.hbohlen = {pkgs, ...}: {
      home.stateVersion = "24.11";

      programs.ssh = {
        enable = true;
        extraConfig = ''
          IdentityAgent ~/.ssh/agent.sock
        '';
      };

      home.sessionVariables = {
        OP_SERVICE_ACCOUNT_TOKEN_FILE = "/etc/opnix-token";
      };
    };
  };
}
