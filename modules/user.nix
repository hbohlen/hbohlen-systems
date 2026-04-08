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
}
