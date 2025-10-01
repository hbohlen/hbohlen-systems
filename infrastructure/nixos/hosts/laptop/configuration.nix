{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Hostname
  networking.hostName = "laptop";

  # Import common modules
  imports = [
    ../../common/base.nix
    ../../common/desktop-environment.nix
    ../../common/development.nix
    ../../common/nvidia.nix
  ];

  # Laptop-specific NVIDIA configuration (hybrid graphics with power management)
  hardware.nvidia = {
    package = pkgs.linuxPackages.nvidiaPackages.production;
    powerManagement.enable = true;
    powerManagement.finegrained = true; # Enable for hybrid graphics/better battery
    # Note: Prime offload and bus IDs are configured by nixos-hardware module
  };

  # Laptop-specific kernel parameters for NVIDIA
  boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];

  # Laptop-specific packages (power management and hardware control)
  environment.systemPackages = with pkgs; [
    # Power management tools
    powertop
    tlp
    acpi
    brightnessctl

    # Wireless tools
    iw
    wpa_supplicant_gui

    # NVIDIA monitoring for ROG laptop
    nvtopPackages.nvidia

    # ASUS laptop hardware control
    asusctl
    supergfxctl
  ];

  # Laptop power management services
  services.tlp.enable = true;
  powerManagement.enable = true;
}
