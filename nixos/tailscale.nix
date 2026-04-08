{
  config,
  pkgs,
  lib,
  ...
}: let
  tailscaleTags = "tag:server,tag:prod";
in {
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

  systemd.services.tailscale.wantedBy = ["multi-user.target"];

  services.onepassword-secrets = {
    enable = true;
    tokenFile = "/etc/opnix-token";

    secrets = {
      caddyTailscaleAuthKey = {
        reference = "op://hbohlen-systems/tailscale/authKey";
        owner = config.services.caddy.user;
        mode = "0600";
        services = ["caddy"];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    tailscale
    _1password-cli
  ];
}
