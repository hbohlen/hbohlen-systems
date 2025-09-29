{ config, pkgs, ... }:

{
  home.username = "hbohlen";
  home.homeDirectory = "/home/hbohlen";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "Harrison Bohlen";
    userEmail = "you@example.com";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Hyprland window manager configuration
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # Basic monitor configuration
      monitor = ",preferred,auto,auto";
      
      # General settings
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
        allow_tearing = false;
      };
      
      # Input configuration
      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = false;
        };
        sensitivity = 0;
      };
      
      # Decoration settings
      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";
      };
      
      # Animation settings
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };
      
      # Layout configuration
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
      
      # Gestures
      gestures = {
        workspace_swipe = false;
      };
      
      # Misc settings
      misc = {
        force_default_wallpaper = -1;
      };
    };
    
    # Additional Hyprland configuration
    extraConfig = ''
      # Environment variables for NVIDIA compatibility
      env = LIBVA_DRIVER_NAME,nvidia
      env = XDG_SESSION_TYPE,wayland
      env = GBM_BACKEND,nvidia-drm
      env = __GLX_VENDOR_LIBRARY_NAME,nvidia
      env = WLR_NO_HARDWARE_CURSORS,1

      # Workspace rules
      workspace = 1, monitor:DP-1, default:true
      workspace = 2, monitor:DP-1
      workspace = 3, monitor:DP-1
      workspace = 4, monitor:DP-1
      workspace = 5, monitor:DP-1

      # Window rules
      windowrule = float, ^(pavucontrol)$
      windowrule = float, ^(blueman-manager)$
      windowrule = float, ^(nm-connection-editor)$
      windowrule = float, ^(file_progress)$
      windowrule = float, ^(confirm)$
      windowrule = float, ^(dialog)$
      windowrule = float, ^(download)$
      windowrule = float, ^(notification)$
      windowrule = float, ^(error)$
      windowrule = float, ^(splash)$
      windowrule = float, ^(confirmreset)$
      windowrule = float, title:^(Open File)(.*)$
      windowrule = float, title:^(Select a File)(.*)$
      windowrule = float, title:^(Choose wallpaper)(.*)$
      windowrule = float, title:^(Open Folder)(.*)$
      windowrule = float, title:^(Save As)(.*)$
      windowrule = float, title:^(Library)(.*)$

      # Startup applications
      exec-once = waybar
      exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    '';
  };

  home.packages = with pkgs; [
    ripgrep fd jq tree stow
  ];
}
