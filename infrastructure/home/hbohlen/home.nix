{ config, pkgs, ... }:

{
  home.username = "hbohlen";
  home.homeDirectory = "/home/hbohlen";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "Harrison Bohlen";
    userEmail = "you@example.com";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    ripgrep fd jq tree stow
  ];
}
