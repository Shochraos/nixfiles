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
        "org.freedesktop.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.portal.OpenURI" = [ "gtk" ];
      };
    };
  };
  
  services.gnome.gnome-keyring.enable = true;
}