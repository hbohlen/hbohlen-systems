{inputs, ...}: {
  perSystem = {config, ...}: {
    nix-unit.tests.testDevShellDefaultExists = {
      expr = config.devShells ? default;
      expected = true;
    };

    nix-unit.tests.testHomeConfigurationExists = {
      expr = inputs.self.homeConfigurations ? hbohlen;
      expected = true;
    };
  };
}
