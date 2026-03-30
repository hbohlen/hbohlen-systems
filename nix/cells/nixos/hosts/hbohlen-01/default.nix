{ config, pkgs, ... }:

{
  # Hostname
  networking.hostName = "hbohlen-01";

  # SSH authorized keys for hbohlen user
  users.users.hbohlen.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDM5qKdKdB3+QQSFlLn+34xC1qjxqbf5NKdePXKr1QJn hbohlen@hetzner"
  ];

  # Hetzner Cloud specific settings
  # Ensure predictable network interface naming is enabled (default in modern NixOS)
  networking.usePredictableInterfaceNames = true;

  # Boot kernel modules for Hetzner Cloud (if needed)
  boot.initrd.availableKernelModules = [ "virtio_net" "virtio_pci" ];
}
