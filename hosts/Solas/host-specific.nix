{ username, ... }:
{ 
  services.fprintd.enable = true;
  services.upower.enable = true;
  services.fwupd.enable = true;
  
  hardware.alsa.enablePersistence = true;
  
  services.xserver.xkb =
  {
    layout = "us";
    variant = "altgr-intl";
  };
  console.keyMap = "us";
  
  home-manager.users.${username} = 
  {   
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
        
        bindl =
        [
          ", switch:on:Lid Switch, exec, dms ipc call lock lock"
          
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ];
        
        binde = 
        [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          
          ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 5 backlight:amdgpu_bl1"
          ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5 backlight:amdgpu_bl1"
      
          ", F6, exec, dms ipc call brightness increment 25 leds:tpacpi::kbd_backlight"
          ", F5, exec, dms ipc call brightness decrement 25 leds:tpacpi::kbd_backlight"
        ];
      };
    };
  };
}
