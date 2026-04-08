{inputs, ...}: {
  flake.nixosConfigurations.hbohlen-01 = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit inputs;};
    modules = [
      inputs.home-manager.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.opnix.nixosModules.default
      {imports = import ../nixos;}
      ../modules/user.nix
      ../modules/home.nix
      ../modules/tmux.nix
      ../hosts/hbohlen-01.nix
    ];
  };
}
