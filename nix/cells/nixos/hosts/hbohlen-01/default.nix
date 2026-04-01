{ lib, ... }:

let
  deployKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICP6MnCIoDGFnx42wAmVgoNxaHxEtRnOF10d3q/xOIZG hbohlen@hetzner";
in
{
  imports = lib.optionals (builtins.pathExists ./hardware-configuration.nix) [
    ./hardware-configuration.nix
    ../../modules/gno-daemon.nix
    ../../modules/gno-serve.nix
  ];


  # Hostname
  networking.hostName = "hbohlen-01";

  # SSH authorized keys for root and hbohlen
  users.users.root.openssh.authorizedKeys.keys = [ deployKey ];
  users.users.hbohlen.openssh.authorizedKeys.keys = [ deployKey ];

  # Hetzner Cloud specific settings
  networking.usePredictableInterfaceNames = true;
  boot.initrd.availableKernelModules = [
    "virtio_net"
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
  ];

  # Enable opencode web UI
  services.opencode = {
    enable = true;
    port = 8080;
  };

  # Enable GNO knowledge engine
  services.gno-daemon = {
    enable = true;
    user = "hbohlen";
    collectionPath = "/home/hbohlen/mnemosyne";
  };

  services.gno-serve = {
    enable = true;
    port = 8081;
  };
  # Enable Caddy with Tailscale integration
  services.caddy.tailscaleEnable = true;
}
