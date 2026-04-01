{ lib, ... }:

{
  imports =
    let
      isNixFile = path: lib.hasSuffix ".nix" (toString path);
      moduleFiles = builtins.filter isNixFile (
        builtins.attrNames (builtins.readDir ./.)
      );
      modulePaths = builtins.map (f: ./${f}) (
        builtins.filter (f: f != "default.nix" && f != "base.nix" && f != "user.nix" && f != "ssh.nix" && f != "tailscale.nix" && f != "caddy.nix" && f != "security.nix" && f != "disko.nix" && f != "gno.nix" && f != "opencode.nix" && f != "home-config.nix") moduleFiles
      );
      hostDir = ./hosts;
      hasHosts = builtins.pathExists hostDir;
      hostFiles = if hasHosts then
        let
          entries = builtins.readDir hostDir;
          hostNames = builtins.attrNames entries;
        in
        builtins.map (f: hostDir + "/${f}") hostNames
      else
        [ ];
    in
    [ ./home-config.nix ] ++ modulePaths ++ hostFiles;
}
