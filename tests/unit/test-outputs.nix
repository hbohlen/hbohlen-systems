{ ... }:

{
  perSystem = { config, ... }:
  {
    nix-unit.tests.testDevShellDefaultExists = {
      expr = config.devShells ? default;
      expected = true;
    };
  };
}
