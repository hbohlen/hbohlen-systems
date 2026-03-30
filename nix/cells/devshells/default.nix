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

          # Start fish if not already in fish
          if [[ -z "$FISH_VERSION" ]]; then
            exec ${pkgs.fish}/bin/fish
          fi
        '';
      };
    };
}
