{
  description = "hbohlen-systems: minimal desktop host";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./infrastructure/nixos/hosts/desktop/hardware-configuration.nix
        ./infrastructure/nixos/hosts/desktop/configuration.nix
      ];
    };
  };
}
