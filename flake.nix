{
  description = "Minimal NixOS (Hyprland + NVIDIA + WiFi + Kitty) on desktop";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./hosts/desktop/hardware-configuration.nix
        ./hosts/desktop/configuration.nix
      ];
    };
  };
}
