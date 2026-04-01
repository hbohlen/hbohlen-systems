{ inputs, ... }:

{
  flake.nixosConfigurations.hbohlen-01 = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      inputs.home-manager.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.opnix.nixosModules.default
      ./base.nix
      ./disko.nix
      ./user.nix
      ./ssh.nix
      ./tailscale.nix
      ./security.nix
      ./caddy.nix
      ./opencode.nix
      ./gno.nix
      ./hosts/hbohlen-01.nix
    ];
  };
}
