{ inputs, ... }:

{
  perSystem = { pkgs, ... }:
    {
      nix-unit.tests.testOpencodeEnableOptionDefault = {
        expr =
          let
            result = pkgs.nixos [
              ../../modules/opencode.nix
              {
                _module.args.inputs = inputs;
                fileSystems."/" = {
                  device = "/dev/sda1";
                  fsType = "ext4";
                };
                boot.loader.grub.devices = [ "/dev/sda" ];
              }
            ];
          in
          result.config.services.opencode.enable == false;
        expected = true;
      };

      nix-unit.tests.testOpencodePortDefault = {
        expr =
          let
            result = pkgs.nixos [
              ../../modules/opencode.nix
              {
                _module.args.inputs = inputs;
                fileSystems."/" = {
                  device = "/dev/sda1";
                  fsType = "ext4";
                };
                boot.loader.grub.devices = [ "/dev/sda" ];
              }
            ];
          in
          result.config.services.opencode.port == 8081;
        expected = true;
      };

      nix-unit.tests.testGnoDaemonEnableOptionDefault = {
        expr =
          let
            result = pkgs.nixos [
              ../../modules/gno.nix
              {
                fileSystems."/" = {
                  device = "/dev/sda1";
                  fsType = "ext4";
                };
                boot.loader.grub.devices = [ "/dev/sda" ];
              }
            ];
          in
          result.config.services.gno-daemon.enable == false;
        expected = true;
      };

      nix-unit.tests.testGnoServeEnableOptionDefault = {
        expr =
          let
            result = pkgs.nixos [
              ../../modules/gno.nix
              {
                fileSystems."/" = {
                  device = "/dev/sda1";
                  fsType = "ext4";
                };
                boot.loader.grub.devices = [ "/dev/sda" ];
              }
            ];
          in
          result.config.services.gno-serve.enable == false;
        expected = true;
      };

      nix-unit.tests.testGnoServePortDefault = {
        expr =
          let
            result = pkgs.nixos [
              ../../modules/gno.nix
              {
                fileSystems."/" = {
                  device = "/dev/sda1";
                  fsType = "ext4";
                };
                boot.loader.grub.devices = [ "/dev/sda" ];
              }
            ];
          in
          result.config.services.gno-serve.port == 8082;
        expected = true;
      };

      nix-unit.tests.testCaddyTailscaleEnableOptionDefault = {
        expr =
          let
            result = pkgs.nixos [
              ../../modules/caddy.nix
              {
                fileSystems."/" = {
                  device = "/dev/sda1";
                  fsType = "ext4";
                };
                boot.loader.grub.devices = [ "/dev/sda" ];
              }
            ];
          in
          result.config.services.caddy.tailscaleEnable == false;
        expected = true;
      };

      nix-unit.tests.testCaddyOpencodeHostDefault = {
        expr =
          let
            result = pkgs.nixos [
              ../../modules/caddy.nix
              {
                fileSystems."/" = {
                  device = "/dev/sda1";
                  fsType = "ext4";
                };
                boot.loader.grub.devices = [ "/dev/sda" ];
              }
            ];
          in
          result.config.services.caddy.opencodeHost == "opencode.hbohlen.systems";
        expected = true;
      };
    };
}
