## 1. Add user option to services.opencode

- [x] 1.1 Add `user` option to `services.opencode` with default `"hbohlen"`, matching the pattern in `gno.nix`

## 2. Update serviceConfig to use user option

- [x] 2.1 Add `User = opencodeCfg.user` to serviceConfig
- [x] 2.2 Add `WorkingDirectory` derived from user's home directory
- [x] 2.3 Add `Environment = ["HOME=<home_dir>"]` to serviceConfig

## 3. Verify and deploy

- [x] 3.1 Rebuild the system to apply the new service configuration
- [x] 3.2 Verify the service is running as user `hbohlen` (check `ps aux` or `systemctl status`)
- [x] 3.3 Verify the service is accessible via Tailscale on port 8081
