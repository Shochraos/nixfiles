{
  aspects.window_rules =
    { config, username, ... }:
    {
      home-manager.users.${username} = {
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
          ++ config.host.hyprland.windowRules;
        };
      };
    };
}
