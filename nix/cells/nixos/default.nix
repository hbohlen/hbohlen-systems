{ inputs, ... }:
{
  flake.nixosConfigurations = {
    hbohlen-01 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.home-manager.nixosModules.default
        inputs.disko.nixosModules.disko
        ./modules/disko.nix
        ./modules/base.nix
        ./modules/ssh-hardening.nix
        ./modules/tailscale-enhanced.nix
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
