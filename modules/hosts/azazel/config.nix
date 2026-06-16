{
  aspects.nixos.azazel = {
    host.hyprland = {
      input = {
        accel_profile = "flat";
      };
      settings = {
        cursor = {
          no_hardware_cursors = true;
        };
      };
      workspaceRules = [
        {
          workspace = "4";
          persistent = true;
        }
        {
          workspace = "5";
          persistent = true;
        }
      ];
      windowRules = [
        {
          match = {
            class = "^(zen-beta)$";
          };
          workspace = "2 silent";
        }
        {
          match = {
            class = "^(dev.zed.Zed)$";
          };
          workspace = "3 silent";
        }
        {
          match = {
            class = "^(discord)$";
          };
          workspace = "4 silent";
        }
        {
          match = {
            class = "^(Spotify)$";
          };
          workspace = "5 silent";
        }
        {
          match = {
            class = "^(steam)$";
          };
          workspace = "5 silent";
        }
        {
          match = {
            class = "^(steam)$";
            title = "^(Steam Settings)$";
          };
          float = true;
        }
        {
          match = {
            class = "^(endfield.exe)$";
            title = "^(Form)$";
          };
          float = true;
          suppress_event = "maximize fullscreen activatefocus";
          fullscreen_state = "0 0";
          workspace = "3 silent";
        }
        {
          match = {
            class = "^(XTerm)$";
          };
          float = true;
        }
      ];
    };

    host.dms = {
      hyprlandOutputSettings = {
        "desc:LG Electronics LG TV SSCR2 0x01010101" = {
          bitdepth = 10;
          vrrFullscreenOnly = true;
        };
      };
      barConfigs = [
        {
          id = "default";
          name = "Main Bar";
          enabled = true;
          visible = true;

          position = 0;
          bottomGap = 0;
          innerPadding = 5;
          spacing = 0;
          transparency = 0;

          popupGapsAuto = false;
          popupGapsManual = 6;

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
              id = "claudeUsage";
              enabled = true;
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
    };
  };

  aspects.home.azazel =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        feather
        electrum
      ];

      xdg.autostart = {
        entries = [
          "${pkgs.discord.desktopItem}/share/applications/discord.desktop"
          "${pkgs.spotify}/share/applications/spotify.desktop"
        ];
      };
    };
}
