#!/usr/bin/env bash
set -euo pipefail

# === hbohlen-systems laptop installer ===
# Run from live ISO after: sudo -i && git clone ... && cd hbohlen-systems
# WARNING: this will ERASE your SSD.

DISK="/dev/disk/by-id/nvme-Micron_2450_MTFDKBA1T0TFK_2146334B7D47"
HOST="laptop"

echo "[1/5] Setting up nix experimental features"
export NIX_CONFIG="experimental-features = nix-command flakes"

echo "[2/5] Partitioning and formatting $DISK with disko"
cat > /tmp/disko-${HOST}.nix <<EOF
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "${DISK}";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              type = "8300";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
EOF

nix run github:nix-community/disko -- --mode disko /tmp/disko-${HOST}.nix
nix run github:nix-community/disko -- --mode mount /tmp/disko-${HOST}.nix

echo "[3/5] Generating hardware-configuration.nix"
mkdir -p infrastructure/nixos/hosts/${HOST}
nixos-generate-config --root /mnt
mv /mnt/etc/nixos/hardware-configuration.nix infrastructure/nixos/hosts/${HOST}/

if [ ! -f infrastructure/nixos/hosts/${HOST}/configuration.nix ]; then
  echo "[3b] Creating minimal configuration.nix for ${HOST}"
  cat > infrastructure/nixos/hosts/${HOST}/configuration.nix <<'CONF'
{ config, pkgs, lib, ... }:

{
  networking.hostName = "laptop";
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  networking.networkmanager.enable = true;

  users.users.hbohlen = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "podman" ];
    initialPassword = "changeme"; # change on first boot
    shell = pkgs.bashInteractive;
  };
  security.sudo.wheelNeedsPassword = true;

  hardware.enableRedistributableFirmware = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.graphics = { enable = true; enable32Bit = true; };
  # Uncomment below if you want NVIDIA drivers
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia = { package = pkgs.linuxPackages.nvidiaPackages.production;
  #   modesetting.enable = true; open = false; nvidiaSettings = true; };

  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  programs.direnv = { enable = true; nix-direnv.enable = true; };
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim git curl htop
    networkmanager networkmanagerapplet
    kitty zed-editor fuzzel waybar
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = lib.mkDefault "25.05";
}
CONF
fi

echo "[4/5] Installing NixOS (this may take a while)"
nixos-install --root /mnt --flake .#${HOST}

echo "[5/5] Installation complete. You can now reboot."
echo "Run: reboot"
