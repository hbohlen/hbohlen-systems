{pkgs, ...}: {
  nixpkgs.config.allowUnfree = true;

  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
        efiSupport = true;
        efiInstallAsRemovable = true;
      };
      efi.canTouchEfiVariables = false;
    };

    kernelParams = ["console=ttyS0,115200n8" "console=tty1"];
  };

  networking.useDHCP = true;
  networking.firewall.enable = true;

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    git
    htop
    eza
    fish
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  system.stateVersion = "24.11";
}
