{ config, pkgs, ... }:

{
  home.username = "hbohlen";
  home.homeDirectory = "/home/hbohlen";
  home.stateVersion = "24.11";

  # Enable home-manager to manage itself
  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "Hayden Bohlen";
    userEmail = "bohlenhayden@gmail.com";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # ===== HYPRLAND WINDOW MANAGER CONFIGURATION =====
  # Comprehensive Hyprland setup with keybindings, window management, and NVIDIA optimizations
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
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
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
        new_on_top = false;
        orientation = "left";
        inherit_fullscreen = true;
        smart_resizing = true;
        drop_at_cursor = true;
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

      };
      
      # Keybinding configuration
      bind = [
        # Terminal launch - Super+Return → kitty
        "SUPER, Return, exec, kitty"
        
        # Window close - Super+Q
        "SUPER, Q, killactive"
        
        # Application launcher - Super+Space → fuzzel
        "SUPER, Space, exec, fuzzel"
        
        # Workspace switching - Super+[1-9]
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"
        
        # Window movement to workspaces - Super+Shift+[1-9]
        "SUPER SHIFT, 1, movetoworkspace, 1"
        "SUPER SHIFT, 2, movetoworkspace, 2"
        "SUPER SHIFT, 3, movetoworkspace, 3"
        "SUPER SHIFT, 4, movetoworkspace, 4"
        "SUPER SHIFT, 5, movetoworkspace, 5"
        "SUPER SHIFT, 6, movetoworkspace, 6"
        "SUPER SHIFT, 7, movetoworkspace, 7"
        "SUPER SHIFT, 8, movetoworkspace, 8"
        "SUPER SHIFT, 9, movetoworkspace, 9"
        
        # Vim-like focus movement - Super+H/J/K/L
        "SUPER, H, movefocus, l"
        "SUPER, J, movefocus, d"
        "SUPER, K, movefocus, u"
        "SUPER, L, movefocus, r"
        
        # Window management keybindings
        "SUPER, F, fullscreen, 0"                    # Fullscreen toggle
        "SUPER SHIFT, Space, togglefloating"         # Floating toggle
        
        # Additional useful window management
        "SUPER, P, pseudo"                           # Pseudotile toggle
        "SUPER SHIFT, J, togglesplit"               # Toggle split direction
        "SUPER, M, exit"                             # Exit Hyprland
        "SUPER SHIFT, R, forcerendererreload"       # Force renderer reload
        
        # Window resizing with Super+Alt combinations
        "SUPER ALT, H, resizeactive, -20 0"
        "SUPER ALT, L, resizeactive, 20 0"
        "SUPER ALT, K, resizeactive, 0 -20"
        "SUPER ALT, J, resizeactive, 0 20"
        
        # Move windows with Super+Shift+vim keys
        "SUPER SHIFT, H, movewindow, l"
        "SUPER SHIFT, L, movewindow, r"
        "SUPER SHIFT, K, movewindow, u"
        "SUPER SHIFT, J, movewindow, d"
      ];
      
      # Mouse bindings for window management
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];
    };
    
    # Additional Hyprland configuration from external file
    # This includes window rules, workspace assignments, startup applications, and NVIDIA environment variables
    extraConfig = builtins.readFile ./hyprland/hyprland.conf;
  };

  # ===== FUZZEL APPLICATION LAUNCHER CONFIGURATION =====
  # Keyboard-driven application launcher integrated with Hyprland (Super+Space)
  programs.fuzzel = {
    enable = true;
    # Note: home-manager fuzzel module expects Nix attribute sets, so we keep the configuration here
    # The external fuzzel.ini file serves as documentation and reference for the settings below
    settings = {
      main = {
        terminal = "kitty";
        layer = "overlay";
        width = 40;
        horizontal-pad = 20;
        vertical-pad = 10;
        inner-pad = 10;
        font = "monospace:size=12";
        dpi-aware = "yes";
        show-actions = "yes";
        password-character = "*";
        fields = "filename,name,generic";
        fuzzy = "yes";
        show-recent = "yes";
        sort-result = "yes";
        lines = 15;
        tabs = 4;
        exit-on-keyboard-focus-loss = "yes";
      };
      
      colors = {
        background = "1e1e2eff";
        text = "cdd6f4ff";
        match = "f38ba8ff";
        selection = "585b70ff";
        selection-text = "cdd6f4ff";
        selection-match = "f38ba8ff";
        border = "b4befeff";
      };
      
      border = {
        width = 2;
        radius = 8;
      };
      
      key-bindings = {
        cancel = "Escape Control+c";
        execute = "Return KP_Enter Control+m";
        execute-or-next = "Tab";
        cursor-left = "Left Control+b";
        cursor-left-word = "Control+Left Mod1+b";
        cursor-right = "Right Control+f";
        cursor-right-word = "Control+Right Mod1+f";
        cursor-home = "Home Control+a";
        cursor-end = "End Control+e";
        delete-prev = "BackSpace";
        delete-prev-word = "Mod1+BackSpace Control+BackSpace";
        delete-next = "Delete";
        delete-next-word = "Mod1+d Control+Delete";
        delete-line = "Control+k";
        prev = "Up Control+p";
        prev-page = "Page_Up Control+v";
        next = "Down Control+n";
        next-page = "Page_Down Mod1+v";
        first = "Control+Home";
        last = "Control+End";
      };
    };
  };

  # ===== WAYBAR STATUS BAR CONFIGURATION =====
  # System status bar with workspace indicators, system monitoring, and Hyprland integration
  programs.waybar = {
    enable = true;
    # Enable systemd integration for proper startup with Hyprland
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
    # Load configuration from external JSON file for easier maintenance
    settings = {
      mainBar = builtins.fromJSON (builtins.readFile ./waybar/config.json);
    };
    # Load CSS styling from external file
    style = builtins.readFile ./waybar/style.css;
  };

  # ===== SYSTEMD USER SERVICES =====
  # Proper session management and service dependencies for Hyprland desktop environment
  systemd.user = {
    targets.hyprland-session = {
      Unit = {
        Description = "Hyprland compositor session";
        Documentation = [ "man:systemd.special(7)" ];
        BindsTo = [ "graphical-session.target" ];
        Wants = [ "graphical-session-pre.target" ];
        After = [ "graphical-session-pre.target" ];
      };
    };

    services.hyprland-autostart = {
      Unit = {
        Description = "Hyprland autostart applications";
        PartOf = [ "hyprland-session.target" ];
        After = [ "hyprland-session.target" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "hyprland-autostart" ''
          # Start waybar with proper dependencies
          ${pkgs.systemd}/bin/systemctl --user start waybar.service
          
          # Ensure proper environment for applications
          ${pkgs.systemd}/bin/systemctl --user import-environment PATH
          ${pkgs.systemd}/bin/systemctl --user import-environment XDG_DATA_DIRS
          
          # Start any additional desktop services
          ${pkgs.systemd}/bin/systemctl --user start xdg-desktop-portal-hyprland.service || true
          ${pkgs.systemd}/bin/systemctl --user start xdg-desktop-portal.service || true
        '';
      };
      Install = {
        WantedBy = [ "hyprland-session.target" ];
      };
    };
  };

  # ===== ADDITIONAL PACKAGES =====
  # Essential command-line tools and utilities
  home.packages = with pkgs; [
    ripgrep fd jq tree stow
  ];
}
