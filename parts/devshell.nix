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
    devShells.default = pkgs.mkShell {
      name = "hbohlen-systems";

      packages = [];

      shellHook = ''
        echo "Entering hbohlen-systems base environment..."
        echo "Tip: use 'nix develop .#ai' for the AI agent shell"
        
        # Tools and standard environment variables are mapped by home-manager
      '';
    };

    devShells.ai = pkgs.mkShell {
      name = "hbohlen-systems-ai";

      packages = with pkgs; [
        llm-agents-packages.omp
        llm-agents-packages.cli-proxy-api
        llm-agents-packages.ccusage-opencode
        llm-agents-packages.ccusage-pi
        llm-agents-packages.openspec
      ];

      shellHook = ''
        echo "Entering hbohlen-systems AI agent shell..."
        echo "Available environment tools: cli-proxy-api, ccusage, openspec"
        echo "Agents (pi, opencode, qwen, hermes) remain available from your global configuration."
      '';
    };
  };
}
