{ ... }:

let
  diskDevice = "/dev/sda";
in
{
  disko.devices = {
    disk.main = {
      device = diskDevice;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          bios = {
            name = "bios";
            size = "1M";
            type = "EF02";
          };

          boot = {
            name = "boot";
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };

          root = {
            name = "root";
            size = "100%";
            content = {
              type = "btrfs";
              subvolumes = {
                root = {
                  mountpoint = "/";
                };
                nix = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                home = {
                  mountpoint = "/home";
                };
                var = {
                  mountpoint = "/var";
                };
                tmp = {
                  mountpoint = "/tmp";
                };
              };
            };
          };
        };
      };
    };
  };
}
