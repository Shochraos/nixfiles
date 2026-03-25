{ pkgs, username, ... }:
{
  environment.plasma6.excludePackages = with pkgs; [ kdePackages.konsole ];
  
  home-manager.users.${username} =
  {
    programs.ghostty =
    {
        enable = true;
        enableFishIntegration = true;
        settings =
        {
          background = "000000";
          background-opacity = 0.2;
          background-blur = true;
          font-family = "OverpassM Nerd Font Mono";
              font-size = 12; 
        };
    };
  };
}