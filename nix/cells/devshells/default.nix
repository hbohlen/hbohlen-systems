{ inputs, ... }:
{
  perSystem = { config, self', inputs', pkgs, system, ... }:
    let
      # Import llm-agents packages
      llm-agents-packages = inputs.llm-agents.packages.${system};

      # Import pi-nix-suite
      pi-nix-suite = pkgs.callPackage ../pi-nix-suite/default.nix { inherit pkgs; };

      # Import fish config from Nix expression
      fishModule = import ./config/fish.nix {
        inherit pkgs;
        starshipConfig = ./config/starship.toml;
      };
    in
    {
      devShells.default = pkgs.mkShell {
        name = "hbohlen-systems";

        packages = with pkgs; [
          # Core shell
          fish
          starship
          direnv
          nix-direnv

          # Nix tooling
          nix

          # Navigation & search
          eza
          ripgrep
          zoxide
          fzf

          # Editor & dev tools
          neovim
          git
          gh

          # AI/Agents
          llm-agents-packages.pi
          llm-agents-packages.omp
          llm-agents-packages.cli-proxy-api
          llm-agents-packages.qwen-code
          llm-agents-packages.hermes-agent
          llm-agents-packages.ccusage-opencode
          llm-agents-packages.ccusage-pi
          llm-agents-packages.rtk
          pi-nix-suite

          # LSPs & formatters
          nil
          lua-language-server
          stylua
          ast-grep
        ];

        shellHook = ''
          echo "Entering hbohlen-systems devShell..."
          export SHELL=${pkgs.fish}/bin/fish

          # Setup fish config from Nix store
          ${fishModule.shellHook}

          # Setup pi-nix-suite
          if [[ -d "${pi-nix-suite}/share" ]]; then
            export PI_NIX_SUITE_DIR="${pi-nix-suite}/share"
            # Auto-link commands if not already present
            if [[ ! -L "$HOME/.pi/agent/commands/subagent" ]]; then
              echo "Setting up pi-nix-suite commands..."
              ${pi-nix-suite}/bin/pi-nix-suite-setup 2>/dev/null || true
            fi
          fi

          echo "Tip: Use 'nix develop --command fish' to enter fish shell directly"
        '';
      };
    };
}
