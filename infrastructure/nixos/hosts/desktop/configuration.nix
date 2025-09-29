{ config, pkgs, lib, ... }:

{
  networking.hostName = "desktop";
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  programs.direnv = {
    enable = true;            # installs direnv + hooks your shell init
    nix-direnv.enable = true; # lets '.envrc' use the 'use nix' directive
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";                   # run weekly
    options = "--delete-older-than 30d"; # delete store paths unused for 30+ days
  };

  # Keep some history for safety
  boot.loader.systemd-boot.configurationLimit = 7; # keep 7 boot entries

  nixpkgs.config.allowUnfree = true;

  hardware.enableRedistributableFirmware = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.hbohlen = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
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

  services.greetd.settings.default_session.command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd ${pkgs.hyprland}/bin/Hyprland";


  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

  environment.systemPackages = with pkgs; [
    vim git curl htop
    networkmanager
    kitty
    networkmanagerapplet
    zed-editor
    vivaldi
    opencode
    vscode
    # affine
    
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = lib.mkDefault "25.05";
}
