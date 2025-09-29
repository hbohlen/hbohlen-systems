{ config, pkgs, lib, ... }:

{
  networking.hostName = "desktop";
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # direnv (dev convenience)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Keep a few generations in systemd-boot
  boot.loader.systemd-boot.configurationLimit = 7;

  # Allow unfree software (NVIDIA, Vivaldi, Zed, etc.)
  nixpkgs.config.allowUnfree = true;

  # Firmware
  hardware.enableRedistributableFirmware = true;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # User account
  users.users.hbohlen = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme"; # change after first login
    shell = pkgs.bashInteractive;
  };
  security.sudo.wheelNeedsPassword = true;

  # Networking
  networking.networkmanager.enable = true;

  # NVIDIA graphics
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

  # Hyprland Wayland compositor
  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  # Login manager (tuigreet → Hyprland via dbus-run-session)
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = ''
        ${pkgs.greetd.tuigreet}/bin/tuigreet \
          --time --remember \
          --cmd "${pkgs.dbus}/bin/dbus-run-session ${pkgs.hyprland}/bin/Hyprland"
      '';
      user = "greeter";
    };
  };

  # Portals (screensharing, file pickers)
  xdg.portal.enable = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
  ];

  # PolicyKit (needed by network-manager, etc.)
  security.polkit.enable = true;

  # Audio with PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Wayland/NVIDIA-friendly env vars
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";                 # Electron/Chromium on Wayland
    __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # GLX/NVIDIA selection
    # If video apps complain and you don't use nvidia-vaapi-driver, remove this:
    LIBVA_DRIVER_NAME = "nvidia";
    # If you ever see a missing cursor or flicker on NVIDIA, toggle this:
    # WLR_NO_HARDWARE_CURSORS = "1";
  };

  # Installed system packages
  environment.systemPackages = with pkgs; [
    vim git curl htop
    networkmanager networkmanagerapplet
    kitty
    vivaldi
    zed-editor
    fuzzel
    waybar
    opencode
    kiro
    codex
    gemini-cli
    gh
    nodejs
    uv

  ];

  # Enable flakes + new nix CLI
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # State version (don’t bump unless you know why)
  system.stateVersion = lib.mkDefault "25.05";
}
