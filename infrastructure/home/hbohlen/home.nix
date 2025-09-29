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
      
      # General settings - optimized for window management
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
        allow_tearing = false;
        resize_on_border = true;
        extend_border_grab_area = 15;
        hover_icon_on_border = true;
      };
      
      # Input configuration - enhanced for better window management
      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";
        follow_mouse = 1;
        mouse_refocus = true;
        float_switch_override_focus = 2;
        touchpad = {
          natural_scroll = false;
          disable_while_typing = true;
          tap-to-click = true;
          drag_lock = false;
          scroll_factor = 1.0;
        };
        sensitivity = 0;
        accel_profile = "flat";
      };
      
      # Decoration settings - optimized for NVIDIA
      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
          new_optimizations = true;
          xray = false;
        };
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        shadow_offset = "0 0";
        "col.shadow" = "rgba(1a1a1aee)";
        active_opacity = 1.0;
        inactive_opacity = 0.95;
        fullscreen_opacity = 1.0;
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
      
      # Layout configuration - enhanced dwindle settings
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        smart_split = false;
        smart_resizing = true;
        force_split = 0;
        special_scale_factor = 0.8;
        split_width_multiplier = 1.0;
        use_active_for_splits = true;
        default_split_ratio = 1.0;
      };
      
      # Master layout configuration (alternative)
      master = {
        new_is_master = true;
        new_on_top = false;
        no_gaps_when_only = false;
        orientation = "left";
        inherit_fullscreen = true;
        always_center_master = false;
        smart_resizing = true;
        drop_at_cursor = true;
      };
      
      # Gestures
      gestures = {
        workspace_swipe = false;
      };
      
      # Misc settings - enhanced for better window management
      misc = {
        force_default_wallpaper = -1;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        vrr = 0;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        enable_swallow = true;
        swallow_regex = "^(kitty)$";
        focus_on_activate = false;
        no_direct_scanout = true;
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

      # Window rules - enhanced for better window management
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
      
      # Additional window management rules
      windowrule = center, ^(pavucontrol)$
      windowrule = center, ^(blueman-manager)$
      windowrule = center, ^(nm-connection-editor)$
      windowrule = size 800 600, ^(pavucontrol)$
      windowrule = size 600 500, ^(blueman-manager)$
      windowrule = size 700 500, ^(nm-connection-editor)$
      
      # Tiling rules for better window management
      windowrule = tile, ^(kitty)$
      windowrule = tile, ^(vivaldi-stable)$
      windowrule = tile, ^(code)$
      windowrule = tile, ^(firefox)$
      
      # Opacity rules for inactive windows
      windowrule = opacity 0.95 0.85, ^(kitty)$
      windowrule = opacity 1.0 0.9, ^(vivaldi-stable)$
      
      # Focus rules
      windowrule = noinitialfocus, ^(steam)$
      windowrule = stayfocused, ^(fuzzel)$

      # Startup applications
      exec-once = waybar
      exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
    '';
  };

  home.packages = with pkgs; [
    ripgrep fd jq tree stow
  ];
}
