{
  description = "hbohlen-systems - dendritic personal infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-unit = {
      url = "github:nix-community/nix-unit";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];

      imports = [
        inputs.nix-unit.modules.flake.default
        ./parts
        ./tests/unit
        ./tests/evaluation
      ];

      perSystem = {pkgs, ...}: let
        # Mirror the deployed hbohlen-01 assembly so nix flake check explicitly
        # evaluates the Home Manager user path used by this repository.
        hbohlen01Eval = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit inputs;};
          modules = [
            inputs.home-manager.nixosModules.default
            inputs.disko.nixosModules.disko
            inputs.opnix.nixosModules.default
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
            {imports = import ./nixos;}
            ./home
            ./hosts/hbohlen-01.nix
          ];
        };
        hbohlen01HomeConfig = hbohlen01Eval.config.home-manager.users.hbohlen;
      in {
        nix-unit.inputs = {
          inherit (inputs) nixpkgs flake-parts nix-unit llm-agents;
        };
        nix-unit.allowNetwork = true;

        checks = {
          formatting = pkgs.runCommand "alejandra-check" {} ''
            ${pkgs.alejandra}/bin/alejandra -c \
              ${./flake.nix} \
              ${./parts} \
              ${./hosts} \
              ${./nixos} \
              ${./home} \
              ${./tests} \
              ${./lib} \
              ${./scripts}
            touch $out
          '';

          statix = pkgs.runCommand "statix-check" {} ''
            ${pkgs.statix}/bin/statix check ${./.}
            touch $out
          '';

          deadnix = pkgs.runCommand "deadnix-check" {} ''
            ${pkgs.deadnix}/bin/deadnix \
              ${./flake.nix} \
              ${./parts} \
              ${./hosts} \
              ${./nixos} \
              ${./home} \
              ${./tests} \
              ${./lib} \
              ${./scripts}
            touch $out
          '';

          # Explicitly validate the deployed host path used in this repo:
          # nixosConfigurations.hbohlen-01.config.home-manager.users.hbohlen
          hbohlen-01-eval =
            pkgs.runCommand "hbohlen-01-eval-check" {
              inherit (hbohlen01HomeConfig.home) username;
            } ''
              test "$username" = "hbohlen"
              touch $out
            '';
        };
      };
    };
}
