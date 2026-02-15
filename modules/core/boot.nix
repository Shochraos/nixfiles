{ pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [ sbctl ];
  
  # Bootloader
  #boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = 
  {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
  
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
}