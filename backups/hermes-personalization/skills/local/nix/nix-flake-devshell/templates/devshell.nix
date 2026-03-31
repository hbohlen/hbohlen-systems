{ inputs, ... }:
{
  perSystem = { config, self', inputs', pkgs, system, ... }:
    {
      devShells.default = pkgs.mkShell {
        name = "{{PROJECT_NAME}}";

        packages = with pkgs; [
          # Core shell
          fish
          starship
          direnv
          nix-direnv

          # Navigation & search
          eza
          ripgrep
          zoxide
          fzf

          # Editor & dev tools
          neovim
          git

          # LSPs & formatters
          nil
        ];

        shellHook = ''
          echo "Entering {{PROJECT_NAME}} devShell..."
          export SHELL=${pkgs.fish}/bin/fish

          # Set starship config
          export STARSHIP_CONFIG=${./config/starship.toml}

          # Set fish config directory for this shell
          export XDG_CONFIG_HOME="$PWD/.nix-devshell-config"
          mkdir -p "$XDG_CONFIG_HOME/fish"
          cp ${./config/config.fish} "$XDG_CONFIG_HOME/fish/config.fish"

          # Start fish if not already in fish AND running interactively
          # CRITICAL: [[ -t 0 ]] check required for 'nix develop --command' to work
          if [[ -z "$FISH_VERSION" && -t 0 ]]; then
            exec ${pkgs.fish}/bin/fish
          fi
        '';
      };
    };
}
