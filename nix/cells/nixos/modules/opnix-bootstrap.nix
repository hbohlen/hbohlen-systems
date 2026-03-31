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
}
