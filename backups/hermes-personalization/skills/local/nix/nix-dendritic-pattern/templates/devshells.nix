# nix/cells/devshells/default.nix
# Development shells for the project

{ config, lib, ... }:
{
  perSystem = { config, self', inputs', pkgs, system, ... }: {
    devShells.default = pkgs.mkShell {
      name = "PROJECT_NAME";
      
      packages = with pkgs; [
        # Core tools
        git
        neovim
        
        # Navigation & search
        eza
        ripgrep
        zoxide
        fzf
        
        # Shell
        fish
        starship
        
        # Environment
        direnv
        nix-direnv
      ];
      
      shellHook = ''
        echo "Welcome to the PROJECT_NAME devShell!"
        
        # Initialize tools
        eval "$(starship init bash)"
        eval "$(zoxide init bash)"
        
        # Auto-activate fish if available and not already in fish
        if command -v fish >/dev/null 2>&1 && [ -z "$FISH_VERSION" ]; then
          exec fish
        fi
      '';
    };
    
    # Additional devShells can be added here
    # devShells.special = pkgs.mkShell { ... };
  };
}
