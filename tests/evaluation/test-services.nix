{inputs, ...}: {
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    homeManagerModule = inputs.home-manager.nixosModules.home-manager;
    opnixModule = inputs.opnix.nixosModules.default;

    minimalSystemConfig = {
      fileSystems."/" = {
        device = "/dev/sda1";
        fsType = "ext4";
      };
      boot.loader.grub.devices = ["/dev/sda"];
    };

    minimalEvalConfig =
      minimalSystemConfig
      // {
        services.caddy.tailscaleEnable = true;
      };
  in {
    nix-unit.tests.testCaddyEvaluates = {
      expr = let
        result = pkgs.nixos [
          ../../nixos/base.nix
          ../../modules/user.nix
          ../../nixos/ssh.nix
          ../../nixos/tailscale.nix
          ../../nixos/caddy.nix
          minimalEvalConfig
          homeManagerModule
          opnixModule
        ];
      in
        result.config.services.caddy.enable == true;
      expected = true;
    };

    nix-unit.tests.testSecurityEvaluates = {
      expr = let
        result = pkgs.nixos [
          ../../nixos/base.nix
          ../../modules/user.nix
          ../../nixos/ssh.nix
          ../../nixos/tailscale.nix
          ../../nixos/caddy.nix
          ../../nixos/security.nix
          minimalEvalConfig
          homeManagerModule
          opnixModule
        ];
      in
        result.config.services.fail2ban.enable == true;
      expected = true;
    };

    nix-unit.tests.testDiskoEvaluates = {
      expr = let
        diskoModule = inputs.disko.nixosModules.disko;
        result = pkgs.nixos [
          diskoModule
          ../../nixos/disko.nix
        ];
      in
        result.config.disko.devices.disk.main.device == "/dev/sda";
      expected = true;
    };

    nix-unit.tests.testGnoEvaluates = {
      expr = let
        result = pkgs.nixos [
          ../../nixos/gno.nix
          {
            services.gno-daemon.enable = true;
            services.gno-serve.enable = true;
          }
          minimalSystemConfig
        ];
      in
        result.config.system.build.toplevel != null;
      expected = true;
    };

    nix-unit.tests.testOpencodeEvaluates = {
      expr = let
        result = pkgs.nixos [
          ../../nixos/opencode.nix
          {
            services.opencode.enable = true;
          }
          {
            _module.args.inputs = inputs;
          }
          minimalSystemConfig
        ];
      in
        result.config.system.build.toplevel != null;
      expected = true;
    };
  };
}
