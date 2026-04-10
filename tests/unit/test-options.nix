{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    nix-unit.tests.testOpencodeEnableOptionDefault = {
      expr = let
        result = pkgs.nixos [
          ../../nixos/opencode.nix
          {
            _module.args.inputs = inputs;
            fileSystems."/" = {
              device = "/dev/sda1";
              fsType = "ext4";
            };
            boot.loader.grub.devices = ["/dev/sda"];
          }
        ];
      in
        result.config.services.opencode.enable == false;
      expected = true;
    };

    nix-unit.tests.testOpencodePortDefault = {
      expr = let
        result = pkgs.nixos [
          ../../nixos/opencode.nix
          {
            _module.args.inputs = inputs;
            fileSystems."/" = {
              device = "/dev/sda1";
              fsType = "ext4";
            };
            boot.loader.grub.devices = ["/dev/sda"];
          }
        ];
      in
        result.config.services.opencode.port == 8081;
      expected = true;
    };

    nix-unit.tests.testPiWebUiEnableOptionDefault = {
      expr = let
        result = pkgs.nixos [
          ../../nixos/pi-web-ui.nix
          {
            fileSystems."/" = {
              device = "/dev/sda1";
              fsType = "ext4";
            };
            boot.loader.grub.devices = ["/dev/sda"];
          }
        ];
      in
        result.config.services.pi-web-ui.enable == false;
      expected = true;
    };

    nix-unit.tests.testPiWebUiPortDefault = {
      expr = let
        result = pkgs.nixos [
          ../../nixos/pi-web-ui.nix
          {
            fileSystems."/" = {
              device = "/dev/sda1";
              fsType = "ext4";
            };
            boot.loader.grub.devices = ["/dev/sda"];
          }
        ];
      in
        result.config.services.pi-web-ui.port == 3000;
      expected = true;
    };

    nix-unit.tests.testCaddyTailscaleEnableOptionDefault = {
      expr = let
        result = pkgs.nixos [
          ../../nixos/caddy.nix
          {
            fileSystems."/" = {
              device = "/dev/sda1";
              fsType = "ext4";
            };
            boot.loader.grub.devices = ["/dev/sda"];
          }
        ];
      in
        result.config.services.caddy.tailscaleEnable == false;
      expected = true;
    };

    nix-unit.tests.testCaddyOpencodeHostDefault = {
      expr = let
        result = pkgs.nixos [
          ../../nixos/caddy.nix
          {
            fileSystems."/" = {
              device = "/dev/sda1";
              fsType = "ext4";
            };
            boot.loader.grub.devices = ["/dev/sda"];
          }
        ];
      in
        result.config.services.caddy.opencodeHost == "opencode.taile0585b.ts.net";
      expected = true;
    };

    nix-unit.tests.testCaddyPiWebUiHostDefault = {
      expr = let
        result = pkgs.nixos [
          ../../nixos/caddy.nix
          {
            fileSystems."/" = {
              device = "/dev/sda1";
              fsType = "ext4";
            };
            boot.loader.grub.devices = ["/dev/sda"];
          }
        ];
      in
        result.config.services.caddy.piWebUiHost == "pi-web-ui.taile0585b.ts.net";
      expected = true;
    };
  };
}
