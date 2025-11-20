{ pkgs, ... }:
{
  # Disable X11
  services.xserver.enable = false;

  # KDE Plasma
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  environment.sessionVariables = 
  {
    KWIN_DRM_DEVICES = "/dev/dri/card1";
  };
  
  # Additional KDE packages
  environment.systemPackages = with pkgs;
  [
    kdePackages.kdeconnect-kde
    kdePackages.kwallet-pam
    kdePackages.skanpage
    kdePackages.kcalc
    kdePackages.partitionmanager
    kdePackages.isoimagewriter
  ];

  # Exclude DE packages
  environment.plasma6.excludePackages = (with pkgs;
  [
    kdePackages.konsole
    kdePackages.elisa
    kdePackages.khelpcenter
  ]);
}