# Laptop hardware configuration template
# This file should be regenerated on the actual laptop hardware using:
# nixos-generate-config --root /mnt
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # Common laptop kernel modules - adjust based on your actual hardware
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # File systems - THESE MUST BE UPDATED WITH ACTUAL DEVICE UUIDs
  # Run 'blkid' to get the correct UUIDs for your laptop's partitions
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-ROOT-UUID";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-BOOT-UUID";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  # Adjust swap configuration based on your setup
  swapDevices = [ ];

  # Networking - enable DHCP on all interfaces by default
  networking.useDHCP = lib.mkDefault true;
  # Uncomment and adjust these for specific interface configurations:
  # networking.interfaces.enp0s25.useDHCP = lib.mkDefault true;  # Ethernet
  # networking.interfaces.wlp3s0.useDHCP = lib.mkDefault true;   # WiFi

  # Platform and CPU microcode
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Enable WiFi hardware
  hardware.enableRedistributableFirmware = true;
}