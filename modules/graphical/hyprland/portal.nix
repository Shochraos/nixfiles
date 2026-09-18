{ config, ... }:
let
  # xdph 1.4.1's screencopy buffer-reuse path is broken: the out-of-buffers
  # branch renegotiates the stream, which re-enters PW_STREAM_STATE_STREAMING
  # synchronously and installs a fresh frame callback that the branch then
  # destroys, leaving a live stream that never receives another frame. Both
  # upstream fixes (PR #424, #425) plus the multi-plane dma-buf fix (PR #427)
  # are back-ported here; none is in a release yet.
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
