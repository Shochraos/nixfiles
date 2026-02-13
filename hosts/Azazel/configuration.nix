{ ... }: 
{
  imports = 
  [  
    ../../modules/core
    ../../modules/nix
    
    ../../modules/gaming
    
    ../../modules/utilities/amdpower.nix
  ];

  networking.hostName = "azazel";
  
  # Globale NixOS Einstellungen
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
}