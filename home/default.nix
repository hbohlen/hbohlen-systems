{inputs, ...}: {
  perSystem = {
    config,
    self',
    inputs',
    pkgs,
    system,
    ...
  }: let
    llm-agents-packages = inputs.llm-agents.packages.${system};
  in {
    home-manager.users.hbohlen = {
      pkgs,
      ...
    }: {
      imports = [
        ./tmux.nix
        ./ssh-client.nix
        ./session-vars.nix
      ];

      home = {
        stateVersion = "24.11";
        homeDirectory = "/home/hbohlen";
        username = "hbohlen";
      };

      packages = [
        llm-agents-packages.beads
      ];
    };
  };
}
