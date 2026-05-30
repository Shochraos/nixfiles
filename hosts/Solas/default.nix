{ lib, ... }:
{
  options.modules.solas.isLoaded = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix
    ./filesystems.nix

    ./host-specific.nix
  ];

}
