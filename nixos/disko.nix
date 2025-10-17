{ ... }:

{
    disko.devices = {
        disk = {
            main = {
                type = "disk";
                device = "/dev/nvme0n1";
                content = {
                    type = "gpt";
                    partitions = {
                        ESP = {
                            size = "1G";
                            type = "EF00";
                            content = {
                                type = "filesystem";
                                format = "vfat";
                                mountpoint = "/boot";  # ✅ Fixed: removed quotes
                            };
                        };
                        luks = {
                            size = "100%";
                            content = {
                                type = "luks";
                                name = "cryptroot";
                                settings.allowDiscards = true;

                                content = {
                                    type = "btrfs";
                                    extraArgs = [ "-f" ];

                                    subvolumes = {
                                        "/root" = {
                                            mountpoint = "/";
                                            mountOptions = [ "compress=zstd" "noatime" ];
                                        };
                                        "/nix" = {
                                            mountpoint = "/nix";
                                            mountOptions = [ "compress=zstd" "noatime" ];
                                        };
                                        "/persist" = {
                                            mountpoint = "/persist";
                                            mountOptions = [ "compress=zstd" "noatime" ];
                                        };
                                        
                                        "/swap" = {
                                            mountpoint = "/swap";
                                            swap.swapfile.size = "16G"; 
                                        };
                                    };
                                };
                            };
                        };
                    };
                };
            };
        };
    };
    fileSystems."/persist".neededForBoot = true;
}