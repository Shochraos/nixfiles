{ config, lib, ... }:
let
  inherit (config) helpers;

  display = import helpers.display { inherit lib; };
in
{
  den.aspects.hyprland.provides.to-users.homeManager =
    {
      osConfig,
      pkgs,
      ...
    }:
    let
      streamingScript = display.streamingEnsureScript {
        inherit pkgs;
        streaming = osConfig.host.streaming;
      };
    in
    {
      home.packages = lib.optional (streamingScript != null) streamingScript;

      wayland.windowManager.hyprland = {
        settings = {
          window_rule = [
            {
              match = {
                class = "^(xdg-desktop-portal-gtk)$";
              };
              float = true;
            }
            {
              match = {
                class = "^(org.quickshell)$";
              };
              float = true;
            }
            {
              match = {
                class = "^(valent)$";
              };
              float = true;
            }
            {
              match = {
                class = "^(com.nextcloud.desktopclient.nextcloud)$";
              };
              float = true;
            }
          ]
          ++ osConfig.host.hyprland.windowRules
          ++ display.streamingWindowRules osConfig.host.streaming;

          layer_rule = [
            {
              match = {
                namespace = "^(dms.*)$";
              };
              ignore_alpha = 0;
              blur = true;
              no_anim = true;
            }
          ];
        };

        extraConfig = display.streamingLua streamingScript;
      };
    };
}
