{lib, ...}: {
  perSystem = {...}: {
    nix-unit.tests.testNixosUserModuleExists = {
      expr = builtins.pathExists ../../nixos/user.nix;
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
