# Common base system configuration for all hosts
# This module contains core system settings that are identical across desktop and laptop
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Locale and timezone
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # Allow unfree software (NVIDIA, Vivaldi, Zed, etc.)
  nixpkgs.config.allowUnfree = true;

  # Firmware
  hardware.enableRedistributableFirmware = true;

  # Bootloader - systemd-boot with EFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 7;

  # User account with consistent configuration
  users.users.hbohlen = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "podman"
    ];
    # Subuid/subgid ranges for rootless podman
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
    initialPassword = "changeme"; # change after first login
    shell = pkgs.bashInteractive;
  };
  security.sudo.wheelNeedsPassword = true;

  security.wrappers.newuidmap = {
    source = "${pkgs.shadow}/bin/newuidmap";
    owner = "root";
    group = "root";
    setuid = true;
  };

  security.wrappers.newgidmap = {
    source = "${pkgs.shadow}/bin/newgidmap";
    owner = "root";
    group = "root";
    setuid = true;
  };

  # Networking
  networking.networkmanager.enable = true;

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Enable flakes + new nix CLI
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # direnv (dev convenience)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # State version
  system.stateVersion = lib.mkDefault "25.05";
}
