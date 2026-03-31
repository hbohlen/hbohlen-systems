{ config, pkgs, ... }:

{
  # Hostname
  networking.hostName = "hbohlen-01";

  # SSH authorized keys for hbohlen user
  users.users.hbohlen.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICP6MnCIoDGFnx42wAmVgoNxaHxEtRnOF10d3q/xOIZG hbohlen@hetzner"
  ];

  # TEMPORARY: Initial password to prevent lockout if SSH fails
  # Remove after confirming SSH key auth works!
  users.users.hbohlen.initialPassword = "TempPass123!";
  users.users.root.initialPassword = "TempPass123!";

  # Hetzner Cloud specific settings
  # Ensure predictable network interface naming is enabled (default in modern NixOS)
  networking.usePredictableInterfaceNames = true;

  # Boot kernel modules for Hetzner Cloud (required for boot)
  # virtio_blk is CRITICAL - without it the root filesystem won't mount
  boot.initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_blk" "virtio_scsi" ];
}
