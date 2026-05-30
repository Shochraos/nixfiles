{
  pkgs,
  username,
  ...
}:
{
  home-manager.users.${username} =
    { config, ... }:
    {
      home.packages = with pkgs; [
        feather
        electrum
      ];

      xdg.autostart = {
        entries = [
          "${pkgs.discord.desktopItem}/share/applications/discord.desktop"
          "${pkgs.spotify}/share/applications/spotify.desktop"
          "${config.programs.zed-editor.package}/share/applications/dev.zed.Zed.desktop"
        ];
      };

      # DankBar
      programs.dank-material-shell = {
        settings = {
          barConfigs = [
            {
              id = "default";
              name = "Main Bar";
              enabled = true;
              visible = true;
              
              position = 0;
              bottomGap = -5;
              innerPadding = 5;
              spacing = 0;
              transparency = 0;

              screenPreferences = [ "all" ];

              borderEnabled = false;
              widgetOutlineEnabled = true;
              widgetOutlineColor = "primary";
              widgetOutlineThickness = 1;
              widgetOutlineOpacity = 0.30;

              leftWidgets = [
                {
                  id = "spacer";
                  enabled = true;
                  size = 5;
                }
                {
                  id = "clock";
                  enabled = true;
                }
                {
                  id = "spacer";
                  enabled = true;
                  size = 15;
                }
                {
                  id = "workspaceSwitcher";
                  enabled = true;
                }
                {
                  id = "runningApps";
                  enabled = true;
                }
              ];

              centerWidgets = [
                {
                  id = "focusedWindow";
                  enabled = true;
                }
              ];

              rightWidgets = [
                {
                  id = "notificationButton";
                  enabled = true;
                }
                {
                  id = "clipboard";
                  enabled = true;
                }
                {
                  id = "dankKDEConnect";
                  enabled = true;
                }
                {
                  id = "spacer";
                  enabled = true;
                  size = 15;
                }
                {
                  id = "cpuUsage";
                  enabled = true;
                  minimumWidth = true;
                }
                {
                  id = "cpuTemp";
                  enabled = true;
                  minimumWidth = true;
                }
                {
                  id = "network_speed_monitor";
                  enabled = true;
                }
                {
                  id = "spacer";
                  enabled = true;
                  size = 15;
                }
                {
                  id = "systemTray";
                  enabled = true;
                }
                {
                  id = "controlCenterButton";
                  enabled = true;
                }
                {
                  id = "spacer";
                  enabled = true;
                  size = 5;
                }
              ];
            }
          ];

          # Power menu
          powerMenuActions = [
            "reboot"
            "poweroff"
          ];
          powerMenuDefaultAction = "poweroff";
        };
      };
    };
}
