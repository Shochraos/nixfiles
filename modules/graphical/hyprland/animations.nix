{
  den.aspects.hyprland.provides.to-users.homeManager = {
    wayland.windowManager.hyprland.settings = {
      curve = [
        {
          _args = [
            "standard"
            {
              type = "bezier";
              points = [
                [
                  0.2
                  0
                ]
                [
                  0
                  1
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "emphasizedAccel"
            {
              type = "bezier";
              points = [
                [
                  0.3
                  0
                ]
                [
                  0.8
                  0.15
                ]
              ];
            }
          ];
        }
        {
          _args = [
            "emphasizedDecel"
            {
              type = "bezier";
              points = [
                [
                  0.05
                  0.7
                ]
                [
                  0.1
                  1
                ]
              ];
            }
          ];
        }
      ];

      animation = [
        {
          leaf = "windowsIn";
          enabled = true;
          speed = 5;
          bezier = "emphasizedDecel";
        }
        {
          leaf = "windowsOut";
          enabled = true;
          speed = 3;
          bezier = "emphasizedAccel";
        }
        {
          leaf = "windowsMove";
          enabled = true;
          speed = 6;
          bezier = "standard";
        }
        {
          leaf = "workspaces";
          enabled = true;
          speed = 4;
          bezier = "standard";
          style = "slidevert";
        }
        {
          leaf = "fadeLayers";
          enabled = true;
          speed = 5;
          bezier = "standard";
        }
        {
          leaf = "fade";
          enabled = true;
          speed = 6;
          bezier = "standard";
        }
        {
          leaf = "border";
          enabled = true;
          speed = 6;
          bezier = "standard";
        }
      ];
    };
  };
}
