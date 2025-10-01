# Common desktop environment configuration (Hyprland + Wayland)
# This module contains Hyprland compositor and related desktop services
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Hyprland Wayland compositor
  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  # Login manager (tuigreet → Hyprland via dbus-run-session)
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = ''
        ${pkgs.greetd.tuigreet}/bin/tuigreet \
          --time --remember \
          --cmd "${pkgs.dbus}/bin/dbus-run-session ${pkgs.hyprland}/bin/Hyprland"
      '';
      user = "greeter";
    };
  };

  # Portals (screensharing, file pickers)
  xdg.portal.enable = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
  ];

  # PolicyKit (needed by network-manager, etc.)
  security.polkit.enable = true;

  # Audio with PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Base Wayland environment variables
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Electron/Chromium on Wayland
  };

  # Desktop environment packages
  environment.systemPackages = with pkgs; [
    networkmanager
    networkmanagerapplet
    kitty
    vivaldi
    zed-editor
    fuzzel
    waybar
  ];
}
