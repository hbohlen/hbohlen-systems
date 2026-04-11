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
    nix-unit = {
      tests = {
        testCaddyEvaluates = {
          expr = let
            result = pkgs.nixos [
              ../../nixos/base.nix
              ../../nixos/user.nix
              ../../nixos/ssh.nix
              ../../nixos/tailscale.nix
              ../../nixos/caddy.nix
              minimalEvalConfig
              homeManagerModule
              opnixModule
            ];
          in
            result.config.services.caddy.enable;
          expected = true;
        };

        testTailscaleMaterializesDatadogSecret = {
          expr = let
            result = pkgs.nixos [
              ../../nixos/base.nix
              ../../nixos/user.nix
              ../../nixos/ssh.nix
              ../../nixos/tailscale.nix
              minimalSystemConfig
              homeManagerModule
              opnixModule
            ];
          in
            result.config.services.onepassword-secrets.secrets.datadogApiKey.reference
            == "op://hbohlen-systems/datadog/apiKey"
            && result.config.services.onepassword-secrets.secrets.datadogApiKey.owner == "hbohlen";
          expected = true;
        };

        testSecurityEvaluates = {
          expr = let
            result = pkgs.nixos [
              ../../nixos/base.nix
              ../../nixos/user.nix
              ../../nixos/ssh.nix
              ../../nixos/tailscale.nix
              ../../nixos/caddy.nix
              ../../nixos/security.nix
              minimalEvalConfig
              homeManagerModule
              opnixModule
            ];
          in
            result.config.services.fail2ban.enable;
          expected = true;
        };

        testDiskoEvaluates = {
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

        testPiWebUiEvaluates = {
          expr = let
            result = pkgs.nixos [
              ../../nixos/pi-web-ui.nix
              {
                services.pi-web-ui.enable = true;
              }
              minimalSystemConfig
            ];
          in
            result.config.system.build.toplevel != null;
          expected = true;
        };

        testOpencodeEvaluates = {
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
    };
  };
}
