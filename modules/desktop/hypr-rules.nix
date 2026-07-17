{
  den.aspects.hyprland.provides.to-users.homeManager =
    { osConfig, ... }:
    let
      dmsModals = "^(dms:(clipboard|file-browser|settings|spotlight|bluetooth-pairing|color-picker|hyprkeybinds|network-info|network-info-wired|notification-center-modal|polkit|power-menu|process-list-modal|wifi-password|confirm-modal|modal))$";
    in
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
              namespace = dmsModals;
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
              namespace = dmsModals;
            };
            animation = "popin 80%";
          }
        ];
      };
    };
}
