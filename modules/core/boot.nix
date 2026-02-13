{ pkgs, lib, ... }:
{
  # Bootloader
  #boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = 
  {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  services.scx = {
      enable = true;
      scheduler = "scx_lavd";
      extraArgs = [ "--performance" ];
  };
  
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  swapDevices =
  [{
    device = "/var/lib/swapfile";
    size = 16*1024;
  }];
  
  # Research
  virtualisation.vswitch.enable = true;
}