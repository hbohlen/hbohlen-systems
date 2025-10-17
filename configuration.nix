{
  config,
  pkgs,
  lib,
  ...
}: {
  # System configuration for Lenovo Yoga 7 2-in-1 14AKP10 with AMD Ryzen AI 7 350
  # This configuration works with the hardware configuration and disko setup
  
  imports = [
    # Import the hardware configuration
    ./hardware-configuration.nix
    
    # Import impermanence module for persistent storage
    ./modules/impermanence.nix
  ];

  # System settings
 # Basic system configuration
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Boot settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Kernel modules needed for hardware
 boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" "amdgpu" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ]; # AMD virtualization support
  boot.extraModulePackages = [ ];
  
  # Enable discard (TRIM) for SSDs
 # This should be handled by disko, but we'll ensure it's enabled
  boot.initrd.luks.devices.cryptroot.allowDiscards = true;

  # Network configuration
 networking = {
    hostName = "yoga7"; # Define your hostname
    networkmanager.enable = true;
    
    # Enable wireless support
    wireless.enable = false; # Use NetworkManager instead
  };
  
  # Time synchronization
  time.timeZone = "America/Chicago";

  # Locale settings
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    # keyMap is set separately to avoid conflicts
    useXkbConfig = true; # Use X11 keyboard layout in console
  };

  # Enable the X11 windowing system
  services.xserver = {
    enable = true;
    layout = "us";
    xkbOptions = "eurosign:e";
    
    # Use libinput as touchpad driver
    libinput.enable = true;
  };

  # Enable the KDE Desktop Environment
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    options = "eurosign:e";
  };

  # Enable CUPS to print documents
  services.printing.enable = true;

  # Enable sound with pipewire
  # sound.enable is deprecated, using pipewire directly
  hardware.pulseaudio.enable = false;  # Disable pulseaudio in favor of pipewire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account
  users.users.hbohlen = {
    isNormalUser = true;
    description = "Heinrich Bohlen";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" ];
    # packages will be defined in home-manager configuration
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile
  # These will be available globally in the system
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
  ];

  # Some programs need SUID wrappers, can be configured further
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Enable automatic login for the user (optional)
  services.getty.autologinUser = null; # Disable autologin by default

  # Enable the OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Enable laptop-specific services
  # Using TLP for power management - note that this conflicts with power-profiles-daemon
  # services.tlp = {
  #   enable = true;
  #   settings = {
  #     # AMD-specific power management
  #     CPU_SCALING_GOVERNOR_ON_AC = "performance";
  #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
  #     CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
  #     CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
  #
  #     # Battery charge thresholds
 #     START_CHARGE_THRESH_BAT0 = 75;
  #     STOP_CHARGE_THRESH_BAT0 = 85;
  #   };
  # };

  # Enable power management
  # CPU frequency scaling
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
  };

  # Additional power management settings for laptop
  # Note: TLP is already enabled, so we don't need power-profiles-daemon as well
  
  # Enable powertop for additional power management
  # services.powertop.enable = true; # This service may not exist in this version of NixOS

  # Enable swap on resume from hibernation
  # This should match the swap partition created in disko
  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Enable touchpad and touchscreen support for Yoga 2-in-1
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = true;
    };
    # Touchscreen is handled by libinput automatically
    # Additional touchscreen-specific settings can be added here if needed
  };
  
  # Additional input device configuration for Yoga 2-in-1
  hardware.xone.enable = false; # Disable if not needed
  # services.udev.packages = [ ]; # Additional udev rules for input devices if needed
  
  # Enable IIO (Industrial I/O) subsystem for sensors like accelerometers
  # This is needed for screen rotation on 2-in-1 laptops
  # services.iio-sensor-proxy.enable = true; # Provides sensor data for screen rotation (commented out due to option not existing)

  # Enable laptop battery and power management
  services.upower.enable = true;

  # Enable automatic optimization for SSDs
 services.fstrim.enable = true; # For SSD wear leveling
  
  # Ensure btrfs-specific settings are properly handled
  # The actual mounting of btrfs subvolumes will be handled by disko
  # Additional security settings

 # Security settings
 security.rtkit.enable = true;
  security.polkit.enable = true;

  # Virtualization support for AMD
  virtualisation = {
    libvirtd.enable = true;
    docker.enable = true;
    # AMD-specific virtualization
    # qemu.package = pkgs.qemu_kvm;
  };

  # System state version - keep this updated to your NixOS version
  system.stateVersion = "24.05"; # Change to your NixOS version
}