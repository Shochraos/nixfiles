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

      programs.hyprland.portalPackage = pkgs.xdg-desktop-portal-hyprland;

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
