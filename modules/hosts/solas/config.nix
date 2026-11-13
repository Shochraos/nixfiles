{ inputs, ... }:
{
  den.aspects.solas.nixos =
    {
      lib,
      pkgs,
      ...
    }:
    let
      lua = lib.generators.mkLuaInline;
      homePeerPubkey = "FrXFvqXNbU+yOyQt2qJb0iugt0YONNX2GtYX5rPGQ08=";
    in
    {
      system.stateVersion = "25.05";

      host.autostart = [ "hermes" ];
      systemd.services.NetworkManager-wait-online.enable = false;

      services.openssh.enable = true;
      networking.firewall.interfaces = {
        home.allowedTCPPorts = [ 22 ];
        home-split.allowedTCPPorts = [ 22 ];
      };

      users.users.shochraos.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC71dT73gYzQ5zQz0hAeqC6XccOcBmBxGh9Fk2xztTb6 hermes-gateway"
      ];

      host.wireguard.profiles = {
        home = {
          extraSecrets = [ "endpoint" ];

          connection = {
            id = "Home (Full-Tunnel)";
            type = "wireguard";
            interface-name = "home";
            autoconnect = false;
          };

          "wireguard-peer.${homePeerPubkey}" = {
            endpoint = "$WG_HOME_ENDPOINT";
            allowed-ips = "0.0.0.0/0;::/0;";
          };

          wireguard = {
            mtu = 1412;
          };

          ipv4 = {
            method = "manual";
            address1 = "192.168.2.3/32";
            dns-search = "~;";
          };

          ipv6 = {
            method = "manual";
            address1 = "fdba:457d:2cbe:2::3/128";
            dns = "fdba:457d:2cbe:10:7965:bc79:23dc:5f61;fdba:457d:2cbe:10:da59:8116:2311:7e94;";
            dns-search = "~;";
          };
        };

        home-split = {
          excludedSSIDs = [ "Ragnarök" ];

          connection = {
            id = "Home (Split-Tunnel)";
            type = "wireguard";
            interface-name = "home-split";
            autoconnect = true;
          };

          "wireguard-peer.${homePeerPubkey}" = {
            endpoint = "$WG_HOME_ENDPOINT";
            allowed-ips = "192.168.1.0/24;192.168.10.0/24;192.168.20.0/24;192.168.30.0/24;192.168.40.0/24;192.168.50.0/24;192.168.60.0/24;fdba:457d:2cbe:1::/64;fdba:457d:2cbe:10::/64;fdba:457d:2cbe:20::/64;fdba:457d:2cbe:30::/64;fdba:457d:2cbe:40::/64;fdba:457d:2cbe:50::/64;fdba:457d:2cbe:60::/64;";
          };

          wireguard = {
            private-key = "$WG_HOME_KEY";
            mtu = 1412;
          };

          ipv4 = {
            method = "manual";
            address1 = "192.168.2.3/32";
            dns-search = "~;";
          };

          ipv6 = {
            method = "manual";
            address1 = "fdba:457d:2cbe:2::3/128";
            dns = "fdba:457d:2cbe:10:7965:bc79:23dc:5f61;fdba:457d:2cbe:10:da59:8116:2311:7e94;";
            dns-search = "~;";
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
              class = "^(UnrealEditor)$";
              title = "^$";
            };
            suppress_event = "activate activatefocus fullscreen maximize fullscreenoutput";
            no_focus = true;
            workspace = "special:unrealghost silent";
          }
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
        scale = "1.5";
        workspaces = [
          1
          2
          3
          4
        ];
      };

      host.dms = {
        plugins.duxMirror = {
          enable = true;
          src = inputs.dux-mirror.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };
        powerMenuActions = [ "suspend" ];
        barConfigs = [
          {
            leftWidgets = [
              {
                id = "launcherButton";
                enabled = true;
                launcherLogoMode = "os";
                launcherLogoColorOverride = "primary";
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

  den.aspects.solas.provides.to-users.homeManager =
    { pkgs, ... }:
    {
      home.stateVersion = "25.05";
      home.packages = [
        pkgs.eduvpn-client
        pkgs.pdfpc
        pkgs.wl-mirror
      ];
    };
}
