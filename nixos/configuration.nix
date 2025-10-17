
{ config, pkgs, lib, ... }:

{
    imports = [

    ];

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
    # User account
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
                { directory = ".ssh"; mode = "0700";  }  # Example of setting mode
            ];
            files = [ ];
        };
    };

    system.stateVersion = "25.05"; # Update this when changing NixOS versions
}
