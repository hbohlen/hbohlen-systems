# Base NixOS configuration
{ pkgs, ... }:

{
  # Allow unfree packages (1password-cli)
  nixpkgs.config.allowUnfree = true;

  # Hetzner Cloud can be picky about firmware mode, so install GRUB in a
  # dual-mode layout: BIOS to the disk itself and EFI to the ESP.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # Keep serial console output available for cloud-console debugging.
  boot.kernelParams = [ "console=ttyS0,115200n8" "console=tty1" ];

  # Network
  networking.useDHCP = true;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  # SSH key-only auth
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # User base definition; keys are assigned in host module
  users.users.hbohlen = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
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

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System state version
  system.stateVersion = "24.11";
}
