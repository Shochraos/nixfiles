{ pkgs, username, ... }:
{
  services.upower.enable = true;
  services.fwupd.enable = true;

  systemd.network.wait-online.enable = false;

  hardware.alsa.enablePersistence = true;

  home-manager.users.${username} =
  { config, ... }:
  {
    home.packages = with pkgs;
    [
      pdfpc
    ];
    
    xdg.autostart = {
      entries = [
        "${config.programs.zed-editor.package}/share/applications/dev.zed.Zed.desktop"
      ];
    };
    wayland.windowManager.hyprland = {
      settings = {
        input = {
          kb_layout = "us";
          kb_variant = "altgr-intl";

          touchpad = {
            natural_scroll = true;
          };
        };

        workspace = [
          "1, persistent:true"
          "2, persistent:true"
          "3, persistent:true"
        ];

        windowrule = [
          "match:class ^(zen-beta)$, workspace 3 silent"
          "match:class ^(dev.zed.Zed)$, workspace 2 silent"
          "match:class ^(pdfpc)$, match:fullscreen_state_internal 0, fullscreen on"
        ];

        gesture = [
          "3, horizontal, workspace"
        ];

        gestures = {
          workspace_swipe_invert = true;
        };

        bindl = [
          ", switch:on:Lid Switch, exec, dms ipc call lock lock"

          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ];

        binde = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"

          ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 5 backlight:amdgpu_bl1"
          ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5 backlight:amdgpu_bl1"

          ", F6, exec, dms ipc call brightness increment 25 leds:tpacpi::kbd_backlight"
          ", F5, exec, dms ipc call brightness decrement 25 leds:tpacpi::kbd_backlight"
        ];
      };
    };

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
            spacing = 2;
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
              {
                id = "spacer";
                enabled = true;
                size = 15;
              }
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
            ];

            centerWidgets = [
              {
                id = "focusedWindow";
                enabled = true;
              }
            ];

            rightWidgets = [
              {
                id = "battery";
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
                id = "vpn";
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
                id = "simpleAudioControl";
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
          "suspend"
          "reboot"
          "poweroff"
        ];
        powerMenuDefaultAction = "poweroff";
      };
    };
  };
}
