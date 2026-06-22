{
  aspects.nixos.hyprland =
    { pkgs, ... }:
    {
      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
        ];

        config = {
          hyprland = {
            default = [
              "hyprland"
              "gtk"
            ];
          };
          common = {
            default = [ "gtk" ];
          };
        };
      };

      systemd.user.services.xdg-desktop-portal = {
        after = [ "graphical-session.target" ];
        requires = [ "graphical-session.target" ];
      };

      systemd.user.services.xdg-desktop-portal-hyprland = {
        after = [ "graphical-session.target" ];
        requires = [ "graphical-session.target" ];
      };

      systemd.user.services.xdg-desktop-portal-gtk = {
        after = [ "graphical-session.target" ];
        requires = [ "graphical-session.target" ];
      };
    };
}
