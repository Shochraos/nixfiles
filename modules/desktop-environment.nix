{ config, pkgs, ... }: {

  # Disable X11
  services.xserver.enable = false;

  # KDE Plasma
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Additional KDE packages
  environment.systemPackages = with pkgs;
  [
  kdePackages.kdeconnect-kde
  kdePackages.kwallet-pam
  kdePackages.skanpage
  ];

  # Exclude DE packages
  environment.plasma6.excludePackages = (with pkgs; [
  kdePackages.konsole
  kdePackages.elisa
  kdePackages.khelpcenter
]);
}