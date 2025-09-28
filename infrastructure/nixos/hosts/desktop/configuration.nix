{ config, pkgs, lib, ... }:

{
  networking.hostName = "desktop";
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  programs.direnv = {
    enable = true;            # installs direnv + hooks your shell init
    nix-direnv.enable = true; # lets '.envrc' use the 'use nix' directive
  };

  nixpkgs.config.allowUnfree = true;

  hardware.enableRedistributableFirmware = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.hbohlen = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme";
    shell = pkgs.bashInteractive;
  };
  security.sudo.wheelNeedsPassword = true;

  networking.networkmanager.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    package = pkgs.linuxPackages.nvidiaPackages.production;
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;
    nvidiaSettings = true;
  };
  boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];

  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
      user = "greeter";
    };
  };

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

  environment.systemPackages = with pkgs; [
    vim git curl htop
    networkmanager
    kitty
    networkmanagerapplet
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = lib.mkDefault "25.05";
}
