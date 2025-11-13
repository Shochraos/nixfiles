{ lib, systemName, ... }:
{
  imports =
  []
  ++ lib.optionals (systemName == "Azazel")
  [
    ./azazel/hardware-configuration.nix
  ]
   ++ lib.optionals (systemName == "Belphegor")
   [
   ./belphegor/hardware-configuration.nix
   ];
}