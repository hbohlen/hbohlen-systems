{inputs, ...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    homeManagerModule = inputs.home-manager.nixosModules.home-manager;

    minimalEvalConfig = {
      fileSystems."/" = {
        device = "/dev/sda1";
        fsType = "ext4";
      };
      boot.loader.grub.devices = ["/dev/sda"];
    };
  in {
    nix-unit.tests.testSshEvaluates = {
      expr = let
        result = pkgs.nixos [
          ../../nixos/base.nix
          ../../modules/user.nix
          ../../nixos/ssh.nix
          minimalEvalConfig
          homeManagerModule
        ];
      in
        result.config.services.openssh.enable == true;
      expected = true;
    };
  };
}
