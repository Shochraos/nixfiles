{
  den.aspects.hyprland.provides.to-users.homeManager =
    { osConfig, ... }:
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
              class = "^(com.nextcloud.desktopclient.nextcloud)$";
            };
            float = true;
          }
          {
            match = {
              class = "^(steam_app_\\d+)$";
            };
            float = true;
          }
        ]
        ++ osConfig.host.hyprland.windowRules;

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
    };
}
