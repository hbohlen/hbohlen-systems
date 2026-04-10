{lib, ...}: let
  deployKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICP6MnCIoDGFnx42wAmVgoNxaHxEtRnOF10d3q/xOIZG hbohlen@hetzner";
in {
  imports = lib.optionals (builtins.pathExists ./hbohlen-01-hardware-configuration.nix) [
    ./hbohlen-01-hardware-configuration.nix
  ];

  networking.hostName = "hbohlen-01";

  users.users.root.openssh.authorizedKeys.keys = [deployKey];

  networking.usePredictableInterfaceNames = true;
  boot.initrd.availableKernelModules = [
    "virtio_net"
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
  ];

  services.opencode.enable = true;
  
  services.pi-web-ui = {
    enable = true;
    port = 3000;
    user = "hbohlen";
    authFilePath = "/home/hbohlen/.pi/agent/auth.json";
  };

  services.caddy = {
    tailscaleEnable = true;
    enablePiWebUi = true;
    piWebUiHost = "mnemosyne.hbohlen.systems";
  };
}
