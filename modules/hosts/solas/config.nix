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
      system.stateVersion = "25.05";

      services.upower.enable = true;
      services.fwupd.enable = true;

      systemd.network.wait-online.enable = false;

      hardware.alsa.enablePersistence = true;

      host.wireguard.profiles = {
        home = {
          connection = {
            id = "home";
            type = "wireguard";
            interface-name = "home";
            autoconnect = false;
          };

          "wireguard-peer.MgkkQIkInEWcDGnK3smCD0V1F+O2/WREI+MQuA1mMU8=" = {
            endpoint = "freunds.me:51820";
            allowed-ips = "0.0.0.0/0;";
          };

          ipv4 = {
            method = "manual";
            address1 = "192.168.137.4/32";
            dns = "192.168.1.2;";
            dns-search = "~;";
          };

          ipv6.method = "disabled";
        };

        hs-fulda = {
          presharedKey = true;

          connection = {
            id = "hs-fulda";
            type = "wireguard";
            interface-name = "hs-fulda";
            autoconnect = false;
          };

          wireguard.mtu = 1392;

          "wireguard-peer.E9rVjRfxl5F6amOjc5FBQ7+1minLp60LetMF/y2N3wE=" = {
            endpoint = "eduvpn01.rz.hs-fulda.de:443";
            allowed-ips = "0.0.0.0/0;::/0;";
          };

          ipv4 = {
            method = "manual";
            address1 = "10.248.0.74/19";
            dns = "10.0.0.53;";
            dns-search = "~;";
          };

          ipv6 = {
            method = "manual";
            addr-gen-mode = "default";
            address1 = "2001:638:301:f820::4a/64";
            dns = "2001:638:301::53;";
            dns-search = "~;";
          };
        };
      };

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
        hyprlandOutputSettings = {
          "eDP-1" = {
            bitdepth = 10;
          };
        };
        barConfigs = [
          {
            leftWidgets = [
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
                id = "claudeUsage";
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
            ];
          }
        ];
      };
    };

  aspects.home.solas =
    { pkgs, ... }:
    {
      home.stateVersion = "25.05";

      home.packages = with pkgs; [
        pdfpc
      ];
    };
}
