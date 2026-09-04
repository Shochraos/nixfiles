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

      host.flakeDir = "/home/shochraos/Repositories/nix/nixfiles";

      host.hyprland = {
        input = {
          accel_profile = "flat";
        };
        windowRules = [
          {
            match = {
              class = "^(zen-beta)$";
            };
            workspace = "4 silent";
          }
          {
            match = {
              class = "^(dev.zed.Zed)$";
            };
            workspace = "2 silent";
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
              class = "^(steam_app_\\d+)$";
            };
            float = true;
            workspace = "1";
          }
          {
            match = {
              class = "^(steam_app_2483190)$";
              title = "^$";
            };
            suppress_event = "activate activatefocus fullscreen maximize fullscreenoutput";
            no_focus = true;
            workspace = "special:fh6ghost silent";
          }
          {
            match = {
              class = "^(steam_app_2483190)$";
              title = "^(Forza Horizon 6)$";
            };
            fullscreen = true;
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

      host.outputs."HDMI-A-1" = {
        primary = true;
        hdr = true;
        wideColor = true;
        vrrFullscreenOnly = true;
        bitdepth = 10;
        mode = "3840x2160@143.988";
        scale = "1";
        workspaces = [
          1
          2
          3
        ];
      };

      host.outputs."DP-1" = {
        vrrFullscreenOnly = true;
        bitdepth = 10;
        mode = "3440x1440@144.000";
        scale = "1";
        workspaces = [
          4
          5
        ];
      };

      host.audio.equalizers.dx3 = {
        target = {
          "api.alsa.card.name" = "DX3 Pro+";
        };
        preamp = -5.0;
        default = "arya-organic";
        presets = {
          flat.bands = [ ];
          arya-organic.bands = [
            {
              type = "bq_lowshelf";
              freq = 105.0;
              gain = 4.3;
              q = 0.7;
            }
            {
              type = "bq_peaking";
              freq = 89.0;
              gain = -2.6;
              q = 0.82;
            }
            {
              type = "bq_highshelf";
              freq = 10000.0;
              gain = -4.5;
              q = 0.7;
            }
          ];
        };
      };

      host.dms = {
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
                id = "dankTodoman";
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
              {
                id = "gamechatMix";
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
    { config, pkgs, ... }:
    {
      home.stateVersion = "25.05";

      home.packages = with pkgs; [
        feather
        electrum
      ];

      xdg.autostart = {
        entries = [
          "${pkgs.discord.override { withVencord = true; }}/share/applications/discord.desktop"
          "${config.programs.spicetify.spicedSpotify}/share/applications/spotify.desktop"
        ];
      };
    };
}
