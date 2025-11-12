{ pkgs, lib, systemName, ... }:
let
  Azazel = lib.mkIf (systemName == "Azazel");
in
{
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Disable sleep modes
  systemd.targets = Azazel
  {
    "suspend".enable = false;
    "hibernate".enable = false;
    "hybrid-sleep".enable = false;
    "suspend-then-hibernate".enable = false;
  };
}