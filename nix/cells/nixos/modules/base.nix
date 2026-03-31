# Base NixOS configuration
{ config, pkgs, ... }:

{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network
  networking.useDHCP = true;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # User
  users.users.hbohlen = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here (will be set in host config)
    ];
  };

  # Sudo
  security.sudo.wheelNeedsPassword = false;

  # Locale and timezone
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # Basic packages
  environment.systemPackages = with pkgs; [
    git
    htop
    eza
    fish
  ];

  # Use fish as default shell for hbohlen
  users.users.hbohlen.shell = pkgs.fish;
  programs.fish.enable = true;

  # Tailscale
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
  };

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System state version
  system.stateVersion = "24.11";
}
