{ config, lib, pkgs, ... }:

{
  # Impermanence module for NixOS system
  # This module sets up the impermanence configuration for the system
  # It defines which directories should persist across reboots and which should be ephemeral

  options = {
    # No special options needed for this basic implementation
  };

 config = {
    # Use activation scripts to set up impermanence
    system.activationScripts.impermanence = {
      text = ''
        # Ensure persist directories exist
        mkdir -p /persist/etc/ssh
        mkdir -p /persist/var/log
        mkdir -p /persist/var/lib
        mkdir -p /persist/var/cache
        mkdir -p /persist/root
        mkdir -p /persist/home/hbohlen

        # Set up persistent symlinks for system directories
        if [ ! -L /etc/ssh ] && [ ! -d /persist/etc/ssh/.git ]; then
          rm -rf /etc/ssh 2>/dev/null || true
          ln -sf /persist/etc/ssh /etc/ssh
        fi
        
        # Set up other persistent directories as needed
        if [ ! -L /var/log ] && [ ! -d /persist/var/log/.git ]; then
          rm -rf /var/log 2>/dev/null || true
          ln -sf /persist/var/log /var/log
        fi
        
        if [ ! -L /root ] && [ ! -d /persist/root/.git ]; then
          rm -rf /root 2>/dev/null || true
          ln -sf /persist/root /root
        fi

        # Ensure proper permissions for persistent directories
        chmod 750 /persist/etc/ssh 2>/dev/null || true
        chmod 600 /persist/etc/ssh/*_key 2>/dev/null || true
        chmod 644 /persist/etc/ssh/*.pub 2>/dev/null || true
      '';
      deps = [ ];
    };

    # Configure home directory impermanence for the user
    # This will be handled in the home-manager configuration
    # users.users.hbohlen.xdg.userDirs.enable = true; # Commented out as this option doesn't exist in system config
  };
}
