{ pkgs, starshipConfig }:

let
  fishConfig = pkgs.writeTextFile {
    name = "devshell-fish-config";
    text = ''
      # hbohlen-systems devShell fish configuration

      # Initialize starship prompt
      if command -v starship > /dev/null
          starship init fish | source
      end

      # Initialize zoxide (smart cd)
      if command -v zoxide > /dev/null
          zoxide init fish | source
      end

      # Initialize direnv
      if command -v direnv > /dev/null
          direnv hook fish | source
      end

      # Abbreviations
      # Git
      abbr -a g git
      abbr -a gs 'git status'
      abbr -a gd 'git diff'
      abbr -a gds 'git diff --staged'
      abbr -a ga 'git add'
      abbr -a gaa 'git add -A'
      abbr -a gc 'git commit'
      abbr -a gcm 'git commit -m'
      abbr -a gl 'git log --oneline -15'
      abbr -a gp 'git push'
      abbr -a gpl 'git pull'
      abbr -a gco 'git checkout'
      abbr -a gb 'git branch'

      # Navigation
      abbr -a l 'eza --icons --group-directories-first'
      abbr -a la 'eza -a --icons --group-directories-first'
      abbr -a ll 'eza -la --icons --group-directories-first'
      abbr -a lt 'eza --tree --icons'

      # Editor
      abbr -a n nvim
      abbr -a v nvim

      # Nix
      abbr -a nb 'nix build'
      abbr -a nr 'nix run'
      abbr -a nf 'nix flake'

      # Welcome message
      echo "Welcome to hbohlen-systems devShell"
      echo "Fish shell with starship, zoxide, and abbreviations ready"
    '';
  };
in
{
  inherit fishConfig;

  shellHook = ''
    # Set starship config from Nix store
    export STARSHIP_CONFIG=${starshipConfig}

    # Point fish to our Nix-generated config
    export XDG_CONFIG_HOME="$PWD/.nix-devshell-config"
    mkdir -p "$XDG_CONFIG_HOME/fish"
    cp ${fishConfig} "$XDG_CONFIG_HOME/fish/config.fish"
  '';
}