{...}: {
  home-manager.users.hbohlen = {pkgs, ...}: {
    imports = [
      ./tmux.nix
      ./ssh-client.nix
      ./session-vars.nix
    ];

    home = {
      stateVersion = "24.11";
      homeDirectory = "/home/hbohlen";
      username = "hbohlen";
    };
  };
}
