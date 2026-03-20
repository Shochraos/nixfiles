{ username,... }:
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
      };
    };
  };
}
