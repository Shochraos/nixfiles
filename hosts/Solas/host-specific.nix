{ pkgs, username, ... }:
let
  mic-mute = pkgs.writeShellScript "mic-mute.sh" (builtins.readFile ../../assets/scripts/mic-mute.sh);
in
{
  environment.etc =
  {
    "ssl/certs/T-TeleSec_GlobalRoot_Class_2.pem".source = ../../assets/certs/T-TeleSec_GlobalRoot_Class_2.pem;
  };
  
  systemd.network.wait-online.enable = false;
  
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
    systemd.user.services.micmute-led =
    {
      Unit =
      {
        Description = "Sync mic mute status with keyboard LED";
        PartOf = [ "graphical-session.target" ];
      };
    
      Service =
      {
        Type = "simple";
        ExecStart = "${mic-mute}";
        Restart = "always";
      };
    
      Install =
      {
        WantedBy = [ "graphical-session.target" ];
      };
    };
      
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
          #'', XF86AudioMicMute, exec, sh -c "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; dms brightness get leds:platform::micmute | grep -q ' 0%' && dms brightness set leds:platform::micmute 100 || dms brightness set leds:platform::micmute 0"''        
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
