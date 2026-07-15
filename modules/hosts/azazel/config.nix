{
  den.aspects.azazel.nixos =
    {
      lib,
      ...
    }:
    let
      lua = lib.generators.mkLuaInline;
    in
    {
      system.stateVersion = "25.05";

      host.wireguard.profiles = {
        uni = {
          presharedKey = true;
          extraSecrets = [
            "endpoint"
            "ipv4-address"
            "ipv4-dns"
            "ipv6-address"
            "ipv6-dns"
          ];

          connection = {
            id = "uni";
            type = "wireguard";
            interface-name = "uni";
            autoconnect = false;
          };

          wireguard.mtu = 1392;

          "wireguard-peer.E9rVjRfxl5F6amOjc5FBQ7+1minLp60LetMF/y2N3wE=" = {
            endpoint = "$WG_UNI_ENDPOINT";
            allowed-ips = "0.0.0.0/0;::/0;";
          };

          ipv4 = {
            method = "manual";
            address1 = "$WG_UNI_IPV4_ADDRESS";
            dns = "$WG_UNI_IPV4_DNS";
            dns-search = "~;";
          };

          ipv6 = {
            method = "manual";
            addr-gen-mode = "default";
            address1 = "$WG_UNI_IPV6_ADDRESS";
            dns = "$WG_UNI_IPV6_DNS";
            dns-search = "~;";
          };
        };
      };

      host.hyprland = {
        input = {
          accel_profile = "flat";
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
              class = "^(spotify)$";
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
        keybinds = [
          {
            _args = [
              "mouse:276"
              (lua "hl.dsp.focus({ workspace = 'm-1' })")
            ];
          }
          {
            _args = [
              "mouse:275"
              (lua "hl.dsp.focus({ workspace = 'm+1' })")
            ];
          }
        ];
      };

      host.dms = {
        hyprlandOutputSettings = {
          "HDMI-A-1" = {
            vrrFullscreenOnly = true;
          };
        };
        barConfigs = [
          {
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
                id = "spacer";
                enabled = true;
                size = 15;
              }
              {
                id = "khalCalendar";
                enabled = true;
              }
              {
                id = "tasks";
                enabled = true;
              }
              {
                id = "spacer";
                enabled = true;
                size = 15;
              }
              {
                id = "discordVoice";
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

  den.aspects.azazel.provides.to-users.homeManager =
    { pkgs, ... }:
    {
      home.stateVersion = "25.05";

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
