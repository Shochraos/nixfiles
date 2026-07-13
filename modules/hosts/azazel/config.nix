{
  aspects.nixos.azazel = {
    system.stateVersion = "25.05";

    host.wireguard.profiles = {
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
          address1 = "10.248.0.59/19";
          dns = "10.0.0.53;";
          dns-search = "~;";
        };

        ipv6 = {
          method = "manual";
          addr-gen-mode = "default";
          address1 = "2001:638:301:f820::3b/64";
          dns = "2001:638:301::53;";
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
    };

    host.dms = {
      hyprlandOutputSettings = {
        "HDMI-A-1" = {
          vrrFullscreenOnly = false;
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

  aspects.home.azazel =
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
