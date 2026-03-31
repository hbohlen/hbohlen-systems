{ inputs, ... }:
{
  perSystem = { config, self', inputs', pkgs, system, ... }:
    let
      # Import llm-agents packages
      llm-agents-packages = inputs.llm-agents.packages.${system};
      
      # Import pi-nix-suite
      pi-nix-suite = pkgs.callPackage ../pi-nix-suite/default.nix { inherit pkgs; };
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

          # AI/Agents
          llm-agents-packages.pi
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

          # Set starship config
          export STARSHIP_CONFIG=${./config/starship.toml}

          # Set fish config directory for this shell
          export XDG_CONFIG_HOME="$PWD/.nix-devshell-config"
          mkdir -p "$XDG_CONFIG_HOME/fish"
          cp ${./config/config.fish} "$XDG_CONFIG_HOME/fish/config.fish"
          
          # Setup pi-nix-suite
          if [[ -d "${pi-nix-suite}/share" ]]; then
            export PI_NIX_SUITE_DIR="${pi-nix-suite}/share"
            # Auto-link commands if not already present
            if [[ ! -L "$HOME/.pi/agent/commands/subagent" ]]; then
              echo "Setting up pi-nix-suite commands..."
              ${pi-nix-suite}/bin/pi-nix-suite-setup 2>/dev/null || true
            fi
          fi

          # Start fish if not already in fish and running interactively
          if [[ -z "$FISH_VERSION" && -t 0 ]]; then
            exec ${pkgs.fish}/bin/fish
          fi
        '';
      };
    };
}
