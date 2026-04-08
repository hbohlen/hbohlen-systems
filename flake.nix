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
        ./modules
        ./parts
        ./tests/unit
        ./tests/evaluation
      ];

      perSystem = {pkgs, ...}: {
        nix-unit.inputs = {
          inherit (inputs) nixpkgs flake-parts nix-unit llm-agents;
        };
        nix-unit.allowNetwork = true;

        checks = {
          formatting = pkgs.runCommand "alejandra-check" {} ''
            ${pkgs.alejandra}/bin/alejandra -c \
              ${./flake.nix} \
              ${./modules} \
              ${./tests}
            touch $out
          '';

          statix = pkgs.runCommand "statix-check" {} ''
            ${pkgs.statix}/bin/statix check ${./flake.nix}
            touch $out
          '';

          deadnix = pkgs.runCommand "deadnix-check" {} ''
            ${pkgs.deadnix}/bin/deadnix \
              ${./flake.nix} \
              ${./modules} \
              ${./tests}
            touch $out
          '';
        };
      };
    };
}
