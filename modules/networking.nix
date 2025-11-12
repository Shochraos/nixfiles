{ config, pkgs, ... }:
{
  # Hostname
  networking.hostName = "Azazel";

  # Networking
  networking.networkmanager.enable = true;

  # Firewall
  networking.firewall =
  {
    enable = true;
    allowedTCPPortRanges =
    [
      { from = 1714; to = 8081; } # KDE Connect
    ];
    allowedUDPPortRanges =
    [
      { from = 1714; to = 1764; } # KDE Connect
    ];
  };

  # Network printing
  services =
  {
    printing.enable = true;
    avahi =
    {
      enable = true;
      nssmdns4 = true;
    };
  };
  hardware.sane =
  {
    enable = true;
    extraBackends = [ pkgs.epkowa ];
  };
}