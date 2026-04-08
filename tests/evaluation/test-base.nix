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
    nix-unit.tests.testBaseEvaluates = {
      expr = let
        result = pkgs.nixos [../../nixos/base.nix minimalEvalConfig];
      in
        result.config.networking.hostName != null;
      expected = true;
    };

    nix-unit.tests.testUserEvaluates = {
      expr = let
        result = pkgs.nixos [../../nixos/base.nix ../../modules/user.nix minimalEvalConfig homeManagerModule];
      in
        result.config.users.users.hbohlen.isNormalUser;
      expected = true;
    };
  };
}
