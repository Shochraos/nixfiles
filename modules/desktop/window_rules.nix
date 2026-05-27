{ username, lib, ... }:
{
  home-manager.users.${username} =
    { config, ... }:
    {
      wayland.windowManager.hyprland.settings = {
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
              class = "^(Discord)$";
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
        ++ lib.optionals (config.modules.azazel.isLoaded or false) [
          {
            match = {
              class = "^(zen-beta)$";
            };
            workspace = "2 silent";
          }
          {
            match = {
              class = "^(dev.zed.Zed)$";
            };
            workspace = "3 silent";
          }
          {
            match = {
              class = "^(discord)$";
            };
            workspace = "4 silent";
          }
          {
            match = {
              class = "^(spotify)$";
            };
            workspace = "5 silent";
          }
          {
            match = {
              class = "^(steam)$";
            };
            workspace = "5 silent";
          }
          {
            match = {
              class = "^(steam)$";
              title = "^(Steam Settings)$";
            };
            float = true;
          }
          {
            match = {
              class = "^(endfield.exe)$";
              title = "^(Form)$";
            };
            float = true;
            suppress_event = "maximize fullscreen activatefocus";
            fullscreen_state = "0 0";
            workspace = "3 silent";
          }
          {
            match = {
              class = "^(XTerm)$";
            };
            float = true;
          }
        ]
        ++ lib.optionals (config.modules.solas.isLoaded or false) [
          {
            match = {
              class = "^(zen-beta)$";
            };
            workspace = "3 silent";
          }
          {
            match = {
              class = "^(dev.zed.Zed)$";
            };
            workspace = "2 silent";
          }
          {
            match = {
              class = "^(pdfpc)$";
              fullscreen_state_internal = 0;
            };
            fullscreen = true;
          }
        ];
      };
    };
}