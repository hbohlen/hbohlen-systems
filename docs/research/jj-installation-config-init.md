# Research: JJ (Jujutsu) Installation, Config, and Repo Init

## Installation Methods

### Pre-built Binaries
- **GitHub Releases**: [Pre-built binaries](https://github.com/jj-vcs/jj/releases/latest) for Windows, Mac, Linux (musl)
- **Cargo Binstall**: `cargo binstall --strategies crate-meta-data jj-cli`

### By Operating System

#### Linux
- **From Source**: Requires Rust >= 1.88, `build-essential`
  ```bash
  cargo install --git https://github.com/jj-vcs/jj.git --locked --bin jj jj-cli  # prerelease
  cargo install --locked --bin jj jj-cli  # latest release
  ```
- **Arch Linux**: `pacman -S jujutsu` (or AUR: `yay -S jujutsu-git`)
- **NixOS**: `nix run 'github:jj-vcs/jj'` (prerelease) or from nixpkgs
- **Homebrew**: `brew install jj`
- **Gentoo**: `emerge -av dev-vcs/jj` (GURU repo)
- **openSUSE**: `zypper install jujutsu`

#### macOS
- **Homebrew**: `brew install jj`
- **MacPorts**: `sudo port install jujutsu`
- **From Source**: Requires Rust >= 1.88, optionally `xcode-select --install`

#### Windows
- **cargo**: Requires Rust >= 1.88
- **winget**: `winget install jj-vcs.jj`
- **scoop**: `scoop install main/jj`

## Initial Configuration

### User Identity
Set your name and email so commits are made in your name:
```bash
jj config set --user user.name "Your Name"
jj config set --user user.email "your.email@example.com"
```

### Commit Signing (Optional)
**GPG:**
```bash
jj config set --user signing.backend "gpg"
jj config set --user signing.behavior "own"
jj config set --user signing.key "YOUR_KEY_FINGERPRINT"
```

**SSH:**
```bash
jj config set --user signing.backend "ssh"
jj config set --user signing.behavior "own"
jj config set --user signing.key "~/.ssh/id_ed25519.pub"
```

### Command-line Completion
```bash
# Bash
source <(jj util completion bash)

# Zsh
autoload -U compinit && compinit
source <(jj util completion zsh)

# Fish
jj util completion fish | source

# Nushell
jj util completion nushell | save -f completions-jj.nu
```

## Repository Initialization

### New Repository
```bash
jj git init                 # Creates .jj/ directory, uses Git as backend
```

### Existing Git Repository (Colocated)
```bash
jj git init --colocate      # Creates .jj/ alongside .git/
```
This creates both `.jj/` and `.git/` directories. Git will show "detached HEAD" - this is normal. Both systems stay synchronized automatically.

### Clone Existing Repository
```bash
jj git clone https://github.com/user/repo
jj git clone git@github.com:user/repo
```

## Key Concepts

### Working Copy as Commit
- In jj, your working copy **is** a commit (`@`)
- No staging area - changes automatically amend `@`
- Every jj command auto-snapshots your working directory

### Change ID vs Commit ID
- **Change ID**: Stable identifier across amendments (e.g., `ppmklykz`)
- **Commit ID**: Changes every time you modify the commit (e.g., `e8ee5ac1`)

### Bookmarks (vs Git Branches)
- Bookmarks automatically follow commits when you rebase
- No "active" bookmark - work with commits directly via change IDs
- Map to Git branches when pushing to remotes

## Colocated Repository Workflow

1. **Initialize in existing Git repo:**
   ```bash
   jj git init --colocate
   ```

2. **Track remote main bookmark:**
   ```bash
   jj bookmark track main@origin
   ```

3. **Daily workflow:**
   ```bash
   jj status          # See changes
   jj log             # View commit graph
   jj new             # Start new commit
   jj describe -m "message"  # Set commit message
   jj commit -m "message"    # Shortcut: describe + new
   jj git push        # Push to remote
   ```

## Sources
- [JJ Installation Docs](https://docs.jj-vcs.dev/latest/install-and-setup/)
- [JJ Tutorial - Complete Guide](https://gist.github.com/christianromney/27fd1fca9e5f24ef24d9ed6c9eddda50)
- [Using JJ in Colocated Repositories](https://cuffaro.com/2025-03-15-using-jujutsu-in-a-colocated-git-repository/)
