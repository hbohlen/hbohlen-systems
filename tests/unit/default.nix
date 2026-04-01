{ lib, ... }:

{
  imports = lib.attrValues (
    builtins.mapAttrs
      (name: value: ./${name})
      (builtins.removeAttrs (builtins.readDir ./.) [ "default.nix" ])
  );
}
