{lib, ...}: {
  perSystem = {...}: {
    nix-unit.tests.testNixosUserModuleExists = {
      expr = builtins.pathExists ../../nixos/user.nix;
      expected = true;
    };

    nix-unit.tests.testDeployScriptUsesScriptRelativeRepoRoot = {
      expr = let
        script = builtins.readFile ../../scripts/deploy-hetzner.sh;
      in
        !(lib.hasInfix "git rev-parse --show-toplevel" script)
        && lib.hasInfix ''dirname -- "''${BASH_SOURCE[0]}"'' script;
      expected = true;
    };

    nix-unit.tests.testNixosModuleListIncludesUser = {
      expr = lib.elem ../../nixos/user.nix (import ../../nixos);
      expected = true;
    };

    nix-unit.tests.testLegacyModulesDirectoryRemoved = {
      expr = builtins.pathExists ../../modules;
      expected = false;
    };
  };
}
