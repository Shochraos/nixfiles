{ pkgs, lib, isAzazel, ... }:
{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Disable sleep modes
  systemd.targets = lib.mkIf isAzazel
  {
    "suspend".enable = false;
    "hibernate".enable = false;
    "hybrid-sleep".enable = false;
    "suspend-then-hibernate".enable = false;
  };
}