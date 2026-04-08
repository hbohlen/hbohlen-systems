{
  description = "PROJECT_DESCRIPTION";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      imports = [
        ./nix/cells/devshells
        # Add more cells here as needed:
        # ./nix/cells/packages
        # ./nix/cells/home
        # ./nix/cells/nixos
      ];
    };
}
