{ lib, systemName, ... }:
{
  imports =
  [
    ./${lib.toLower systemName}/hardware-configuration.nix
  ];
}