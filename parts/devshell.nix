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

      packages = [
        llm-agents-packages.beads
      ];

      shellHook = ''
        echo "hbohlen-systems"
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
