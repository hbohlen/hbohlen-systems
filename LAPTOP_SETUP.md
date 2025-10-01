# Laptop Setup Guide

This guide will help you set up your laptop configuration, which is designed to be virtually identical to the desktop configuration but optimized for laptop hardware.

## Pre-Installation Requirements

1. **Boot from NixOS Live ISO** - Download and boot from the latest NixOS unstable ISO
2. **Connect to Internet** - Ensure you have a working internet connection
3. **Identify Your Hardware** - You'll need to identify your laptop's disk and hardware

## Step 1: Identify Your Disk

Before running the installer, you need to identify your laptop's main disk:

```bash
# List all available disk IDs
ls /dev/disk/by-id/

# Look for your main NVMe or SATA drive, usually something like:
# nvme-BRAND_MODEL_SERIAL
# ata-BRAND_MODEL_SERIAL
```

## Step 2: Update Installation Script

Edit the `install.sh` file and update the `DISK` variable with your actual disk ID:

```bash
# Example for an NVMe drive:
DISK="/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S2NS0R123456"

# Example for a SATA SSD:
DISK="/dev/disk/by-id/ata-Samsung_SSD_860_EVO_500GB_S3Z9NB0K123456"
```

## Step 3: Run the Installation

After updating the disk ID:

```bash
sudo -i
git clone https://github.com/hbohlen/hbohlen-systems.git
cd hbohlen-systems
./install.sh
```

## Step 4: Post-Installation Hardware Configuration

After installation, you'll need to update the hardware configuration with your actual hardware details:

1. **Boot into your new system**
2. **Update hardware-configuration.nix**:
   ```bash
   sudo nixos-generate-config --show-hardware-config > /tmp/hw-config.nix
   # Review and merge any missing configurations into:
   # /etc/nixos/hosts/laptop/hardware-configuration.nix
   ```

3. **Update filesystem UUIDs** in `hardware-configuration.nix`:
   ```bash
   # Find your filesystem UUIDs
   sudo blkid
   
   # Update the UUIDs in hardware-configuration.nix
   sudo vim /etc/nixos/hosts/laptop/hardware-configuration.nix
   ```

## Key Differences from Desktop Configuration

The laptop configuration includes the same applications and services as the desktop but with these laptop-specific optimizations:

### Hardware Differences
- **Graphics**: NVIDIA hybrid graphics (Intel iGPU + NVIDIA RTX 3070 Ti) for ASUS ROG Zephyrus M16
- **nixos-hardware**: Uses nixos-hardware modules for ASUS ROG Zephyrus M16 GU603ZW
- **Power Management**: TLP, thermald, and laptop-specific power settings
- **NVIDIA Prime**: Configured for NVIDIA Optimus offload mode for better battery life
- **Hardware Support**: Laptop-specific kernel modules and firmware from nixos-hardware

### Additional Laptop Software
- `powertop` - Power consumption monitoring
- `tlp` - Advanced power management
- `acpi` - ACPI information tools
- `brightnessctl` - Screen brightness control
- `iw` - Wireless configuration tools
- `wpa_supplicant_gui` - WiFi GUI management
- `nvtop` - NVIDIA GPU monitoring tool

### Services Enabled
- `services.tlp.enable = true` - Power management
- `services.thermald.enable = true` - Thermal management (Intel)
- `powerManagement.enable = true` - System power management
- `hardware.nvidia.prime.offload` - NVIDIA Optimus offload mode

### nixos-hardware Integration
The laptop configuration automatically includes hardware-specific optimizations from the nixos-hardware repository:
- ASUS ROG Zephyrus GU603 series profile (`nixos-hardware.nixosModules.asus-zephyrus-gu603h`)
- Optimized kernel parameters for ROG laptops
- Intel CPU and NVIDIA Ampere GPU (RTX 30 series) support
- NVIDIA Prime offload configuration with default bus IDs
- Laptop and SSD optimizations

## Customization for Different Hardware

**Note:** This configuration is now optimized specifically for the ASUS ROG Zephyrus M16 GU603ZW with nixos-hardware integration. For other laptop models, you may need to adjust the nixos-hardware module or remove it.

### NVIDIA Prime Bus IDs
The NVIDIA Prime configuration uses default bus IDs. To verify or update them for your specific system:

```bash
# Check your GPU bus IDs
nix-shell -p pciutils --run "lspci | grep -E 'VGA|3D'"

# Output will look like:
# 00:02.0 VGA compatible controller: Intel Corporation ...
# 01:00.0 3D controller: NVIDIA Corporation ...

# Update the bus IDs in configuration.nix:
# intelBusId = "PCI:0:2:0";   # from 00:02.0
# nvidiaBusId = "PCI:1:0:0";  # from 01:00.0
```

### Using NVIDIA GPU for Specific Applications
The configuration enables NVIDIA Prime offload mode. To run applications on the NVIDIA GPU:

```bash
# Run with NVIDIA GPU
nvidia-offload <application>

# Or use environment variables directly
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia <application>
```

### AMD CPU (for different laptop models)
If you have a different laptop with an AMD CPU, update `hardware-configuration.nix`:
```nix
boot.kernelModules = [ "kvm-amd" ]; # instead of "kvm-intel"
hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
```

### Intel-only Graphics (for different laptop models)
If your laptop has only Intel integrated graphics (no NVIDIA), update `configuration.nix`:
```nix
# Replace NVIDIA graphics section with:
services.xserver.videoDrivers = [ "intel" ];
hardware.graphics = {
  enable = true;
  enable32Bit = true;
};

# Remove NVIDIA-specific environment variables
environment.sessionVariables = {
  NIXOS_OZONE_WL = "1";
};
```

### Different nixos-hardware Module
For different laptop models, check available modules at:
https://github.com/NixOS/nixos-hardware

Then update `flake.nix` to use the appropriate module instead of `asus-zephyrus-gu603h`.

### Different WiFi Chipsets
Most WiFi chipsets are supported out of the box with `hardware.enableRedistributableFirmware = true`, but if you have issues:

1. Check what WiFi hardware you have: `lspci | grep -i wireless`
2. Enable specific firmware if needed in `configuration.nix`

## Troubleshooting

### Boot Issues
- Ensure UUIDs in `hardware-configuration.nix` match your actual partitions
- Check that the disk ID in the installer was correct

### WiFi Not Working
- Verify `hardware.enableRedistributableFirmware = true` is set
- Check if your WiFi chip needs specific firmware packages

### Power Management
- If battery life is poor, check `powertop` for power-hungry processes
- Adjust TLP settings in `/etc/tlp.conf` if needed

### Graphics Issues
- For Intel graphics problems, try different drivers: `"modesetting"` instead of `"intel"`
- For NVIDIA on laptops, ensure power management is enabled

## Rebuilding After Changes

After making any configuration changes:

```bash
sudo nixos-rebuild switch --flake .#laptop
```

This will rebuild your system with the new configuration.