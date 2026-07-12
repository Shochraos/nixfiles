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
    };
  };
}
