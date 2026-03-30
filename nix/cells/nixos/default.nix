{ inputs, ... }:
{
  # NixOS configurations using disko for declarative disk partitioning
  # This cell is imported by the flake and provides NixOS system configurations

  flake.nixosModules.disko = inputs.disko.nixosModules.disko;
}
