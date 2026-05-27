{ username, lib, ... }:
{
  home-manager.users.${username} =
    { config, ... }:
    {
      wayland.windowManager.hyprland.settings = {
        window_rule = [
          {
            _args = [
              {
                match = {
                  class = "^(xdg-desktop-portal-gtk)$";
                };
                float = true;
              }
            ];
          }
          {
            _args = [
              {
                match = {
                  class = "^(org.quickshell)$";
                };
                float = true;
              }
            ];
          }
          {
            _args = [
              {
                match = {
                  class = "^(valent)$";
                };
                float = true;
              }
            ];
          }
          {
            _args = [
              {
                match = {
                  class = "^(Discord)$";
                };
                float = true;
              }
            ];
          }
          {
            _args = [
              {
                match = {
                  class = "^(com.nextcloud.desktopclient.nextcloud)$";
                };
                float = true;
              }
            ];
          }
        ]
        ++ lib.optionals (config.modules.azazel.isLoaded or false) [
          {
            _args = [
              {
                match = {
                  class = "^(zen-beta)$";
                };
                workspace = "2 silent";
              }
            ];
          }
          {
            _args = [
              {
                match = {
                  class = "^(dev.zed.Zed)$";
                };
                workspace = "3 silent";
              }
            ];
          }
          {
            _args = [
              {
                match = {
                  class = "^(discord)$";
                };
                workspace = "4 silent";
              }
            ];
          }
          {
            _args = [
              {
                match = {
                  class = "^(spotify)$";
                };
                workspace = "5 silent";
              }
            ];
          }
          {
            _args = [
              {
                match = {
                  class = "^(steam)$";
                };
                workspace = "5 silent";
              }
            ];
          }
          {
            _args = [
              {
                match = {
                  class = "^(steam)$";
                  title = "^(Steam Settings)$";
                };
                float = true;
              }
            ];
          }
          {
            _args = [
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
            ];
          }
          {
            _args = [
              {
                match = {
                  class = "^(XTerm)$";
                };
                float = true;
              }
            ];
          }
        ]
        ++ lib.optionals (config.modules.solas.isLoaded or false) [
          {
            _args = [
              {
                match = {
                  class = "^(zen-beta)$";
                };
                workspace = "3 silent";
              }
            ];
          }
          {
            _args = [
              {
                match = {
                  class = "^(dev.zed.Zed)$";
                };
                workspace = "2 silent";
              }
            ];
          }
          {
            _args = [
              {
                match = {
                  class = "^(pdfpc)$";
                  fullscreen_state_internal = 0;
                };
                fullscreen = true;
              }
            ];
          }
        ];
      };
    };
}
