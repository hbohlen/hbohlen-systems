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

    pi-nix-suite = pkgs.callPackage ../nix/cells/pi-nix-suite/default.nix {inherit pkgs;};

    fishConfig = pkgs.writeTextFile {
      name = "devshell-fish-config";
      text = ''
        # hbohlen-systems devShell fish configuration

        if command -v starship > /dev/null
            starship init fish | source
        end

        if command -v zoxide > /dev/null
            zoxide init fish | source
        end

        if command -v direnv > /dev/null
            direnv hook fish | source
        end

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

        abbr -a l 'eza --icons --group-directories-first'
        abbr -a la 'eza -a --icons --group-directories-first'
        abbr -a ll 'eza -la --icons --group-directories-first'
        abbr -a lt 'eza --tree --icons'

        abbr -a n nvim
        abbr -a v nvim

        abbr -a nb 'nix build'
        abbr -a nr 'nix run'
        abbr -a nf 'nix flake'

        echo "Welcome to hbohlen-systems devShell"
        echo "Fish shell with starship, zoxide, and abbreviations ready"
      '';
    };

    starshipConfig = pkgs.writeTextFile {
      name = "starship-config";
      text = ''
        format = """
        $directory$git_branch$git_status
        $character"""

        [directory]
        truncation_length = 3
        truncation_symbol = ".../"
        format = "[$path]($style) "
        style = "cyan"

        [git_branch]
        symbol = ""
        format = "[$symbol$branch]($style) "
        style = "purple"

        [git_status]
        format = '([$all_status$ahead_behind]($style) )'
        style = "yellow"
        conflicted = "✘"
        ahead = "⇡"
        behind = "⇣"
        diverged = "⇕"
        up_to_date = ""
        untracked = "?"
        stashed = ""
        modified = "✎"
        staged = "+"
        renamed = "→"
        deleted = "✘"

        [character]
        success_symbol = "[>](green)"
        error_symbol = "[>](red)"

        [username]
        disabled = true
        [hostname]
        disabled = true
        [time]
        disabled = true
        [cmd_duration]
        disabled = true
        [line_break]
        disabled = true
        [battery]
        disabled = true
      '';
    };
  in {
    devShells.default = pkgs.mkShell {
      name = "hbohlen-systems";

      packages = with pkgs; [
        fish
        starship
        direnv
        nix-direnv
        nix
        eza
        ripgrep
        zoxide
        fzf
        neovim
        git
        gh
        llm-agents-packages.pi
        llm-agents-packages.omp
        llm-agents-packages.cli-proxy-api
        llm-agents-packages.qwen-code
        llm-agents-packages.hermes-agent
        llm-agents-packages.ccusage-opencode
        llm-agents-packages.ccusage-pi
        llm-agents-packages.rtk
        pi-nix-suite
        nil
        lua-language-server
        stylua
        ast-grep
      ];

      shellHook = ''
        echo "Entering hbohlen-systems devShell..."
        export SHELL=${pkgs.fish}/bin/fish

        export STARSHIP_CONFIG=${starshipConfig}
        export XDG_CONFIG_HOME="$PWD/.nix-devshell-config"
        mkdir -p "$XDG_CONFIG_HOME/fish"
        cp ${fishConfig} "$XDG_CONFIG_HOME/fish/config.fish"

        if [[ -d "${pi-nix-suite}/share" ]]; then
          export PI_NIX_SUITE_DIR="${pi-nix-suite}/share"
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
