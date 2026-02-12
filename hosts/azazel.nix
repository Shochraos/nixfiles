{ ... }: {
  imports = [
    #./hardware-configuration.nix  # Die generierte Hardware-Config
    ../modules/terminal.nix       # Hier aktivierst du Terminal + ZSH (HM)
    # ../modules/gaming.nix       # Weitere Features einfach hier hinzufügen
  ];

  networking.hostName = "azazel";
  
  # Globale NixOS Einstellungen
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";

  system.stateVersion = "25.05";
}