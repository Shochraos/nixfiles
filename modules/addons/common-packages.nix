{ inputs, username, pkgs, ... }:
{
  home-manager.users.${username} =
  {
    imports = [  inputs.spicetify-nix.homeManagerModules.default ];
    home.packages = with pkgs; 
    [ 
      (discord.override { withVencord = true; }) 
      anki  
    ];
    
    programs.spicetify = 
    {
      enable = true;
    };
    
    wayland.windowManager.hyprland = 
    {     
        settings = 
        {
          bindr = 
          [            
            # Discord
            ", F9, sendshortcut, CTRL SHIFT, M, class:^(discord)$"
            ", F10, sendshortcut, CTRL SHIFT, D, class:^(discord)$"
            
            # Spotify
            ", XF86AudioPrev, exec, playerctl --player=spotify previous"
            ", XF86AudioPlay, exec, playerctl --player=spotify play-pause"
            ", XF86AudioNext, exec, playerctl --player=spotify next"
          ];
          binde = 
          [
            # Spotify
            ", F11, exec, playerctl --player=spotify volume 0.05-"
            ", F12, exec, playerctl --player=spotify volume 0.05+"
          ];
        };
    };
  };
}