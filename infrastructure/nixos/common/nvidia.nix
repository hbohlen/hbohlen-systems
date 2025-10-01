# Common NVIDIA graphics configuration
# This module contains base NVIDIA settings shared between desktop and laptop
# Host-specific overrides should be in the respective host configurations
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Enable NVIDIA graphics support
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Base NVIDIA configuration (common settings)
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };

  # NVIDIA-specific environment variables for Wayland
  environment.sessionVariables = {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "0";
  };
}
