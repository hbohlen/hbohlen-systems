{ config, pkgs, lib, ... }:

{
    imports = [

    ];
    
    hardware.enableRedistributableFirmware = true;
    hardware.firmware = with pkgs; [ linux-firmware ];
    
    services.fwupd.enable = true;
    
    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.extraModprobeConfig = ''
      options rtw89_core disable_ps_mode=y
    '';

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" "amdgpu" ];
    boot.initrd.kernelModules = [ "kvm_amd" ];

    boot.initrd.postResumeCommands = lib.mkAfter ''
        mkdir /btrfs_tmp
        mount /dev/mapper/cryptroot /btrfs_tmp
        if [[ -e /btrfs_tmp/root ]]; then
            mkdir -p /btrfs_tmp/old_roots
            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
            mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
        fi

        delete_subvolume_recursively() {
            IFS=$'\n'
            for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                delete_subvolume_recursively "/btrfs_tmp/$i"
            done
            btrfs subvolume delete "$1"
        }

        for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
            delete_subvolume_recursively "$i"
        done

        btrfs subvolume create /btrfs_tmp/root
        umount /btrfs_tmp
    '';

    # Network configuration
    networking = {
        hostName = "yoga7";
        networkmanager.enable = true;
    };

    # Time zone
    time.timeZone = "America/Chicago";

    # Locale settings
    i18n.defaultLocale = "en_US.UTF-8";

    users.mutableUsers = false;
    users.users.root.initialHashedPassword = "$6$ZHwIJqKn6TnBjrhF$k0YYXHl2ZPpeYuCi1s9.BUk8DMJtDNqbIvHDS2IhlaeJfkBh04qZjfF92yxWpdL9wHRaIKRPELQevWIVK92Qv.";
    
    users.users.hbohlen = {
        isNormalUser = true;
        description = "Hayden Bohlen";
        extraGroups = [ 
            "wheel"
            "networkmanager"
        ];
        initialHashedPassword = "$6$ZHwIJqKn6TnBjrhF$k0YYXHl2ZPpeYuCi1s9.BUk8DMJtDNqbIvHDS2IhlaeJfkBh04qZjfF92yxWpdL9wHRaIKRPELQevWIVK92Qv.";
    };

    # Enable sudo for wheel group without password
    security.sudo.wheelNeedsPassword = false;

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
        vim
        git
        brave
        vscode
        nodejs_22
        python311
        uv
        wget
        curl
        htop
        neofetch
        kitty
        zsh
        oh-my-zsh
        starship
        pciutils
        linux-firmware
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.settings.trusted-users = [ "root" "hbohlen" ];

    services.openssh = {
        enable = true;
        settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
        };
    };

    programs.zsh = {
        enable = true;
        ohMyZsh = {
            enable = true;
            theme = "agnoster";
            plugins = [ "git" "npm" "node" ];
        };
    };

    programs.starship.enable = true;
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;
   
    environment.gnome.excludePackages = with pkgs; [
        gnome-tour
    ];

    environment.persistence."/persist" = {
        hideMounts = true;

        directories = [
            "/var/log"
            "/var/lib/nixos"
            "/var/lib/systemd/coredump"
            "/etc/NetworkManager/system-connections"
        ];

        files = [
            "/etc/machine-id"
            "/etc/shadow"
        ];

        users.hbohlen = {
            directories = [
                "dev"
                "Downloads"
                { directory = ".ssh"; mode = "0700";  }
                # Brave browser profile
                { directory = ".config/BraveSoftware/Brave-Browser"; mode = "0700"; }
                { directory = ".config/Code"; mode = "0700"; }
                { directory = ".config/kitty"; mode = "0700"; }
                { directory = ".config/oh-my-zsh"; mode = "0700"; }
                { directory = ".config/starship"; mode = "0700"; }
                { directory = ".local/share/gnome-shell"; mode = "0700"; }
                { directory = ".local/share/gnome-settings-daemon"; mode = "0700"; }
                { directory = ".local/share/gnome-session"; mode = "0700"; }
                { directory = ".local/share/keyrings"; mode = "0700"; }
                { directory = ".config/dconf"; mode = "0700"; }
            ];
            files = [ ];
        };
    };

    system.stateVersion = "25.05";
}
