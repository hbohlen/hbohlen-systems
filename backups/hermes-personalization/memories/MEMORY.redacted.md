hbohlen-systems project: Nix-based personal infrastructure using dendritic pattern with flake-parts. First branch is devShell with fish, starship, zoxide, pi, and ADHD-friendly tooling. User is building this to establish reproducible environments before adding home-manager, system config, pi customizations, and Hermes skills.
§
Effective approach with ADHD/perfectionism: Break design into tiny, completable experiments. Use explicit approval gates (present design, get approval, then implement). Avoid combining multiple decisions in one question. Validate scope before diving into details. The dendritic pattern aligns well with need for organic growth without big upfront design.
§
ADHD-friendly terminal configuration established with user: Fish shell with starship (minimal git-focused prompt), zoxide for fuzzy directory jumping, eza for better ls, direnv for auto environment loading. Uses abbreviations instead of aliases so full commands are visible. Prefers small, concrete steps over big planning sessions.
§
hbohlen-systems project structure: Uses flake-parts with dendritic cells pattern at nix/cells/<cell-name>/. DevShell is at nix/cells/devshells/default.nix. Flake inputs: nixpkgs (nixos-unstable), flake-parts, llm-agents. Cross-platform: x86_64-linux, aarch64-linux, aarch64-darwin.
§
Critical Nix devShell fix: shellHook must check for interactive terminal with `[[ -t 0 ]]` before exec-ing to fish. Without this, `nix develop --command` fails because fish replaces the shell process unconditionally. Pattern: `if [[ -z "$FISH_VERSION" && -t 0 ]]; then exec fish; fi`
§
Hetzner x86 deploy fix: use dual-mode GRUB on /dev/sda plus EFI removable install, with a GPT BIOS boot partition EF02. deploy-hetzner.sh should use absolute flake paths and --no-use-machine-substituters for hardware generation.
§
DigitalOcean VPS (Ubuntu 24.04, SFO3): Public IP 165.232.141.135, Tailscale IP 100.85.70.39. Hardened with SSH (key-only, no root), UFW (port 22 only), fail2ban (3 strikes). Tailscale runs userspace mode at ~/.local/var/run/tailscale/. Root password: REDACTED
§
Git commit identity on the droplet: name `hbohlen`, email `hbohlen.io@gmail.com`.