# Pure 1Password Secret Injection for hbohlen-systems

This guide explains how to set up secrets management using **pure 1Password secret injection** with `op://` URIs. No secrets are stored locally or in git - everything stays safely in 1Password.

## Overview

This approach provides:
- **Zero Local Secrets**: No secrets stored on disk or in git
- **1Password Native Integration**: Uses `op://` URI syntax for direct injection
- **Desktop App Integration**: Seamless authentication via 1Password desktop app
- **SSH Agent Support**: SSH keys managed through 1Password agent
- **Development Environment**: Easy environment variable injection
- **Container Registry Auth**: Automatic authentication for Docker/Podman

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ 1Password       │ -> │ op:// Injection  │ -> │ Running         │
│ Vaults          │    │ (CLI + Desktop)  │    │ Applications    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                v
                    ┌──────────────────────┐
                    │ No Local Storage     │
                    │ No Git Secrets       │
                    │ Real-time Injection  │
                    └──────────────────────┘
```

**Key Principles:**
- All secrets remain in 1Password vaults
- Secrets injected at runtime using `op://` URIs
- Desktop app provides seamless authentication
- SSH agent integration for key management
- Template-based environment configuration

## Prerequisites

Ensure your system is built with the updated configuration:

```bash
sudo nixos-rebuild switch --flake .
```

This installs:
- 1Password desktop application with CLI integration
- 1Password CLI (`op`)
- Custom helper commands for secret injection
- SSH agent integration support

## Quick Setup

Run the automated setup script:

```bash
./setup-secrets.sh
```

This will guide you through:
1. Prerequisites check
2. 1Password authentication setup
3. Required vault structure
4. Example vault item creation
5. Development environment templates
6. SSH integration (optional)

## Manual Setup Steps

### 1. Install and Authenticate 1Password

1. **Desktop App**: Install 1Password desktop app if not already done
2. **Enable CLI Integration**: 
   - Open 1Password → Settings → Developer
   - Enable "Use the SSH agent" (optional but recommended)
   - Enable "Integrate with 1Password CLI"
3. **Authenticate**: The CLI should automatically use your desktop app session

```bash
# Test authentication
op account list

# If authentication fails, try manual signin
op signin
```

### 2. Create Required Vault Items

Create these items in your 1Password vault (recommended: "Personal" vault):

#### GitHub-API (API Credential)
- **Title**: `GitHub-API`
- **Category**: API Credential
- **Fields**:
  - `credential` → Your GitHub personal access token
  - `username` → Your GitHub username

#### Database (Database)
- **Title**: `Database`
- **Category**: Database  
- **Fields**:
  - `password` → Database password

#### API-Keys (Secure Note)
- **Title**: `API-Keys`
- **Category**: Secure Note
- **Custom Fields**:
  - `openai` → OpenAI API key
  - `anthropic` → Anthropic API key

#### Container-Registry (Secure Note)
- **Title**: `Container-Registry`
- **Category**: Secure Note
- **Custom Fields**:
  - `docker-hub` → Docker Hub token
  - `docker-username` → Docker Hub username
  - `ghcr` → GitHub Container Registry token
  - `github-username` → GitHub username

### 3. Test Secret Injection

```bash
# Check 1Password authentication and vault access
check-1password

# Validate all required items exist
validate-vault-structure

# Test secret injection (uses helper script)
./setup-secrets.sh test-injection
```

## Using Secret Injection

### Available Commands

After setup, these commands are available system-wide:

```bash
# Check 1Password status and authentication
check-1password

# Validate that all required vault items exist
validate-vault-structure

# Start development shell with secrets injected
dev-with-secrets

# Run git commands with GitHub token injection
git-with-secrets push origin main

# Run docker commands with registry authentication
docker-with-secrets login-docker
docker-with-secrets login-ghcr

# Run any command with secret injection
op-run -- your-command-here
```

### Shell Functions

These functions are available in your shell:

```bash
# Load development environment variables
dev-env

# Inject secrets from a template file
op-env ~/.config/development/.env.template
```

### Direct 1Password CLI Usage

```bash
# Inject secrets into a file
op inject -i template.env -o .env

# Run command with environment injection
op run --env-file=template.env -- your-command

# Get a specific secret
op item get "GitHub-API" --field credential

# Run with inline secret references
op run -- sh -c 'echo "Token: $GITHUB_TOKEN"' --env GITHUB_TOKEN=op://Personal/GitHub-API/credential
```

## Environment Templates

### Development Environment Template

Located at `~/.config/development/.env.template`:

```bash
# 1Password Development Environment Template
# Use with: op inject -i .env.template -o .env

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
```

### Custom Templates

Create your own templates using the `op://VaultName/ItemName/fieldName` syntax:

```bash
# Create custom template
create-env-template ~/.config/myapp/.env.template

# Use the template
op inject -i ~/.config/myapp/.env.template -o ~/.config/myapp/.env
```

## SSH Integration

### 1Password SSH Agent

Enable SSH agent in 1Password desktop app:
1. Go to Settings → Developer
2. Enable "Use the SSH agent"
3. Add your SSH keys to 1Password

### SSH Configuration

The setup automatically configures SSH to use 1Password agent:

```bash
# Set up SSH integration
./setup-secrets.sh setup-ssh

# Or manually configure
setup-ssh-1password
```

Your `~/.ssh/config` will include:

```
# 1Password SSH Agent Integration
Host *
    IdentityAgent ~/.1password/agent.sock

Host github.com
    HostName github.com
    User git
    IdentityAgent ~/.1password/agent.sock
```

## Development Workflows

### Starting Development Session

```bash
# Method 1: Interactive shell with all secrets
dev-with-secrets

# Method 2: Load environment in current shell
dev-env

# Method 3: Run specific command with secrets
op-run -- npm run dev
```

### Git Operations

```bash
# Git operations with automatic token injection
git-with-secrets clone https://github.com/user/repo.git
git-with-secrets push origin main

# Or use regular git with SSH keys from 1Password
git clone git@github.com:user/repo.git
```

### Container Operations

```bash
# Login to Docker Hub
docker-with-secrets login-docker

# Login to GitHub Container Registry  
docker-with-secrets login-ghcr

# Run docker commands with secrets
op-run -- docker build --secret id=github_token,src=<(echo $GITHUB_TOKEN) .
```

### Application Development

```bash
# Node.js development
op run --env-file=~/.config/development/.env.template -- npm start

# Python development
op run --env-file=~/.config/development/.env.template -- python app.py

# Any application that needs environment variables
op-run -- your-application
```

## Configuration

### Adding New Secrets

1. **Create in 1Password**: Add new item or field in your vault
2. **Update Templates**: Add `op://` reference to your template files
3. **Test Injection**: Verify the secret is accessible

Example:
```bash
# Add to template file
echo "NEW_API_KEY=op://Personal/MyService/api-key" >> ~/.config/development/.env.template

# Test injection
op inject -i ~/.config/development/.env.template | grep NEW_API_KEY
```

### Custom Vault Structure

You can customize vault names and structure by editing the NixOS configuration:

```nix
# Edit infrastructure/nixos/secrets/onepassword-secrets.nix
# Update references like op://Personal/... to op://YourVault/...
```

## Security Considerations

### Authentication
- Desktop app integration provides secure, persistent authentication
- CLI automatically uses desktop app session
- No service account tokens stored locally
- Biometric authentication supported via desktop app

### Secret Access
- Secrets never written to disk
- Real-time injection from 1Password
- Audit trail available in 1Password
- Vault-level access controls

### Network Security
- All communication with 1Password over HTTPS
- Local socket communication with desktop app
- No secrets in system logs
- Process isolation for secret access

## Troubleshooting

### Authentication Issues

```bash
# Check 1Password authentication
check-1password

# If authentication fails
op signin

# Check desktop app integration
op account list
```

### Secret Injection Failures

```bash
# Validate vault structure
validate-vault-structure

# Test specific item
op item get "GitHub-API" --field credential

# Check template syntax
op inject -i ~/.config/development/.env.template --dry-run
```

### SSH Agent Issues

```bash
# Check if SSH agent is running
ls -la ~/.1password/agent.sock

# Test SSH agent
SSH_AUTH_SOCK=~/.1password/agent.sock ssh-add -l

# Enable SSH agent in 1Password settings
# Settings → Developer → Use the SSH agent
```

### Desktop App Issues

```bash
# Check if 1Password desktop is running
ps aux | grep "1Password"

# Start 1Password desktop
1password --silent

# Check CLI integration setting
# 1Password → Settings → Developer → Integrate with 1Password CLI
```

## Best Practices

### Template Organization
- Create templates for different environments (dev/staging/prod)
- Use descriptive variable names
- Group related secrets together
- Comment your templates

### Vault Management
- Use descriptive item names
- Organize items with tags
- Regular secret rotation
- Document field purposes in item notes

### Development Workflow
- Always use templates instead of hardcoding `op://` references
- Test secret injection before deployment
- Use environment-specific templates
- Never commit injected `.env` files

### Security
- Enable biometric authentication in 1Password
- Use SSH agent for key management
- Regular vault access audits
- Monitor 1Password activity logs

## Migration from Other Tools

### From SOPS/Age
1. Export current secrets
2. Create corresponding 1Password items
3. Create templates with `op://` references
4. Test injection thoroughly
5. Remove encrypted files from git

### From Environment Files
1. Identify all `.env` files
2. Create 1Password items for each secret
3. Convert to template format
4. Add templates to `.gitignore`
5. Update documentation

## Advanced Usage

### Conditional Secret Injection

```bash
# Different secrets based on environment
if [ "$NODE_ENV" = "production" ]; then
    op inject -i prod.env.template -o .env
else
    op inject -i dev.env.template -o .env
fi
```

### Script Integration

```bash
#!/bin/bash
# deploy.sh - Deployment script with secret injection

set -euo pipefail

# Inject secrets for deployment
op inject -i deploy.env.template -o /tmp/deploy.env
source /tmp/deploy.env

# Run deployment with secrets available
kubectl apply -f deployment.yaml

# Clean up
rm -f /tmp/deploy.env
```

### Service Integration

For systemd services that need secrets:

```bash
# Create service-specific template
op inject -i service.env.template -o /tmp/service.env

# Run service with injected environment
systemd-run --uid=serviceuser --gid=servicegroup \
    --setenv-file=/tmp/service.env \
    /usr/bin/myservice
```

## Support and Maintenance

### Regular Tasks
- Monitor 1Password desktop app updates
- Update CLI when new versions available
- Review and rotate secrets quarterly
- Audit vault access permissions
- Test secret injection after updates

### Monitoring Commands

```bash
# Check system status
check-1password
validate-vault-structure

# Test common operations
op-run -- echo "Testing injection: $GITHUB_TOKEN" | sed 's/ghp_.*/ghp_***/'
```

For issues or questions:
- [1Password CLI Documentation](https://developer.1password.com/docs/cli)
- [1Password Secret Management](https://developer.1password.com/docs/cli/secret-management)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)

---

**Key Advantage**: With this pure injection approach, your entire git repository contains **zero secrets** - everything stays securely in 1Password where it belongs! 🔐✨