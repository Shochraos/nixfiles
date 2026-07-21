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
        ]
        ++ osConfig.host.hyprland.windowRules;

        layer_rule = [
          {
            match = {
              namespace = "^(dms.*)$";
            };
            ignore_alpha = 0;
            blur = true;
          }
          {
            match = {
              namespace = "^(dms:(bar|app-launcher|control-center|clipboard-popout|battery|vpn|dash|notification-center-popout|process-list-popout|popout|plugins:.*|plugins:plugin|clipboard|file-browser|settings|spotlight|bluetooth-pairing|color-picker|hyprkeybinds|network-info|network-info-wired|notification-center-modal|polkit|power-menu|process-list-modal|wifi-password|confirm-modal|modal))$";
            };
            no_anim = true;
          }
        ];
      };
    };
}
