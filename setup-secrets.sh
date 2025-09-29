#!/usr/bin/env bash
# setup-secrets.sh - Pure 1Password Secret Injection Setup for hbohlen-systems
# This approach uses 1Password's op:// URI injection without storing any secrets locally

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed or not in PATH"
        return 1
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if system has been rebuilt with new configuration
    if ! check_command "op"; then
        log_error "1Password CLI not found"
        log_info "Please rebuild your system first:"
        log_info "  sudo nixos-rebuild switch --flake ."
        exit 1
    fi

    # Check if 1Password GUI is available
    if command -v "1password" &> /dev/null; then
        log_success "1Password GUI found"
    else
        log_warning "1Password GUI not found - please install it manually or rebuild system"
    fi

    # Check if helper commands are available
    if command -v "check-1password" &> /dev/null; then
        log_success "1Password helper commands available"
    else
        log_warning "Helper commands not found - system may need rebuild"
    fi

    log_success "Prerequisites checked"
}

# Guide user through 1Password authentication
setup_authentication() {
    log_info "Setting up 1Password authentication..."

    # Check if already authenticated
    if op account list &>/dev/null; then
        log_success "Already authenticated to 1Password"
        op account list --format=table
        return 0
    fi

    log_info "You need to authenticate to 1Password CLI."
    log_info ""
    log_info "Authentication options:"
    log_info "1. Desktop app integration (recommended)"
    log_info "2. Manual signin with account credentials"
    log_info ""

    read -p "Do you have 1Password desktop app installed and running? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Great! The CLI should automatically use your desktop app authentication."
        log_info "If it doesn't work, you may need to enable CLI integration in 1Password settings:"
        log_info "  1Password → Settings → Developer → Command Line Interface"
    else
        log_info "Please authenticate manually:"
        log_info "  op signin"
        log_info ""
        read -p "Press Enter after you've authenticated..."
    fi

    # Verify authentication
    if op account list &>/dev/null; then
        log_success "1Password authentication successful!"
        op account list --format=table
    else
        log_error "Authentication failed. Please try:"
        log_error "1. Install and start 1Password desktop app"
        log_error "2. Enable CLI integration in 1Password settings"
        log_error "3. Or run: op signin"
        exit 1
    fi
}

# Show required 1Password vault structure
show_vault_structure() {
    log_info "Required 1Password vault structure:"
    echo
    echo "Create these items in your 1Password 'Personal' vault (or your preferred vault):"
    echo
    echo "📝 GitHub-API (API Credential)"
    echo "   ├── credential → Your GitHub personal access token"
    echo "   └── username → Your GitHub username"
    echo
    echo "🗄️ Database (Database)"
    echo "   └── password → Database password"
    echo
    echo "🔑 API-Keys (Secure Note)"
    echo "   ├── openai → OpenAI API key"
    echo "   └── anthropic → Anthropic API key"
    echo
    echo "📦 Container-Registry (Secure Note)"
    echo "   ├── docker-hub → Docker Hub token"
    echo "   ├── docker-username → Docker Hub username"
    echo "   ├── ghcr → GitHub Container Registry token"
    echo "   └── github-username → GitHub username"
    echo
    echo "Note: You can customize vault names and item structure in the configuration files."
}

# Interactively create vault items
create_vault_items() {
    log_info "Would you like help creating the required vault items?"
    read -p "Create items in Personal vault? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping item creation. You can create them manually in 1Password."
        return 0
    fi

    log_info "Creating vault items with placeholder values..."
    log_warning "You'll need to edit these items in 1Password to add your actual secrets"

    # Create GitHub-API item
    log_info "Creating GitHub-API item..."
    if op item create \
        --category="API Credential" \
        --title="GitHub-API" \
        --vault="Personal" \
        credential="ghp_your_github_token_here" \
        username="your-github-username" &>/dev/null; then
        log_success "✓ Created GitHub-API item"
    else
        log_warning "Could not create GitHub-API item (may already exist)"
    fi

    # Create Database item
    log_info "Creating Database item..."
    if op item create \
        --category="Database" \
        --title="Database" \
        --vault="Personal" \
        password="your-database-password-here" &>/dev/null; then
        log_success "✓ Created Database item"
    else
        log_warning "Could not create Database item (may already exist)"
    fi

    # Create API-Keys item
    log_info "Creating API-Keys item..."
    if op item create \
        --category="Secure Note" \
        --title="API-Keys" \
        --vault="Personal" &>/dev/null; then
        # Add custom fields
        op item edit "API-Keys" --vault="Personal" \
            "openai[text]"="sk-your-openai-key-here" \
            "anthropic[text]"="sk-ant-your-anthropic-key-here" &>/dev/null || true
        log_success "✓ Created API-Keys item"
    else
        log_warning "Could not create API-Keys item (may already exist)"
    fi

    # Create Container-Registry item
    log_info "Creating Container-Registry item..."
    if op item create \
        --category="Secure Note" \
        --title="Container-Registry" \
        --vault="Personal" &>/dev/null; then
        # Add custom fields
        op item edit "Container-Registry" --vault="Personal" \
            "docker-hub[text]"="your-docker-hub-token" \
            "docker-username[text]"="your-docker-username" \
            "ghcr[text]"="ghp_your-github-token" \
            "github-username[text]"="your-github-username" &>/dev/null || true
        log_success "✓ Created Container-Registry item"
    else
        log_warning "Could not create Container-Registry item (may already exist)"
    fi

    echo
    log_success "Vault items created with placeholder values!"
    log_warning "⚠️  IMPORTANT: Edit these items in 1Password to add your real secrets"
    log_info "You can use the 1Password app or: op item edit <item-name>"
}

# Test secret injection
test_secret_injection() {
    log_info "Testing 1Password secret injection..."

    # Create a simple test template
    test_template=$(mktemp)
    cat > "$test_template" << 'EOF'
# Test template for 1Password injection
GITHUB_TOKEN=op://Personal/GitHub-API/credential
GITHUB_USERNAME=op://Personal/GitHub-API/username
DATABASE_PASSWORD=op://Personal/Database/password
EOF

    log_info "Testing secret injection with test template..."

    if op inject -i "$test_template" > /dev/null 2>&1; then
        log_success "✓ Secret injection working!"
        log_info "Sample injected values (showing format only):"
        op inject -i "$test_template" | head -3 | sed 's/=.*/=***REDACTED***/'
    else
        log_error "✗ Secret injection failed"
        log_info "This usually means:"
        log_info "1. Required vault items don't exist"
        log_info "2. Field names don't match"
        log_info "3. Vault permissions issue"

        log_info "Run 'validate-vault-structure' for detailed checks"
    fi

    # Clean up
    rm -f "$test_template"
}

# Set up development environment template
setup_dev_environment() {
    log_info "Setting up development environment template..."

    dev_dir="$HOME/.config/development"
    template_file="$dev_dir/.env.template"

    mkdir -p "$dev_dir"

    if [ -f "$template_file" ]; then
        log_warning "Template already exists at $template_file"
        read -p "Overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing template"
            return 0
        fi
    fi

    # Create environment template
    cat > "$template_file" << 'EOF'
# 1Password Development Environment Template
# Use with: op inject -i .env.template -o .env
# Or with: dev-env (shell function)

# GitHub Integration
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
GITHUB_REGISTRY_USERNAME=op://Personal/Container-Registry/github-username

# Add more secrets using the format:
# SECRET_NAME=op://VaultName/ItemName/fieldName
EOF

    chmod 600 "$template_file"
    log_success "Created development environment template at $template_file"

    # Test the template
    if op inject -i "$template_file" > /dev/null 2>&1; then
        log_success "✓ Template validation passed"
    else
        log_warning "⚠ Template validation failed - you may need to create more vault items"
    fi
}

# Set up SSH with 1Password agent
setup_ssh_integration() {
    log_info "Setting up SSH integration with 1Password..."

    read -p "Configure SSH to use 1Password agent? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping SSH setup"
        return 0
    fi

    # Check if 1Password SSH agent is available
    if [ ! -S "$HOME/.1password/agent.sock" ]; then
        log_warning "1Password SSH agent socket not found"
        log_info "To enable SSH agent in 1Password:"
        log_info "1. Open 1Password"
        log_info "2. Go to Settings → Developer"
        log_info "3. Enable 'Use the SSH agent'"
        log_info "4. Add your SSH keys to 1Password"

        read -p "Press Enter after enabling SSH agent..."
    fi

    # Configure SSH
    ssh_config="$HOME/.ssh/config"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # Backup existing config
    if [ -f "$ssh_config" ]; then
        cp "$ssh_config" "$ssh_config.backup.$(date +%s)"
        log_info "Backed up existing SSH config"
    fi

    # Add 1Password agent configuration
    cat >> "$ssh_config" << 'EOF'

# 1Password SSH Agent Integration
Host *
    IdentityAgent ~/.1password/agent.sock

# GitHub with 1Password SSH
Host github.com
    HostName github.com
    User git
    IdentityAgent ~/.1password/agent.sock
EOF

    chmod 600 "$ssh_config"
    log_success "SSH configured to use 1Password agent"

    # Test SSH agent
    if [ -S "$HOME/.1password/agent.sock" ]; then
        log_success "✓ 1Password SSH agent is running"

        # Show available keys
        if SSH_AUTH_SOCK="$HOME/.1password/agent.sock" ssh-add -l &>/dev/null; then
            log_info "Available SSH keys:"
            SSH_AUTH_SOCK="$HOME/.1password/agent.sock" ssh-add -l
        fi
    else
        log_warning "1Password SSH agent not found - make sure it's enabled in 1Password settings"
    fi
}

# Show usage examples
show_usage_examples() {
    log_info "Usage examples for 1Password secret injection:"
    echo
    echo "🔧 Available Commands:"
    echo "  check-1password           - Check authentication and vault status"
    echo "  validate-vault-structure  - Verify all required items exist"
    echo "  dev-with-secrets         - Start shell with development environment"
    echo "  git-with-secrets         - Run git commands with GitHub token"
    echo "  docker-with-secrets      - Run docker with registry authentication"
    echo "  op-run <command>         - Run any command with secret injection"
    echo
    echo "🌟 Shell Functions (available after login):"
    echo "  dev-env                  - Load development environment variables"
    echo "  op-env <template>        - Inject secrets from template file"
    echo
    echo "📋 Direct 1Password CLI Usage:"
    echo "  op inject -i template.env -o .env    # Inject secrets into file"
    echo "  op run -- your-command               # Run command with secrets"
    echo "  op item get GitHub-API --field credential  # Get specific secret"
    echo
    echo "📁 Template Files:"
    echo "  ~/.config/development/.env.template  # Development environment"
    echo "  Create custom templates with op:// URIs"
    echo
    echo "🔍 Examples:"
    echo "  # Load dev environment and run tests"
    echo "  dev-with-secrets"
    echo "  npm test"
    echo
    echo "  # Git operations with automatic token injection"
    echo "  git-with-secrets push origin main"
    echo
    echo "  # Docker login to registries"
    echo "  docker-with-secrets login-docker"
    echo "  docker-with-secrets login-ghcr"
}

# Main setup function
main() {
    log_info "Starting 1Password pure injection secrets management setup"
    log_info "This approach stores NO secrets locally - everything stays in 1Password! 🔐"
    echo

    case "${1:-setup}" in
        "prereq"|"prerequisites")
            check_prerequisites
            ;;
        "auth"|"authenticate")
            setup_authentication
            ;;
        "vault-structure")
            show_vault_structure
            ;;
        "create-items")
            setup_authentication
            create_vault_items
            ;;
        "test-injection")
            test_secret_injection
            ;;
        "setup-dev")
            setup_dev_environment
            ;;
        "setup-ssh")
            setup_ssh_integration
            ;;
        "examples"|"usage")
            show_usage_examples
            ;;
        "all"|"setup")
            log_info "🚀 Running complete setup..."
            echo
            check_prerequisites
            setup_authentication
            show_vault_structure
            create_vault_items
            test_secret_injection
            setup_dev_environment
            setup_ssh_integration

            echo
            log_success "🎉 1Password secret injection setup completed!"
            echo
            log_info "🎯 Next Steps:"
            log_info "1. Edit the created items in 1Password with your real secrets"
            log_info "2. Test with: check-1password"
            log_info "3. Validate with: validate-vault-structure"
            log_info "4. Try development environment: dev-with-secrets"
            log_info "5. Test git integration: git-with-secrets status"
            echo
            show_usage_examples
            ;;
        "help"|"--help"|"-h")
            echo "Usage: $0 [command]"
            echo
            echo "Pure 1Password Secret Injection Setup"
            echo "No secrets stored locally or in git - everything stays in 1Password!"
            echo
            echo "Commands:"
            echo "  setup, all         - Run complete setup (default)"
            echo "  prereq             - Check prerequisites"
            echo "  auth               - Set up 1Password authentication"
            echo "  vault-structure    - Show required vault structure"
            echo "  create-items       - Create example items in 1Password"
            echo "  test-injection     - Test secret injection functionality"
            echo "  setup-dev          - Set up development environment template"
            echo "  setup-ssh          - Configure SSH with 1Password agent"
            echo "  examples, usage    - Show usage examples"
            echo "  help               - Show this help"
            echo
            echo "After setup, use these system commands:"
            echo "  check-1password           - Check 1Password status"
            echo "  validate-vault-structure  - Validate vault items"
            echo "  dev-with-secrets          - Development environment"
            echo "  git-with-secrets          - Git with authentication"
            echo "  docker-with-secrets       - Docker with registries"
            echo "  op-run <command>          - Run with secret injection"
            ;;
        *)
            log_error "Unknown command: $1"
            log_info "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
