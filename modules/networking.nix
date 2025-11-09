{ config, pkgs, ... }: {

  # Hostname
  networking.hostName = "Azazel";

  # Networking
  networking.networkmanager.enable = true;

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [
      { from = 1714; to = 8081; } # KDE Connect
    ];
    allowedUDPPortRanges = [
      { from = 1714; to = 1764; } # KDE Connect
    ];
  };

  # Network printing
  services.printing.enable = true;

  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  hardware.sane.enable = true;
  hardware.sane.extraBackends = [ pkgs.epkowa ];
}