# Common development tools and container runtime configuration
# This module contains development tools, podman, and related utilities
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Podman container runtime
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Development and system tools
  environment.systemPackages = with pkgs; [
    # Core utilities
    vim
    git
    curl
    htop

    # Custom packages
    opencode
    kiro
    codex
    gemini-cli

    # Development tools
    gh
    nodejs
    uv

    # Container management
    podman-desktop
    podman-compose

    # Secrets management
    _1password-gui
    _1password
  ];

  # Import 1Password secrets management
  imports = [
    ../secrets/onepassword-secrets.nix
  ];
}
