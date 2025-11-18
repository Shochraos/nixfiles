{ pkgs, lib, systemName, isBelphegor, ... }:
{
  # Hostname
  networking.hostName = "${systemName}";

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

  environment.etc = lib.mkMerge [
    (lib.mkIf isBelphegor {
      "ssl/certs/T-TeleSec_GlobalRoot_Class_2.pem".source = ../assets/certs/T-TeleSec_GlobalRoot_Class_2.pem;
    })
  ];
}