{ lib, systemName, ... }:
{
  imports =
  [
    # Import the hardware configuration based on systemName
    ./${lib.toLower systemName}/hardware-configuration.nix
  ];
}