{ pkgs, ... }:
{
  xdg.portal = 
  {
    enable = true;
    extraPortals = with pkgs; 
    [
      xdg-desktop-portal-gtk
    ];
  
    config = 
    {
      hyprland =
      {
        default = [ "hyprland" "gtk" ];
      };
      common = 
      {
        default = [ "gtk" ];
      };
    };
  };
  
  services.gnome.gnome-keyring.enable = true;
}