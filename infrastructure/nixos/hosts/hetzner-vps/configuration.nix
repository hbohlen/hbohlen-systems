{
  config,
  pkgs,
  lib,
  ...
}:

{
  networking.hostName = "hetzner-vps"; # Or whatever you want to call it
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

  # Allow unfree software
  nixpkgs.config.allowUnfree = true;

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

  # Podman container runtime
  virtualisation = {
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

  # Installed system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    htop
    networkmanager
    networkmanagerapplet
    kitty
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
  ];

  # Import 1Password secrets management (pure injection approach)
  imports = [
    ../../secrets/onepassword-secrets.nix
  ];

  # Enable flakes + new nix CLI
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # State version (dont bump unless you know why)
  system.stateVersion = lib.mkDefault "25.05";
}
