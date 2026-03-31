{ inputs, ... }:

{
  flake.homeConfigurations.hbohlen = inputs.home-manager.lib.homeManagerConfiguration {
    system = "x86_64-linux";
    homeDirectory = "/home/hbohlen";
    username = "hbohlen";
    modules = [
      ./programs/opnix-ssh.nix
    ];
  };
}
