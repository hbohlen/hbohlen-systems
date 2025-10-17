{ ... }: {
  # Disk configuration using disko for automated disk partitioning
 # Optimized for AMD Ryzen laptop with SSD, btrfs filesystem, and impermanence
  # This configuration sets up a disk with GPT partitioning, encrypted root partition using LUKS,
  # and btrfs subvolumes for different system directories to enable better snapshot management
  
  disko.devices = {
    disk.main = {
      type = "disk";
      # Using device by-id for better persistence across reboots/reconnections
      # For AMD Ryzen laptop with NVMe SSD, update this to match your actual disk ID
      device = "/dev/disk/by-id/nvme-WD_PC_SN7100S_SDFPMSL-1T00-1101_25112Q801629"; # Your actual disk ID - Western Digital Black SN710 1TB NVMe SSD
      
      content = {
        type = "gpt";
        # Define a custom label for better identification
        label = "main-disk";

        partitions = {
          # EFI System Partition for UEFI boot
          boot = {
            name = "boot";
            size = "512M"; # Increased size for AMD platform compatibility
            type = "EF00"; # EFI System Partition type
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "defaults" ];
            };
          };

          # Swap partition for hibernation support on AMD Ryzen laptop
          swap = {
            name = "swap";
            size = "16G"; # Match RAM size for hibernation support
            type = "8200"; # Linux swap type
            content = {
              type = "swap";
              # Enable discard for SSD
              settings = {
                # Use discard to support TRIM on SSD
                discard = true;
              };
            };
          };

          # Encrypted root partition containing btrfs subvolumes
          luks = {
            name = "luks-root";
            size = "100%"; # Use remaining space
            content = {
              type = "luks";
              name = "cryptroot";
              
              # Security and performance settings optimized for AMD Ryzen laptop with SSD
              settings = {
                allowDiscards = true; # Enable TRIM/Discard for SSD longevity
                # Additional LUKS settings can be added here if needed
              };
              
              content = {
                type = "btrfs";
                # Create a label for the btrfs filesystem
                label = "nixos-root";
                # Additional btrfs-specific arguments
                extraArgs = [ "-f" ]; # Force overwrite if needed
                
                # Define subvolumes for different system directories
                # This allows for independent snapshotting and management
                subvolumes = {
                  # Root filesystem - optimized for SSD and AMD Ryzen
                  "root" = {
                    mountpoint = "/";
                    # Performance and compression options for SSD on AMD platform
                    mountOptions = [
                      "ssd"              # Enable SSD-specific optimizations
                      "compress=zstd"    # Compress data with zstd algorithm (good balance of speed/compression)
                      "noatime"          # Don't update access time (performance)
                      "space_cache=v2"   # Use version 2 space cache (performance)
                      "autodefrag"       # Enable automatic defragmentation
                      "discard=async"    # Enable async discard for better SSD performance
                    ];
                  };
                  
                  # Home directory - optimized for SSD
                  "home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "ssd"
                      "compress=zstd"
                      "noatime"
                      "space_cache=v2"
                      "autodefrag"
                      "discard=async"
                    ];
                  };
                  
                  # Nix store (separate for potential sharing between systems)
                  # Optimized for frequent writes typical of Nix operations
                  "nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "ssd"
                      "compress=zstd"
                      "noatime"
                      "space_cache=v2"
                      # Disable COW for nix store to improve performance for package operations
                      "nodatacow"
                      "discard=async"
                    ];
                  };
                  
                  # Persistent storage (for impermanence setup)
                  # Critical for maintaining state between reboots
                  "persist" = {
                    mountpoint = "/persist";
                    mountOptions = [
                      "ssd"
                      "compress=zstd"
                      "noatime"
                      "space_cache=v2"
                      "autodefrag"
                      "discard=async"
                    ];
                  };
                  
                  # Log directory (separate for better management)
                  # Frequent writes require specific optimizations
                  "log" = {
                    mountpoint = "/var/log";
                    mountOptions = [
                      "ssd"
                      "compress=zstd"
                      "noatime"
                      "space_cache=v2"
                      "autodefrag"
                      "discard=async"
                    ];
                  };
                  
                  # Temporary files - optimized for frequent write operations
                  "tmp" = {
                    mountpoint = "/tmp";
                    mountOptions = [
                      "ssd"
                      "compress=zstd"
                      "noatime"
                      "space_cache=v2"
                      "autodefrag"
                      "discard=async"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Ensure critical filesystems are available during boot
 # This is necessary for impermanence setups where these volumes are separate
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/var/log".neededForBoot = true;
  
  # Additional filesystem options that might be needed
  # boot.initrd.luks.devices.cryptroot.allowDiscards = true; # Already set in LUKS settings
  
  # Enable swap for hibernation support on the AMD Ryzen laptop
  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
 ];
}
