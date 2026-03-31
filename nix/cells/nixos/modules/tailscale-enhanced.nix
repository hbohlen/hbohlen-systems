{ config, pkgs, ... }:

let
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
      "--reset"
    ];
  };
  
  systemd.services.tailscale.wantedBy = [ "multi-user.target" ];
  environment.systemPackages = [ pkgs.tailscale ];
}
