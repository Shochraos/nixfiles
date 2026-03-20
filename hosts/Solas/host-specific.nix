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
        };
        
        gestures = {
          workspace_swipe = true;
          workspace_swipe_fingers = 3;
          
          # Optional für die "natürliche" Scrollrichtung:
          # workspace_swipe_invert = false;
          };
      };
    };
  };
}
