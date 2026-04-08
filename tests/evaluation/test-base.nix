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
        result = pkgs.nixos [../../nixos/base.nix ../../nixos/user.nix minimalEvalConfig homeManagerModule];
      in
        result.config.users.users.hbohlen.isNormalUser;
      expected = true;
    };

    nix-unit.tests.testHomeModuleComposes = {
      expr = let
        result = pkgs.nixos [../../nixos/user.nix ../../home/default.nix minimalEvalConfig homeManagerModule];
        homeConfig = lib.attrsets.attrByPath ["home-manager" "users" "hbohlen"] null result.config;
      in
        homeConfig.home.username == "hbohlen";
      expected = true;
    };

    nix-unit.tests.testHomeModuleImportedConfigsCompose = {
      expr = let
        result = pkgs.nixos [../../nixos/user.nix ../../home/default.nix minimalEvalConfig homeManagerModule];
        homeConfig = lib.attrsets.attrByPath ["home-manager" "users" "hbohlen"] null result.config;
      in
        homeConfig.programs.tmux.enable
        && homeConfig.programs.ssh.enable
        && homeConfig.home.sessionVariables.OP_SERVICE_ACCOUNT_TOKEN_FILE == "/etc/opnix-token";
      expected = true;
    };
  };
}
