{
  aspects.nixos.solas =
    {
      lib,
      ...
    }:
    let
      lua = lib.generators.mkLuaInline;
    in
    {
      services.upower.enable = true;
      services.fwupd.enable = true;

      systemd.network.wait-online.enable = false;

      hardware.alsa.enablePersistence = true;

      host.hyprland = {
        input = {
          touchpad = {
            natural_scroll = true;
          };
        };
        settings = {
          gestures = {
            workspace_swipe_invert = true;
          };
        };
        gestures = [
          {
            fingers = 3;
            direction = "horizontal";
            action = "workspace";
          }
        ];
        windowRules = [
          {
            match = {
              class = "^(zen-beta)$";
            };
            workspace = "3 silent";
          }
          {
            match = {
              class = "^(dev.zed.Zed)$";
            };
            workspace = "2 silent";
          }
          {
            match = {
              class = "^(pdfpc)$";
              fullscreen_state_internal = 0;
            };
            fullscreen = true;
          }
        ];
        keybinds = [
          {
            _args = [
              "switch:on:Lid Switch"
              (lua "hl.dsp.exec_cmd('dms ipc call lock lock')")
              { locked = true; }
            ];
          }
          {
            _args = [
              "XF86AudioMute"
              (lua "hl.dsp.exec_cmd('wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle')")
              { locked = true; }
            ];
          }
          {
            _args = [
              "XF86AudioMicMute"
              (lua "hl.dsp.exec_cmd('wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle')")
              { locked = true; }
            ];
          }

          {
            _args = [
              "XF86AudioRaiseVolume"
              (lua "hl.dsp.exec_cmd('wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+')")
              { repeating = true; }
            ];
          }
          {
            _args = [
              "XF86AudioLowerVolume"
              (lua "hl.dsp.exec_cmd('wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-')")
              { repeating = true; }
            ];
          }
          {
            _args = [
              "XF86MonBrightnessUp"
              (lua "hl.dsp.exec_cmd('dms ipc call brightness increment 5 backlight:amdgpu_bl1')")
              { repeating = true; }
            ];
          }
          {
            _args = [
              "XF86MonBrightnessDown"
              (lua "hl.dsp.exec_cmd('dms ipc call brightness decrement 5 backlight:amdgpu_bl1')")
              { repeating = true; }
            ];
          }
          {
            _args = [
              "F6"
              (lua "hl.dsp.exec_cmd('dms ipc call brightness increment 25 leds:tpacpi::kbd_backlight')")
              { repeating = true; }
            ];
          }
          {
            _args = [
              "F5"
              (lua "hl.dsp.exec_cmd('dms ipc call brightness decrement 25 leds:tpacpi::kbd_backlight')")
              { repeating = true; }
            ];
          }
        ];
      };

      host.dms = {
        powerMenuActions = [ "suspend" ];
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
              {
                id = "spacer";
                enabled = true;
                size = 15;
              }
              {
                id = "battery";
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
      };
    };

  aspects.home.solas =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        pdfpc
      ];
    };
}
