{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Hostname
  networking.hostName = "desktop";

  # Import common modules
  imports = [
    ../../common/base.nix
    ../../common/desktop-environment.nix
    ../../common/development.nix
    ../../common/nvidia.nix
  ];

  # Desktop-specific NVIDIA configuration
  hardware.nvidia = {
    package = pkgs.linuxPackages.nvidiaPackages.production;
    powerManagement.enable = false;
  };

  # Desktop-specific kernel parameters for NVIDIA
  boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
}
