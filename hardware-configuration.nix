{
  # Hardware configuration for Lenovo Yoga 7 2-in-1 14AKP10 with AMD Ryzen AI 7 350
  # and Radeon 860M graphics
  
  # Import necessary modules for AMD hardware support
  imports = [
    # AMD GPU support (Radeon 860M is RDNA 3.5 based)
    # Note: This system uses integrated graphics, so we enable AMD GPU support
    # for the integrated Radeon 860M GPU
    ({ config, lib, pkgs, ... }: {
      config = {
        # AMD GPU configuration for Radeon 860M
        hardware.graphics = {
          enable = true;
          enable32Bit = true; # For 32-bit applications that need GPU acceleration
          extraPackages = [
            # Open source AMD GPU drivers (Mesa)
            pkgs.mesa
            # Vulkan support
            pkgs.vulkan-loader
            pkgs.vulkan-validation-layers
            pkgs.vulkan-tools
            # OpenCL support for AMD GPUs
            pkgs.clinfo
            # pkgs.opencl-icd  # This may not be available in all nixpkgs versions
            # pkgs.rocm-opencl-icd  # This may not be available in all nixpkgs versions
            # Additional AMD GPU tools
            pkgs.radeontop
            # pkgs.gputop  # This may not be available in all nixpkgs versions
          ];
          extraPackages32 = [
            # 32-bit GPU drivers
            pkgs.driversi686Linux.mesa
          ];
          
        };

        # AMD GPU configuration specifically for Radeon 860M
        # The amdgpu driver is enabled by default when hardware.graphics is enabled
        # Additional AMD-specific settings can go here
        # AMD-specific kernel modules
        boot.initrd.kernelModules = [ 
          "amdgpu" # AMD GPU driver
        ];
        
        # AMD GPU kernel module configuration
        boot.extraModulePackages = [ ];
        
        # Enable AMD microcode updates
        hardware.cpu.amd.updateMicrocode = true;
        
        # Power management for AMD Ryzen processor
        powerManagement = {
          enable = true;
          cpuFreqGovernor = "ondemand"; # Adaptive frequency scaling
        };
        
        # Additional kernel parameters for AMD hardware
        boot.kernelParams = [
          # Enable early KMS (Kernel Mode Setting) for AMD GPUs
          "amdgpu.display=1"
          # Enable AMD GPU power management
          "amdgpu.ppfeaturemask=0xffffffff"
          # Enable Zen power management
          "zenpower.enable=1"
        ];
        
        # Enable AMD P-state driver for modern AMD processors
        # This provides better power management for Ryzen processors
        # services.fwupd.enable = true;  # Enable if firmware updates are needed
        
        # For Ryzen AI 7 350 (Zen 5 based), enable appropriate power management
        environment.etc = {
          "modprobe.d/amd.conf".text = ''
            # Enable AMD GPU power management
            options amdgpu si_support=1 cik_support=1
            # Enable audio support for AMD GPUs
            options snd_hda_intel dmic_detect=0
          '';
        };
      };
    })
  ];

  # System-specific hardware settings
  config = {
    # Boot loader settings for UEFI system
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    
    # File system labels should match the disko configuration
    # The actual mounting is handled by disko configuration
    
    # Enable support for laptop hardware
    # Touchpad configuration for Yoga 2-in-1
    services.xserver = {
      enable = true;
      libinput = {
        enable = true;
        touchpad = {
          naturalScrolling = true;
          tapping = true;
          middleEmulation = true;
        };
      };
    };
    
    # Enable laptop-specific services
    # services.tlp = {
    #   enable = true;
    #   settings = {
    #     # CPU power management for AMD Ryzen
    #     CPU_SCALING_GOVERNOR_ON_AC = "performance";
    #     CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    #
    #     # Disable unnecessary services when on battery
    #     START_CHARGE_THRESH_BAT0 = 75;
    #     STOP_CHARGE_THRESH_BAT0 = 85;
    #   };
    # };
    
    # Enable bluetooth for Yoga 2-in-1 functionality
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
    
    # Audio configuration for AMD hardware
    hardware.pulseaudio.enable = false; # Use pipewire instead
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    
    # Network hardware configuration
    networking.networkmanager.enable = true;
    
    # Hardware-specific packages that may be needed
    # environment.systemPackages = [ ]; # Packages will be added in the main configuration
  };
}