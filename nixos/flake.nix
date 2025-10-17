
{
    description = "Yoga 7 NixOS Configuration";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

        impermanence.url = "github:nix-community/impermanence";

        disko = {
            url = "github:nix-community/disko";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = { self, nixpkgs, impermanence, disko, ... }: {
        nixosConfigurations.yoga7 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";

            modules = [
                disko.nixosModules.disko
                impermanence.nixosModules.impermanence
                ./configuration.nix
                ./disko.nix
            ];
        };
    };
}