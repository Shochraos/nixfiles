{
  aspects.home.hyprland = {
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
          leaf = "windows";
          enabled = true;
          speed = 2.5;
          bezier = "curveWindow";
          style = "slide";
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = 2.5;
          bezier = "curveWorkspace";
          style = "slidevert";
        }
        {
          leaf = "layers";
          enabled = true;
          speed = 2.5;
          bezier = "curveMenu";
          style = "popin 80%";
        }
      ];

      layer_rule = [
        {
          match = {
            namespace = "^(dms.*)$";
          };
          ignore_alpha = 0.0;
          blur = true;
        }
        {
          match = {
            namespace = "^(dms:(clipboard|file-browser|settings|spotlight|bluetooth-pairing|color-picker|hyprkeybinds|network-info|network-info-wired|notification-center-modal|polkit|power-menu|process-list-modal|wifi-password|confirm-modal|modal))$";
          };
          dim_around = 1;
        }
        {
          match = {
            namespace = "^(dms:bar)$";
          };
          no_anim = true;
        }
        {
          match = {
            namespace = "^(dms:(app-launcher|control-center|clipboard-popout|battery|vpn|dash|notification-center-popout|process-list-popout|popout|plugins:.*|plugins:plugin))$";
          };
          animation = "slide top";
        }
        {
          match = {
            namespace = "^(dms:(clipboard|file-browser|settings|spotlight|bluetooth-pairing|color-picker|hyprkeybinds|network-info|network-info-wired|notification-center-modal|polkit|power-menu|process-list-modal|wifi-password|confirm-modal|modal))$";
          };
          animation = "popin 80%";
        }
      ];
    };
  };
}
