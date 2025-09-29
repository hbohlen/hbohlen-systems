{
  description = "hbohlen-systems: minimal desktop host + devShell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [ git just ripgrep fd alejandra nixfmt-rfc-style direnv nix-direnv ];
    };

    packages.${system}.formatters = pkgs.writeShellScriptBin "fmt" ''
      alejandra .
      nixfmt --width 100 $(git ls-files '*.nix' || true)
    '';

    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./infrastructure/nixos/hosts/desktop/hardware-configuration.nix
        ./infrastructure/nixos/hosts/desktop/configuration.nix

        # --- Home Manager as a NixOS module ---
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.hbohlen = import ./infrastructure/home/hbohlen/home.nix;
        }
      ];
    };
  };
}
