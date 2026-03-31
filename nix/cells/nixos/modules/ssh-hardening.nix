{ config, pkgs, ... }:

{
  # Harden OpenSSH for emergency fallback only
  services.openssh = {
    enable = true;
    
    settings = {
      # Disable weak auth methods
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      
      # Modern crypto only
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
        "hmac-sha2-256-etm@openssh.org"
      ];
      
      # Rate limiting
      MaxAuthTries = 3;
      MaxSessions = 2;
      ClientAliveInterval = 60;
      ClientAliveCountMax = 3;
    };
    
    # Only listen on Tailscale interface (CGNAT range)
    listenAddresses = [
      { addr = "100.64.0.0"; port = 22; }
    ];
  };
  
  # Ensure firewall allows SSH on Tailscale interface
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
}
