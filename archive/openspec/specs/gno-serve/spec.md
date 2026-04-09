## Requirements

### Requirement: gno-serve systemd service
The `gno-serve` systemd service SHALL run `gno serve` with only the `--port` argument.

#### Scenario: gno-serve starts with valid arguments
- **WHEN** the `gno-serve` service starts
- **THEN** it runs `gno serve --port <port>` without unsupported flags

#### Scenario: tailscale serves gno over tailnet
- **WHEN** both `gno-serve` and `tailscale-serve-gno` services are enabled
- **THEN** tailscale serve forwards traffic from the tailnet hostname to the gno port
