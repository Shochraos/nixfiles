{
  den.aspects.hyprland.nixos =
    { pkgs, ... }:
    {
      programs.dux-files.portal.enable = true;

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
            "org.freedesktop.impl.portal.FileChooser" = [ "dfiles" ];
          };
          common = {
            default = [ "gtk" ];
            "org.freedesktop.impl.portal.FileChooser" = [ "dfiles" ];
          };
        };
      };

    };
}
