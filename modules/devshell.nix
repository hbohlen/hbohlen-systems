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
    agent-menu = pkgs.writeShellApplication {
      name = "agent-menu";
      runtimeInputs = with pkgs; [
        tmux
        git
        fish
        gnused
        gnugrep
        coreutils
      ];
      text = ''
        set -euo pipefail

        AGENT_BIN_opencode="${llm-agents-packages.opencode}/bin/opencode"
        AGENT_BIN_pi="${llm-agents-packages.pi}/bin/pi"
        AGENT_BIN_hermes="${llm-agents-packages.hermes-agent}/bin/hermes-agent"
        NIX_BIN="${pkgs.nix}/bin/nix"

        list_sessions() {
          echo ""
          echo "=== Active tmux sessions ==="
          echo ""
          local i=1
          while IFS= read -r line; do
            local session_name
            session_name=$(echo "$line" | cut -d: -f1)
            local agent_type="unknown"
            if echo "$session_name" | grep -q "opencode"; then
              agent_type="opencode"
            elif echo "$session_name" | grep -q "pi"; then
              agent_type="pi"
            elif echo "$session_name" | grep -q "hermes"; then
              agent_type="hermes"
            fi
            local created
            created=$(tmux display-message -t "$session_name" -p '#{session_created}' 2>/dev/null || echo "0")
            local age=""
            if [ "$created" != "0" ]; then
              local now
              now=$(date +%s)
              local diff=$((now - created))
              if [ "$diff" -lt 3600 ]; then
                age="$((diff / 60))m ago"
              elif [ "$diff" -lt 86400 ]; then
                age="$((diff / 3600))h ago"
              else
                age="$((diff / 86400))d ago"
              fi
            fi
            echo "  $i) $session_name [$agent_type] ($age)"
            i=$((i + 1))
          done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null)
          echo ""
        }

        select_agent() {
          echo "Select agent type:"
          echo "  1) opencode"
          echo "  2) pi"
          echo "  3) hermes-agent"
          echo ""
          printf "Choice [1-3]: "
          read -r choice
          case "$choice" in
            1) AGENT="opencode"; AGENT_CMD="$AGENT_BIN_opencode" ;;
            2) AGENT="pi"; AGENT_CMD="$AGENT_BIN_pi" ;;
            3) AGENT="hermes"; AGENT_CMD="$AGENT_BIN_hermes" ;;
            *) echo "Invalid choice"; exit 1 ;;
          esac
        }

        create_session() {
          select_agent

          printf "Project path: "
          read -r project_path
          project_path=$(eval echo "$project_path")

          if [ ! -d "$project_path/.git" ]; then
            echo "Error: $project_path is not a git repository"
            exit 1
          fi

          local date_tag
          date_tag=$(date +%Y%m%d)
          local worktree_name="agent-''${AGENT}-''${date_tag}"
          local branch_name="agent/''${AGENT}-''${date_tag}"
          local worktree_path="$project_path/.worktrees/$worktree_name"

          echo "Creating worktree: $worktree_path"
          mkdir -p "$project_path/.worktrees"
          git -C "$project_path" worktree add -b "$branch_name" "$worktree_path" 2>/dev/null || \
            git -C "$project_path" worktree add "$worktree_path" 2>/dev/null || true

          local session_name
          session_name=$(basename "$project_path")"-''${AGENT}"

          echo "Creating tmux session: $session_name"
          tmux new-session -d -s "$session_name" -n shell -c "$worktree_path" \
            "$NIX_BIN develop --command fish"

          tmux new-window -t "$session_name" -n "$AGENT" -c "$worktree_path" \
            "$NIX_BIN develop --command $AGENT_CMD"

          echo "Attaching to session: $session_name"
          tmux attach-session -t "$session_name"
        }

        attach_session() {
          local sessions
          sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null)
          if [ -z "$sessions" ]; then
            echo "No sessions to attach to"
            return
          fi

          printf "Enter session number: "
          read -r num
          local session
          session=$(echo "$sessions" | sed -n "''${num}p")
          if [ -n "$session" ]; then
            tmux attach-session -t "$session"
          else
            echo "Invalid session number"
          fi
        }

        main() {
          local has_sessions=false
          if tmux list-sessions &>/dev/null; then
            has_sessions=true
            list_sessions
          else
            echo ""
            echo "No active tmux sessions"
            echo ""
          fi

          echo "=== agent-menu ==="
          echo "  n) New session"
          if [ "$has_sessions" = true ]; then
            echo "  a) Attach to session"
          fi
          echo "  q) Quit"
          echo ""
          printf "Choice: "
          read -r action

          case "$action" in
            n) create_session ;;
            a)
              if [ "$has_sessions" = true ]; then
                attach_session
              else
                echo "No sessions available"
              fi
              ;;
            q) exit 0 ;;
            *) echo "Invalid choice" ;;
          esac
        }

        main "$@"
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
        nil
        lua-language-server
        stylua
        ast-grep
        tmux
      ];

      shellHook = ''
        echo "Entering hbohlen-systems devShell..."
        export SHELL=${pkgs.fish}/bin/fish

        export STARSHIP_CONFIG=${starshipConfig}
        export XDG_CONFIG_HOME="$PWD/.nix-devshell-config"
        mkdir -p "$XDG_CONFIG_HOME/fish"
        cp ${fishConfig} "$XDG_CONFIG_HOME/fish/config.fish"

        echo "Tip: use 'nix develop .#ai' for the AI agent shell"
      '';
    };

    devShells.ai = pkgs.mkShell {
      name = "hbohlen-systems-ai";

      packages = with pkgs; [
        llm-agents-packages.pi
        llm-agents-packages.omp
        llm-agents-packages.cli-proxy-api
        llm-agents-packages.qwen-code
        llm-agents-packages.hermes-agent
        llm-agents-packages.ccusage-opencode
        llm-agents-packages.ccusage-pi
        llm-agents-packages.rtk
        llm-agents-packages.opencode
        llm-agents-packages.openspec
        tmux
        agent-menu
      ];

      shellHook = ''
        echo "Entering hbohlen-systems AI agent shell..."
        echo "Available agents: pi, omp, opencode, qwen-code, hermes-agent"
        echo "Tools: cli-proxy-api, rtk, ccusage-opencode, ccusage-pi, openspec"
      '';
    };
  };
}
