{ pkgs, username,... }:
{
  services.fprintd.enable = true;
  services.upower.enable = true;
  
  services.xserver.xkb =
  {
    layout = "us";
    variant = "altgr-intl";
  };
  console.keyMap = "us";
  
  home-manager.users.${username} = 
  {
    home.packages = with pkgs;
    [
      brightnessctl
    ];
    
    wayland.windowManager.hyprland = 
    {
      settings = 
      {       
        input = 
        {
          kb_layout = "us"; 
          kb_variant = "altgr-intl";
          
          touchpad = 
          {
            natural_scroll = true;
          };
        };
        
        gesture = 
        [
            "3, horizontal, workspace"
        ];
        
        gestures = 
        {
          workspace_swipe_invert = true;
        };
        
        binde = 
        [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          
          ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
          ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ];
        
        bindel = 
        [
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ];
      };
    };
  };
}
