{ config, pkgs, ... }:

{
  services.fail2ban = {
    enable = true;
    
    # Global settings
    maxretry = 3;
    findtime = "10m";
    bantime = "1h";
    
    # Extra daemon config
    extraDaemonConfig = ''
      [DEFAULT]
      backend = systemd
      usedns = no
      logencoding = utf-8
    '';
    
    # SSH jail for brute force protection
    jails = {
      sshd = ''
        enabled = true
        filter = sshd
        action = iptables-multiport[name=SSH, port="ssh", protocol=tcp]
        logpath = /var/log/auth.log
        backend = %(sshd_backend)s
      '';
      
      # Additional protection for Tailscale SSH (logs to same auth.log)
      sshd-tailscale = ''
        enabled = true
        filter = sshd
        action = iptables-multiport[name=SSH-TAILSCALE, port="ssh", protocol=tcp]
        logpath = /var/log/auth.log
        maxretry = 5
        findtime = 15m
      '';
    };
  };
  
  # Ensure log directory exists
  systemd.tmpfiles.rules = [
    "d /var/log 0755 root root -"
  ];
}
