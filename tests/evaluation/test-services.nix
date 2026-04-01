{ inputs, ... }:

{
  perSystem = { pkgs, lib, ... }:
    let
      homeManagerModule = inputs.home-manager.nixosModules.home-manager;
      opnixModule = inputs.opnix.nixosModules.default;

      minimalEvalConfig = {
        fileSystems."/" = {
          device = "/dev/sda1";
          fsType = "ext4";
        };
        boot.loader.grub.devices = [ "/dev/sda" ];
        services.caddy.tailscaleEnable = true;
      };
    in
    {
      nix-unit.tests.testCaddyEvaluates = {
        expr =
          let
            result = pkgs.nixos [
              ../../modules/base.nix
              ../../modules/user.nix
              ../../modules/ssh.nix
              ../../modules/tailscale.nix
              ../../modules/caddy.nix
              minimalEvalConfig
              homeManagerModule
              opnixModule
            ];
          in
          result.config.services.caddy.enable == true;
        expected = true;
      };
    };
}
