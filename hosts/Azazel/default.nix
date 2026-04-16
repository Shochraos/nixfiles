{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix
    ./filesystems.nix

    ./host-specific.nix
  ];
}
