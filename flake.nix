{
  description = "hbohlen-systems: minimal desktop host + devShell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    # ---- dev tools for working on this repo (no effect on your system) ----
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        git just ripgrep fd
        alejandra nixfmt-rfc-style
        direnv nix-direnv
      ];
      shellHook = ''
        echo "Tip: run: echo 'use nix' > .envrc && direnv allow"
      '';
    };

    packages.${system}.formatters = pkgs.writeShellScriptBin "fmt" ''
      alejandra .
      nixfmt --width 100 $(git ls-files '*.nix' || true)
    '';

    # ---- your existing NixOS host ----
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./infrastructure/nixos/hosts/desktop/hardware-configuration.nix
        ./infrastructure/nixos/hosts/desktop/configuration.nix
      ];
    };
  };
}
