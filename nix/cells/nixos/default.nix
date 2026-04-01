{ inputs, ... }:
{
  flake.nixosConfigurations = {
    hbohlen-01 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        inputs.home-manager.nixosModules.default
        inputs.disko.nixosModules.disko
        inputs.opnix.nixosModules.default
        ./modules/disko.nix
        ./modules/base.nix
        ./modules/ssh-hardening.nix
        ./modules/fail2ban.nix
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.hbohlen = import ../home/programs/opnix-ssh.nix;
        }
        ./modules/opnix-bootstrap.nix
        ./modules/caddy-tailscale.nix
        ./modules/opencode.nix
        ./hosts/hbohlen-01/default.nix
      ];
    };
  };
}
