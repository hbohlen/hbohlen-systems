## ADDED Requirements

### Requirement: Service runs as non-root user

The opencode web UI systemd service MUST run as the `hbohlen` user and `users` group, not as `root`.

#### Scenario: Service process ownership
- **WHEN** the `opencode-web` service is started
- **THEN** the process runs under user `hbohlen` and group `users`

#### Scenario: Git operations use correct identity
- **WHEN** opencode performs git operations (commit, push, etc.)
- **THEN** they execute with the git identity configured for user `hbohlen`

### Requirement: Service working directory and HOME environment are set

The opencode web UI systemd service MUST set `WorkingDirectory` to the user's home directory and MUST set `Environment = ["HOME=<home_dir>"]` so that tools relying on `$HOME` (git, SSH, etc.) function correctly.

#### Scenario: Service starts in home directory
- **WHEN** the `opencode-web` service is started
- **THEN** the working directory is the configured user's home directory

#### Scenario: HOME environment variable is set for child processes
- **WHEN** opencode spawns child processes (git, shell commands, etc.)
- **THEN** `$HOME` resolves to the configured user's home directory

### Requirement: Service retains security hardening

The opencode web UI systemd service MUST retain `PrivateTmp = true` and `NoNewPrivileges = true` when running as a non-root user.

#### Scenario: Security settings preserved
- **WHEN** the service configuration is deployed
- **THEN** `PrivateTmp` is enabled and `NoNewPrivileges` is enabled
