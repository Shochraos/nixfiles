{
  den.aspects.solas.nixos =
    {
      lib,
      ...
    }:
    let
      lua = lib.generators.mkLuaInline;
    in
    {
      system.stateVersion = "25.05";

      host.autostart = [ "hermes" ];

      host.flakeDir = "/home/shochraos/Repositories/nix/nixfiles";
      host.keepassxc.database = "/mnt/nextcloud/Security/KeePass/Vault.kdbx";

      host.wireguard.profiles = {
        home = {
          extraSecrets = [ "endpoint" ];

          connection = {
            id = "home";
            type = "wireguard";
            interface-name = "home";
            autoconnect = false;
          };

          "wireguard-peer.cPsDOh8aiCez/Up7DOAv0yUHDAMHlVKwbwOGMGHmIUU=" = {
            endpoint = "$WG_HOME_ENDPOINT";
            allowed-ips = "0.0.0.0/0;";
          };

          wireguard.mtu = 1412;

          ipv4 = {
            method = "manual";
            address1 = "192.168.137.3/32";
            dns = "192.168.10.254;";
            dns-search = "~;";
          };

          ipv6 = {
            method = "disabled";
          };
        };
      };

      host.wifi.profiles = {
        ragnarok = {
          connection = {
            id = "Ragnarök";
            autoconnect-priority = 100;
          };

          wifi.ssid = "Ragnarök";

          wifi-security = {
            key-mgmt = "sae";
            pmf = 3;
          };
        };

        eduroam = {
          eap = true;
          extraSecrets = [
            "identity"
            "anonymous-identity"
            "domain"
          ];

          connection.autoconnect-priority = 100;

          "802-1x" = {
            eap = "peap;";
            identity = "$WIFI_EDUROAM_IDENTITY";
            anonymous-identity = "$WIFI_EDUROAM_ANONYMOUS_IDENTITY";
            ca-cert = "/etc/eduroam-certs/hs-fulda-eduroam-ca.pem";
            domain-suffix-match = "$WIFI_EDUROAM_DOMAIN";
            phase2-auth = "mschapv2";
            system-ca-certs = false;
          };
        };
      };

      host.hyprland = {
        input = {
          touchpad = {
            natural_scroll = true;
          };
        };
        screenshotKeycode = 107;
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
              class = "^(hermes)$";
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
              class = "^(zen-beta)$";
            };
            workspace = "4 silent";
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

      host.outputs."eDP-1" = {
        bitdepth = 10;
        workspaces = [
          1
          2
          3
          4
        ];
      };

      host.dms = {
        powerMenuActions = [ "suspend" ];
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
                id = "spacer";
                enabled = true;
                size = 15;
              }
              {
                id = "khalCalendar";
                enabled = true;
              }
              {
                id = "dankTodoman";
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
                id = "battery";
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
                id = "systemTray";
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

  den.aspects.solas.provides.to-users.homeManager = _: {
    home.stateVersion = "25.05";
  };
}
