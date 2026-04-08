{inputs, ...}: {
  perSystem = {config, ...}: {
    nix-unit.tests.testDevShellDefaultExists = {
      expr = config.devShells ? default;
      expected = true;
    };

    nix-unit.tests.testFlakeNixosConfigurationAssembly = {
      expr = let
        flake = import ../../flake.nix;
        outputs = flake.outputs inputs;
        system = outputs.nixosConfigurations.hbohlen-01;
      in
        outputs ? nixosConfigurations
        && outputs.nixosConfigurations ? hbohlen-01
        && system.config.networking.hostName == "hbohlen-01"
        && system.config.system.build.toplevel.drvPath != "";
      expected = true;
    };
  };
}
