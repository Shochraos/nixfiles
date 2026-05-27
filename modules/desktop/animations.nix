{ username, ... }:
{
  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings = {
      curve = [
        {
          _args = [
            "curveWindow"
            {
              type = "bezier";
              points = [
                [
                  0.61
                  1
                ]
                [
                  0.88
                  1
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "curveWorkspace"
            {
              type = "bezier";
              points = [
                [
                  0.25
                  1
                ]
                [
                  0.5
                  1
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "curveMenu"
            {
              type = "bezier";
              points = [
                [
                  0.05
                  0.9
                ]
                [
                  0.1
                  1.05
                ]
              ];
            }
          ];
        }
      ];

      animation = [
        {
          _args = [
            {
              leaf = "windows";
              enabled = true;
              speed = 2.5;
              bezier = "curveWindow";
              style = "slide";
            }
          ];
        }
        {
          _args = [
            {
              leaf = "workspaces";
              enabled = true;
              speed = 2.5;
              bezier = "curveWorkspace";
              style = "slidevert";
            }
          ];
        }
        {
          _args = [
            {
              leaf = "layers";
              enabled = true;
              speed = 2.5;
              bezier = "curveMenu";
              style = "popin 80%";
            }
          ];
        }
        {
          _args = [
            {
              leaf = "fadeLayers";
              enabled = false;
            }
          ];
        }
      ];

      layer_rule = [
        {
          _args = [
            {
              match = {
                namespace = "^(dms.*)$";
              };
              blur = true;
            }
          ];
        }
        {
          _args = [
            {
              match = {
                namespace = "^(dms.*)$";
              };
              ignore_alpha = 0;
            }
          ];
        }
        {
          _args = [
            {
              match = {
                namespace = "^(dms:(clipboard|file-browser|settings|spotlight|bluetooth-pairing|color-picker|hyprkeybinds|network-info|network-info-wired|notification-center-modal|polkit|power-menu|process-list-modal|wifi-password|confirm-modal|modal))$";
              };
              dim_around = 1;
            }
          ];
        }
        {
          _args = [
            {
              match = {
                namespace = "^(dms:bar)$";
              };
              no_anim = true;
            }
          ];
        }
        {
          _args = [
            {
              match = {
                namespace = "^(dms:(app-launcher|control-center|clipboard-popout|battery|vpn|dash|notification-center-popout|process-list-popout|popout|plugins:.*|plugins:plugin))$";
              };
              animation = "slide top";
            }
          ];
        }
        {
          _args = [
            {
              match = {
                namespace = "^(dms:(clipboard|file-browser|settings|spotlight|bluetooth-pairing|color-picker|hyprkeybinds|network-info|network-info-wired|notification-center-modal|polkit|power-menu|process-list-modal|wifi-password|confirm-modal|modal))$";
              };
              animation = "popin 80%";
            }
          ];
        }
      ];

    };
  };
}
