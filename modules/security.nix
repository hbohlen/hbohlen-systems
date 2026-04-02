{
  config,
  pkgs,
  ...
}: {
  services.fail2ban = {
    enable = true;

    maxretry = 3;
    bantime = "1h";

    daemonSettings = {
      DEFAULT = {
        backend = "systemd";
        usedns = "no";
        logencoding = "utf-8";
        findtime = "10m";
      };
    };

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

  systemd.tmpfiles.rules = [
    "d /var/log 0755 root root -"
  ];
}
