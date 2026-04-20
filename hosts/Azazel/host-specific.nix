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

      wayland.windowManager.hyprland = {
        settings = {
          input = {
            kb_layout = "us";
            kb_variant = "altgr-intl";

            accel_profile = "flat";
          };

          cursor = {
            no_hardware_cursors = true;
          };

          workspace = [
            "1, persistent:true"
            "2, persistent:true"
            "3, persistent:true"
            "4, persistent:true"
            "5, persistent:true"
          ];
          
          windowrule = [
            "match:class ^(zen-beta)$, workspace 2 silent"
            "match:class ^(dev.zed.Zed)$, workspace 3 silent"
            "match:class ^(discord)$, workspace 4 silent"
            "match:class ^(spotify)$, workspace 5 silent"
            "match:class ^(steam)$, workspace 5 silent"
            "match:class ^(steam)$, match:title ^(Steam Settings)$, float on"

            # Arknights Endfield
            "match:class ^(endfield.exe)$, match:title ^(Form)$, float on, suppress_event maximize fullscreen activatefocus, fullscreen_state 0 0, workspace 3 silent"
          ];
        };
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
              widgetOutlineOpacity = 0.35;

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
