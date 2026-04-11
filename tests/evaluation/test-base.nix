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
    nix-unit = {
      tests = {
        testBaseEvaluates = {
          expr = let
            result = pkgs.nixos [../../nixos/base.nix minimalEvalConfig];
          in
            result.config.networking.hostName != null;
          expected = true;
        };

        testUserEvaluates = {
          expr = let
            result = pkgs.nixos [../../nixos/base.nix ../../nixos/user.nix minimalEvalConfig homeManagerModule];
          in
            result.config.users.users.hbohlen.isNormalUser;
          expected = true;
        };

        testHomeModuleComposes = {
          expr = let
            result = pkgs.nixos [
              ../../nixos/user.nix
              ../../home/default.nix
              minimalEvalConfig
              homeManagerModule
              {_module.args.inputs = inputs;}
            ];
            homeConfig = lib.attrsets.attrByPath ["home-manager" "users" "hbohlen"] null result.config;
          in
            homeConfig.home.username == "hbohlen";
          expected = true;
        };

        testHomeModuleImportedConfigsCompose = {
          expr = let
            result = pkgs.nixos [
              ../../nixos/user.nix
              ../../home/default.nix
              minimalEvalConfig
              homeManagerModule
              {_module.args.inputs = inputs;}
            ];
            homeConfig = lib.attrsets.attrByPath ["home-manager" "users" "hbohlen"] null result.config;
          in
            homeConfig.programs.tmux.enable
            && homeConfig.programs.ssh.enable
            && homeConfig.home.sessionVariables.OP_SERVICE_ACCOUNT_TOKEN_FILE == "/etc/opnix-token"
            && homeConfig.home.sessionVariables.PI_OBSERVABILITY_ENABLE == "1"
            && homeConfig.home.sessionVariables.PI_OBSERVABILITY_API_KEY_FILE == "/var/lib/opnix/secrets/datadogApiKey";
          expected = true;
        };

        testHomePackagesContainLlmAgentTools = {
          expr = let
            result = pkgs.nixos [
              ../../nixos/user.nix
              ../../home/default.nix
              minimalEvalConfig
              homeManagerModule
              {_module.args.inputs = inputs;}
            ];
            homeConfig = lib.attrsets.attrByPath ["home-manager" "users" "hbohlen"] null result.config;
            packageNames = map (pkg: pkg.pname or (lib.getName pkg)) homeConfig.home.packages;
          in
            builtins.elem "beads" packageNames
            && builtins.elem "pi" packageNames;
          expected = true;
        };

        testHomeInstallsPiObservabilityExtension = {
          expr = let
            result = pkgs.nixos [
              ../../nixos/user.nix
              ../../home/default.nix
              minimalEvalConfig
              homeManagerModule
              {_module.args.inputs = inputs;}
            ];
            homeConfig = lib.attrsets.attrByPath ["home-manager" "users" "hbohlen"] null result.config;
          in
            lib.hasAttrByPath [".pi/agent/extensions/datadog-observability.ts"] homeConfig.home.file
            && lib.hasAttrByPath [".pi/agent/extensions/datadog-observability-config.mjs"] homeConfig.home.file;
          expected = true;
        };
      };
    };
  };
}
