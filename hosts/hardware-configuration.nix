{ lib, systemName, ... }:
{
  imports =
  []
  ++ lib.optionals (systemName == "Azazel")
  [
    ./azazel/hardware-configuration.nix
  ]
   ++ lib.optionals (systemName == "Azazel")
   [
   #./belphegor/hardware-configuration.nix
   ];
}