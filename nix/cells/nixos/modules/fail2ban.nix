{ config, pkgs, ... }:

{
  services.fail2ban = {
    enable = true;
    
    # Global settings
    maxretry = 3;
    bantime = "1h";
    
    # Daemon settings (new attribute-based format)
    daemonSettings = {
      DEFAULT = {
        backend = "systemd";
        usedns = "no";
        logencoding = "utf-8";
        findtime = "10m";
      };
    };
    
    # SSH jail for brute force protection
    jails = {
      sshd = {
        enabled = true;
        settings = {
          filter = "sshd";
          action = "iptables-multiport[name=SSH, port=\"ssh\", protocol=tcp]";
          logpath = "/var/log/auth.log";
          backend = "systemd";
        };
      };
      
      # Additional protection for Tailscale SSH (logs to same auth.log)
      sshd-tailscale = {
        enabled = true;
        settings = {
          filter = "sshd";
          action = "iptables-multiport[name=SSH-TAILSCALE, port=\"ssh\", protocol=tcp]";
          logpath = "/var/log/auth.log";
          maxretry = 5;
          findtime = "15m";
          backend = "systemd";
        };
      };
    };
  };
  
  # Ensure log directory exists
  systemd.tmpfiles.rules = [
    "d /var/log 0755 root root -"
  ];
}
