# Design Document

## Overview

This design extends the existing NixOS desktop configuration by implementing comprehensive Hyprland window manager configurations and enhanced home-manager setup. The solution leverages home-manager's declarative configuration capabilities to manage Hyprland, waybar, and fuzzel configurations, ensuring a reproducible and maintainable desktop environment.

The design builds upon the existing system-level Hyprland enablement in the NixOS configuration and moves user-specific configurations to home-manager for better separation of concerns.

## Architecture

### Configuration Layers

1. **System Level (NixOS)**: Maintains Hyprland enablement, display drivers, and system services
2. **User Level (Home Manager)**: Manages Hyprland configuration, waybar, fuzzel, and user-specific desktop settings
3. **Application Integration**: Ensures proper integration between Hyprland, waybar, and fuzzel

### File Structure

```
infrastructure/home/hbohlen/
├── home.nix                    # Main home-manager configuration
├── hyprland/
│   ├── hyprland.conf          # Hyprland configuration file
│   └── keybindings.conf       # Separated keybinding configuration
├── waybar/
│   ├── config.json           # Waybar configuration
│   └── style.css             # Waybar styling
└── fuzzel/
    └── fuzzel.ini            # Fuzzel configuration
```

## Components and Interfaces

### Hyprland Configuration Module

**Purpose**: Manages Hyprland window manager settings, keybindings, and behavior

**Key Configuration Areas**:
- Monitor setup and workspace assignment
- Input device configuration (keyboard, mouse, touchpad)
- Window rules and workspace behavior
- Keybinding definitions
- Animation and visual effects
- Startup applications

**Interface with System**: 
- Reads system-level Hyprland enablement from NixOS configuration
- Integrates with existing NVIDIA and audio configurations
- Respects existing environment variables for Wayland/NVIDIA compatibility

### Waybar Integration

**Purpose**: Provides system status bar with workspace indicators and system information

**Components**:
- Workspace module for Hyprland integration
- System resource monitoring (CPU, memory, network)
- Audio control integration with PipeWire
- Clock and date display
- Custom styling to match desktop theme

**Interface with Hyprland**:
- Uses Hyprland IPC for workspace information
- Responds to workspace changes in real-time
- Integrates with Hyprland's window management events

### Fuzzel Application Launcher

**Purpose**: Keyboard-driven application launcher integrated with Hyprland

**Configuration Areas**:
- Appearance and theming
- Search behavior and indexing
- Keyboard shortcuts and navigation
- Integration with desktop applications

**Interface with System**:
- Launches applications through desktop entries
- Integrates with Hyprland's keybinding system
- Uses system application database

### Home Manager Integration

**Purpose**: Declarative management of all desktop configurations

**Module Structure**:
```nix
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = { ... };
    extraConfig = builtins.readFile ./hyprland/hyprland.conf;
  };
  
  programs.waybar = {
    enable = true;
    settings = { ... };
    style = builtins.readFile ./waybar/style.css;
  };
  
  programs.fuzzel = {
    enable = true;
    settings = { ... };
  };
}
```

## Data Models

### Hyprland Configuration Schema

```nix
{
  general = {
    gaps_in = 5;
    gaps_out = 10;
    border_size = 2;
    layout = "dwindle";
  };
  
  input = {
    kb_layout = "us";
    follow_mouse = 1;
    touchpad = {
      natural_scroll = false;
    };
  };
  
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
  };
}
```

### Waybar Configuration Schema

```json
{
  "layer": "top",
  "position": "top",
  "height": 30,
  "modules-left": ["hyprland/workspaces"],
  "modules-center": ["clock"],
  "modules-right": ["pulseaudio", "network", "cpu", "memory"],
  "hyprland/workspaces": {
    "format": "{icon}",
    "format-icons": {
      "1": "1",
      "2": "2",
      "3": "3",
      "4": "4",
      "5": "5"
    }
  }
}
```

### Fuzzel Configuration Schema

```ini
[main]
terminal=kitty
layer=overlay
width=40
horizontal-pad=20
vertical-pad=10
inner-pad=10

[colors]
background=1e1e2eff
text=cdd6f4ff
match=f38ba8ff
selection=585b70ff
selection-text=cdd6f4ff
border=b4befeff
```

## Error Handling

### Configuration Validation

1. **Syntax Validation**: Home-manager will validate Nix syntax during build
2. **Runtime Validation**: Hyprland validates configuration on startup
3. **Fallback Behavior**: System falls back to default Hyprland configuration if user config fails

### Service Management

1. **Waybar Restart**: Automatic restart on configuration changes
2. **Hyprland Reload**: Configuration reload without session restart
3. **Error Logging**: Centralized logging through systemd user services

### Compatibility Checks

1. **NVIDIA Compatibility**: Ensure configurations work with existing NVIDIA setup
2. **Audio Integration**: Verify PipeWire integration with waybar audio controls
3. **Application Compatibility**: Test fuzzel integration with installed applications

## Testing Strategy

### Configuration Testing

1. **Build Testing**: Verify home-manager configuration builds successfully
2. **Syntax Testing**: Validate all configuration file syntax
3. **Integration Testing**: Test component interactions (Hyprland + waybar + fuzzel)

### Functional Testing

1. **Keybinding Testing**: Verify all defined keybindings work correctly
2. **Workspace Testing**: Test workspace switching and window movement
3. **Application Launch Testing**: Verify fuzzel launches applications correctly
4. **Status Bar Testing**: Confirm waybar displays correct system information

### Regression Testing

1. **System Integration**: Ensure changes don't break existing NixOS functionality
2. **Performance Testing**: Verify desktop performance remains acceptable
3. **Session Management**: Test login/logout and session persistence

### Manual Testing Checklist

1. Login to Hyprland session
2. Test basic keybindings (terminal, application launcher, window management)
3. Verify waybar displays and updates correctly
4. Test fuzzel application search and launch
5. Verify workspace switching and window movement
6. Test window management features (fullscreen, floating, tiling)
7. Verify system integration (audio, networking, etc.)

## Implementation Considerations

### Existing System Integration

- Preserve existing NVIDIA configuration and environment variables
- Maintain compatibility with existing greetd/tuigreet login setup
- Ensure PipeWire audio integration continues working
- Keep existing application installations functional

### Performance Optimization

- Use efficient Hyprland animation settings for NVIDIA hardware
- Configure appropriate blur and shadow settings for performance
- Optimize waybar update intervals for system resource monitoring

### Theming and Consistency

- Use consistent color scheme across Hyprland, waybar, and fuzzel
- Ensure proper font configuration and sizing
- Maintain visual consistency with existing applications (kitty, vivaldi, etc.)

### Future Extensibility

- Design configuration structure to easily add new waybar modules
- Allow for easy addition of new Hyprland keybindings and rules
- Structure files to support theming variations and user customization