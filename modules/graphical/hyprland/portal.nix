{ config, ... }:
let
  xdphScreencopyBufferReuseOverlay = _final: prev: {
    xdg-desktop-portal-hyprland = prev.xdg-desktop-portal-hyprland.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ config.assets.xdphScreencopyBufferReusePatch ];
    });
  };
in
{
  den.aspects.hyprland.nixos =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [ xdphScreencopyBufferReuseOverlay ];

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
