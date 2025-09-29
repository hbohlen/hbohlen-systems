{ config, pkgs, lib, ... }:

{
  networking.hostName = "laptop";
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

  # Allow unfree software
  nixpkgs.config.allowUnfree = true;

  # Firmware
  hardware.enableRedistributableFirmware = true;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # User account
  users.users.hbohlen = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "podman"
    ];
    initialPassword = "changeme"; # change after first login
    shell = pkgs.bashInteractive;
  };
  security.sudo.wheelNeedsPassword = true;

  # Networking
  networking.networkmanager.enable = true;

  # Laptop-specific: Intel graphics (adjust if you have NVIDIA/AMD)
  services.xserver.videoDrivers = [ "intel" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

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

  # Podman container runtime
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Audio with PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Laptop-specific environment variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Electron/Chromium on Wayland
  };

  # Laptop-specific packages (remove NVIDIA-specific ones)
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    htop
    networkmanager
    networkmanagerapplet
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
    podman-desktop
    podman-compose
    # Secrets management
    _1password-gui
    _1password
    # Laptop extras
    powertop
    tlp
    laptop-mode-tools
  ];

  # Import 1Password secrets management
  imports = [
    ../../secrets/onepassword-secrets.nix
  ];

  # Laptop power management
  services.tlp.enable = true;
  services.power-profiles-daemon.enable = true;

  # Enable flakes + new nix CLI
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # State version
  system.stateVersion = lib.mkDefault "25.05";
}
