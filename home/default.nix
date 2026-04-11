{
  inputs,
  pkgs,
  ...
}: let
  llm-agents-packages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in {
  home-manager.users.hbohlen = {pkgs, ...}: {
    imports = [
      ./tmux.nix
      ./ssh-client.nix
      ./session-vars.nix
    ];

    home = {
      stateVersion = "24.11";
      homeDirectory = "/home/hbohlen";
      username = "hbohlen";

      file.".pi/agent/extensions/datadog-observability.ts".source = ../pi/extensions/datadog-observability.ts;
      file.".pi/agent/extensions/datadog-observability-config.mjs".source = ../pi/extensions/datadog-observability-config.mjs;
    };

    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        if command -v starship > /dev/null
            starship init fish | source
        end

        if command -v zoxide > /dev/null
            zoxide init fish | source
        end

        if command -v direnv > /dev/null
            direnv hook fish | source
        end

        echo "Welcome to hbohlen-systems (home-manager)"
        echo "Fish shell with starship, zoxide, and abbreviations ready"
      '';
      shellAbbrs = {
        g = "git";
        gs = "git status";
        gd = "git diff";
        gds = "git diff --staged";
        ga = "git add";
        gaa = "git add -A";
        gc = "git commit";
        gcm = "git commit -m";
        gl = "git log --oneline -15";
        gp = "git push";
        gpl = "git pull";
        gco = "git checkout";
        gb = "git branch";

        l = "eza --icons --group-directories-first";
        la = "eza -a --icons --group-directories-first";
        ll = "eza -la --icons --group-directories-first";
        lt = "eza --tree --icons";

        n = "nvim";
        v = "nvim";

        nb = "nix build";
        nr = "nix run";
        nf = "nix flake";
      };
    };

    programs.starship = {
      enable = true;
      settings = {
        format = ''
          $directory$git_branch$git_status
          $character
        '';
        directory = {
          truncation_length = 3;
          truncation_symbol = ".../";
          format = "[$path]($style) ";
          style = "cyan";
        };
        git_branch = {
          symbol = "";
          format = "[$symbol$branch]($style) ";
          style = "purple";
        };
        git_status = {
          format = "([$all_status$ahead_behind]($style) )";
          style = "yellow";
          conflicted = "✘";
          ahead = "⇡";
          behind = "⇣";
          diverged = "⇕";
          up_to_date = "";
          untracked = "?";
          stashed = "";
          modified = "✎";
          staged = "+";
          renamed = "→";
          deleted = "✘";
        };
        character = {
          success_symbol = "[>](green)";
          error_symbol = "[>](red)";
        };
        username.disabled = true;
        hostname.disabled = true;
        time.disabled = true;
        cmd_duration.disabled = true;
        line_break.disabled = true;
        battery.disabled = true;
      };
    };

    home.packages = with pkgs; [
      # Base Terminal Tools
      direnv
      nix-direnv
      nixos-rebuild
      eza
      ripgrep
      zoxide
      fzf
      neovim
      git
      gh
      dolt
      nil
      lua-language-server
      stylua
      ast-grep
      tmux

      # LLM Agents / Tools
      llm-agents-packages.beads
      llm-agents-packages.pi
      llm-agents-packages.qwen-code
      llm-agents-packages.hermes-agent
      llm-agents-packages.rtk
      llm-agents-packages.opencode
    ];
  };
}
