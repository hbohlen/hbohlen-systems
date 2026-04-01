{ inputs, ... }:

{
  flake.homeConfigurations.hbohlen = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [
      {
        home.stateVersion = "24.11";
        home.homeDirectory = "/home/hbohlen";
        home.username = "hbohlen";

        programs.ssh = {
          enable = true;
          extraConfig = ''
            IdentityAgent ~/.ssh/agent.sock
          '';
        };

        home.sessionVariables = {
          OP_SERVICE_ACCOUNT_TOKEN_FILE = "/etc/opnix-token";
        };
      }
    ];
  };
}
