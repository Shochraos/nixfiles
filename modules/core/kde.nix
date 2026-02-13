{ pkgs, ... }:
{
  services.xserver.enable = false;

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  
  environment.systemPackages = with pkgs;
  [
    kdePackages.kdeconnect-kde
    kdePackages.kwallet-pam
    kdePackages.skanpage
    kdePackages.kcalc
    kdePackages.partitionmanager
    kdePackages.isoimagewriter
  ];

  environment.plasma6.excludePackages = (with pkgs;
  [
    kdePackages.konsole
    kdePackages.elisa
    kdePackages.khelpcenter
  ]);
  
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
}