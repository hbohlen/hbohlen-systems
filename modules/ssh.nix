{
  config,
  pkgs,
  lib,
  ...
}: {
  # NixOS: OpenSSH server with hardening
  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";

      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
      ];
      KexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
      ];

      MaxAuthTries = 3;
      MaxSessions = 2;
      ClientAliveInterval = 60;
      ClientAliveCountMax = 3;
    };

    listenAddresses = [
      {
        addr = "0.0.0.0";
        port = 22;
      }
    ];
  };

  # Firewall: allow SSH on Tailscale interface
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [22];
}
