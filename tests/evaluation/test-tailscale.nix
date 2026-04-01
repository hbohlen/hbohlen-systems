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
      };
    in
    {
      nix-unit.tests.testTailscaleEvaluates = {
        expr =
          let
            result = pkgs.nixos [
              ../../modules/base.nix
              ../../modules/user.nix
              ../../modules/ssh.nix
              ../../modules/tailscale.nix
              minimalEvalConfig
              homeManagerModule
              opnixModule
            ];
          in
          result.config.services.tailscale.enable == true;
        expected = true;
      };
    };
}
