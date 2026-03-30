{ inputs, ... }:
{
  flake.nixosConfigurations = {
    hbohlen-01 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.disko.nixosModules.disko
        ./modules/disko.nix
        ./modules/base.nix
        ./hosts/hbohlen-01/default.nix
      ];
    };
  };
}
