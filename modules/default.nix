{lib, ...}: {
  imports = let
    isNixFile = path: lib.hasSuffix ".nix" (toString path);
    moduleFiles = builtins.filter isNixFile (
      builtins.attrNames (builtins.readDir ./.)
    );
    modulePaths = builtins.map (f: ./${f}) (
      builtins.filter (f: f != "default.nix" && f != "base.nix" && f != "user.nix" && f != "ssh.nix" && f != "tailscale.nix" && f != "caddy.nix" && f != "security.nix" && f != "disko.nix" && f != "gno.nix" && f != "opencode.nix" && f != "home-config.nix" && f != "home.nix" && f != "tmux.nix" && f != "devshell.nix" && f != "nixos-configurations.nix") moduleFiles
    );
  in
    modulePaths;
}
