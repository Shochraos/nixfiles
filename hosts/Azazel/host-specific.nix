{ pkgs, username, ... }:
{
  services.xserver.xkb =
  {
    layout = "de";
    variant = "";
  };
  console.keyMap = "de";
  
  home-manager.users.${username} = 
  {
    home.packages = with pkgs; 
    [          
      feather
      electrum
    ];
    
    xdg.autostart = 
    {
      entries = 
      [
        "${pkgs.discord.desktopItem}/share/applications/discord.desktop"
        "${pkgs.spotify}/share/applications/spotify.desktop"
      ];
    };
    
    wayland.windowManager.hyprland = 
    {
        settings = 
        {       
          input = 
          {
            kb_layout = "de"; 
            kb_variant = "nodeadkeys";
             
            accel_profile = "flat";
          };
          
          cursor = 
          {
            no_hardware_cursors = true;
          };
        };
    };
    
    programs.ghostty =
    {
        settings =
        { 
          window-height = 50;
          window-width  = 150;
        };
    };
  };
}