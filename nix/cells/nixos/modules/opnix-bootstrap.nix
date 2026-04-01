# Tailscale + opnix bootstrap module
{ config, pkgs, ... }:

let
  # From 1Password: op read op://hbohlen-systems/tailscale/authKey
  tailscaleAuthKey = "tskey-auth-k8dtzB3tS821CNTRL-yxmcjnUZmd3yXxLfZbN7d3ehY84oYfTe";
  tailscaleTags = "tag:server,tag:prod";
in
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--ssh"
      "--advertise-tags=${tailscaleTags}"
      "--authkey=${tailscaleAuthKey}"
    ];
  };

  systemd.services.tailscale.wantedBy = [ "multi-user.target" ];

  services.onepassword-secrets = {
    enable = true;
    tokenFile = "/etc/opnix-token";

    secrets = {
      caddyTailscaleEnv = {
        reference = "op://hbohlen-systems/tailscale/authKey";
        owner = config.services.caddy.user;
        mode = "0600";
        services = [ "caddy" ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    tailscale
    _1password-cli
  ];

  # Bootstrap service: fetch opnix token from setec relay on hbohlen-01
  systemd.services.opnix-bootstrap = {
    description = "Fetch opnix token from setec relay and hydrate secrets";
    after = [ "network.target" "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeScript "opnix-bootstrap.sh" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        # Wait for Tailscale to be ready
        sleep 10

        # Fetch token from hbohlen-01 setec relay
        TOKEN=$(tailscale --host=setec setec get opnix-token 2>/dev/null || echo "")

        if [ -n "$TOKEN" ]; then
          echo "$TOKEN" > /etc/opnix-token
          chmod 600 /etc/opnix-token
          echo "opnix token fetched and stored"
        else
          echo "WARNING: Could not fetch opnix token from setec relay"
        fi
      '';
    };
  };
}
