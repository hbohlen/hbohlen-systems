{ inputs, ... }:
{
  perSystem = { config, self', inputs', pkgs, system, ... }:
    let
      # Import llm-agents packages
      llm-agents-packages = inputs.llm-agents.packages.${system};
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

          # Start fish if not already in fish and running interactively
          if [[ -z "$FISH_VERSION" && -t 0 ]]; then
            exec ${pkgs.fish}/bin/fish
          fi
        '';
      };
    };
}
