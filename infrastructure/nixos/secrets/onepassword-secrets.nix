# Pure 1Password Secret Injection for hbohlen-systems
# This approach uses 1Password's op:// URI syntax for direct secret injection
# No secrets are stored locally - everything stays in 1Password

{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Helper script to run commands with 1Password secret injection
  opRun = pkgs.writeShellScript "op-run" ''
    set -euo pipefail

    # Check if user is authenticated to 1Password
    if ! op account list >/dev/null 2>&1; then
      echo "Error: Not authenticated to 1Password. Please run: op signin"
      exit 1
    fi

    # Run the command with 1Password secret injection
    exec op run -- "$@"
  '';

  # Helper script to inject secrets into environment files
  createEnvFile = pkgs.writeShellScript "create-env-file" ''
    set -euo pipefail

    target_file="$1"
    template_file="$2"

    if ! op account list >/dev/null 2>&1; then
      echo "Error: Not authenticated to 1Password. Please run: op signin"
      exit 1
    fi

    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$target_file")"

    # Inject secrets and create file
    op inject -i "$template_file" -o "$target_file"
    chmod 600 "$target_file"

    echo "Created $target_file with injected secrets"
  '';

  # Template files for secret injection
  developmentEnvTemplate = pkgs.writeText "development.env.template" ''
    # Development Environment Variables
    # These will be injected by 1Password

    GITHUB_TOKEN=op://Personal/GitHub-API/credential
    DATABASE_PASSWORD=op://Personal/Database/password
    OPENAI_API_KEY=op://Personal/API-Keys/openai
    ANTHROPIC_API_KEY=op://Personal/API-Keys/anthropic
    DOCKER_HUB_TOKEN=op://Personal/Container-Registry/docker-hub
    GHCR_TOKEN=op://Personal/Container-Registry/ghcr

    # Add more environment variables as needed
    # Format: KEY=op://Vault/Item/field
  '';

  # SSH config template for 1Password agent
  sshConfigTemplate = pkgs.writeText "ssh-config.template" ''
    # SSH Configuration with 1Password Integration

    Host github.com
        HostName github.com
        User git
        # Use 1Password SSH agent for key authentication
        IdentityAgent ~/.1password/agent.sock

    Host *
        # Enable 1Password SSH agent globally
        IdentityAgent ~/.1password/agent.sock

    # Add more host configurations as needed
  '';

in
{
  # Install 1Password and CLI
  environment.systemPackages = with pkgs; [
    _1password-gui
    _1password-cli

    # Create helper commands for secret injection
    # Command to run applications with 1Password secret injection
    (writeShellScriptBin "op-run" ''
      ${opRun} "$@"
    '')

    # Command to start development environment with secrets
    (writeShellScriptBin "dev-with-secrets" ''
      echo "Starting development environment with 1Password secrets..."

      if ! op account list >/dev/null 2>&1; then
        echo "Please authenticate to 1Password first:"
        echo "  op signin"
        exit 1
      fi

      # Create temporary environment file with injected secrets
      temp_env=$(mktemp)
      op inject -i ${developmentEnvTemplate} -o "$temp_env"

      # Source the environment and run shell
      echo "Environment loaded. Type 'exit' to return to normal shell."
      env -i bash --rcfile <(echo "source $temp_env; source ~/.bashrc; PS1='[1password] \$PS1'")

      # Clean up
      rm -f "$temp_env"
    '')

    # Command to run git with 1Password authentication
    (writeShellScriptBin "git-with-secrets" ''
      # Set up git credential helper using 1Password
      export GIT_CONFIG_GLOBAL=/dev/null

      op run --env-file=${developmentEnvTemplate} -- \
        git -c credential.helper='!f() { echo username=token; echo password=$GITHUB_TOKEN; }; f' "$@"
    '')

    # Command to run docker commands with registry authentication
    (writeShellScriptBin "docker-with-secrets" ''
      case "$1" in
        "login-docker")
          echo "Logging into Docker Hub..."
          op run -- sh -c 'echo "$DOCKER_HUB_TOKEN" | docker login --username "$DOCKER_USERNAME" --password-stdin'
          ;;
        "login-ghcr")
          echo "Logging into GitHub Container Registry..."
          op run -- sh -c 'echo "$GHCR_TOKEN" | docker login ghcr.io --username "$GITHUB_USERNAME" --password-stdin'
          ;;
        *)
          op run --env-file=${developmentEnvTemplate} -- docker "$@"
          ;;
      esac
    '')

    # Command to setup SSH with 1Password agent
    (writeShellScriptBin "setup-ssh-1password" ''
      echo "Setting up SSH with 1Password agent..."

      # Create SSH config directory
      mkdir -p ~/.ssh
      chmod 700 ~/.ssh

      # Backup existing config if it exists
      if [ -f ~/.ssh/config ]; then
        cp ~/.ssh/config ~/.ssh/config.backup.$(date +%s)
        echo "Backed up existing SSH config"
      fi

      # Create new SSH config with 1Password integration
      cat ${sshConfigTemplate} > ~/.ssh/config
      chmod 600 ~/.ssh/config

      echo "SSH configured to use 1Password agent"
      echo "Make sure 1Password desktop app is running and SSH agent is enabled"
    '')

    # Command to run applications that need database access
    (writeShellScriptBin "run-with-db" ''
      echo "Running command with database credentials from 1Password..."
      op run --env-file=${developmentEnvTemplate} -- "$@"
    '')

    # Command to check 1Password authentication status
    (writeShellScriptBin "check-1password" ''
      echo "Checking 1Password authentication status..."

      if op account list >/dev/null 2>&1; then
        echo "✅ Authenticated to 1Password"
        echo ""
        echo "Available accounts:"
        op account list --format=table
        echo ""
        echo "Available vaults:"
        op vault list --format=table
        echo ""
        echo "Test secret injection:"
        if op inject -i ${developmentEnvTemplate} >/dev/null 2>&1; then
          echo "✅ Secret injection working"
        else
          echo "❌ Secret injection failed - check your vault items"
        fi
      else
        echo "❌ Not authenticated to 1Password"
        echo "Please run: op signin"
      fi
    '')

    # Command to validate vault structure
    (writeShellScriptBin "validate-vault-structure" ''
      echo "Validating 1Password vault structure..."

      if ! op account list >/dev/null 2>&1; then
        echo "❌ Not authenticated to 1Password"
        exit 1
      fi

      # Check required items exist
      required_items=(
        "GitHub-API"
        "Database"
        "API-Keys"
        "Container-Registry"
      )

      vault="Personal"
      all_good=true

      for item in "''${required_items[@]}"; do
        if op item get "$item" --vault="$vault" >/dev/null 2>&1; then
          echo "✅ Found: $item"
        else
          echo "❌ Missing: $item"
          all_good=false
        fi
      done

      if [ "$all_good" = true ]; then
        echo ""
        echo "🎉 All required vault items found!"
      else
        echo ""
        echo "❌ Some items are missing. Please create them in your $vault vault."
      fi
    '')

    # Command to create development environment template
    (writeShellScriptBin "create-env-template" ''
            target="''${1:-$HOME/.config/development/.env.template}"

            echo "Creating environment template at: $target"
            mkdir -p "$(dirname "$target")"

            cat > "$target" << 'EOF'
      # 1Password Environment Template
      # Use with: op inject -i .env.template -o .env

      # GitHub
      GITHUB_TOKEN=op://Personal/GitHub-API/credential
      GITHUB_USERNAME=op://Personal/GitHub-API/username

      # Database
      DATABASE_PASSWORD=op://Personal/Database/password
      DATABASE_URL=postgresql://user:op://Personal/Database/password@localhost:5432/mydb

      # API Keys
      OPENAI_API_KEY=op://Personal/API-Keys/openai
      ANTHROPIC_API_KEY=op://Personal/API-Keys/anthropic

      # Container Registries
      DOCKER_HUB_TOKEN=op://Personal/Container-Registry/docker-hub
      DOCKER_USERNAME=op://Personal/Container-Registry/docker-username
      GHCR_TOKEN=op://Personal/Container-Registry/ghcr
      GITHUB_USERNAME=op://Personal/Container-Registry/github-username

      # Add more secrets using the format:
      # SECRET_NAME=op://VaultName/ItemName/fieldName
      EOF

            chmod 600 "$target"
            echo "Template created. Customize it for your needs."
            echo "Use with: op inject -i $target -o .env"
    '')
  ];

  # Enable 1Password desktop integration
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "hbohlen" ];
  };

  # Configure 1Password SSH agent
  programs.ssh.extraConfig = ''
    # Use 1Password SSH agent
    Host *
        IdentityAgent ~/.1password/agent.sock
  '';

  # Set up environment variables for common patterns
  environment.sessionVariables = {
    # Tell applications where to find 1Password socket
    SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";
  };

  # Create systemd user service to ensure 1Password is running
  systemd.user.services.onepassword-desktop = {
    description = "1Password Desktop Application";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Create activation script to set up user directories
  system.activationScripts.onepassword-user-setup = ''
    # Create user configuration directories
    if [ -d /home/hbohlen ]; then
      mkdir -p /home/hbohlen/.config/development
      mkdir -p /home/hbohlen/.config/1password
      chown -R hbohlen:users /home/hbohlen/.config/development
      chown -R hbohlen:users /home/hbohlen/.config/1password
      chmod 700 /home/hbohlen/.config/development
      chmod 700 /home/hbohlen/.config/1password
    fi
  '';

  # Security: ensure 1Password has necessary permissions
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.policykit.exec") &&
            (action.lookup("program") == "${pkgs._1password-gui}/bin/1password")) {
            if (subject.user == "hbohlen") {
                return polkit.Result.YES;
            }
        }
    });
  '';

  # Add to user's shell initialization
  environment.interactiveShellInit = ''
    # 1Password helper functions
    op-env() {
      if [ -f "$1" ]; then
        op inject -i "$1"
      else
        echo "Template file not found: $1"
        echo "Create one with: create-env-template $1"
      fi
    }

    # Quick access to development environment
    dev-env() {
      local template="$HOME/.config/development/.env.template"
      if [ -f "$template" ]; then
        eval "$(op inject -i "$template")"
        echo "Development environment loaded from 1Password"
      else
        echo "No environment template found. Create one with:"
        echo "  create-env-template $template"
      fi
    }
  '';
}
