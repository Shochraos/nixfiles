{
  pkgs,
  username,
  lib,
  ...
}:
{
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services.power-profiles-daemon.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs; [
    nautilus
    gnome-text-editor
    loupe
    evince
    playerctl
    libsecret
  ];

  xdg.mime = {
    enable = true;

    defaultApplications = {
      "text/html" = "zen-beta.desktop";
      "x-scheme-handler/http" = "zen-beta.desktop";
      "x-scheme-handler/https" = "zen-beta.desktop";
      "x-scheme-handler/about" = "zen-beta.desktop";
      "x-scheme-handler/unknown" = "zen-beta.desktop";

      "application/pdf" = [
        "org.gnome.Evince.desktop"
        "zen-beta.desktop"
      ];

      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/png" = "org.gnome.Loupe.desktop";
      "video/mp4" = "mpv.desktop";
      "video/mkv" = "mpv.desktop";
      "text/plain" = "org.gnome.TextEditor.desktop";
    };
  };

  home-manager.users.${username} = 
  { config, ...}:
  {
    xdg.configFile."uwsm/env".source = "${
      config.home.sessionVariablesPackage
    }/etc/profile.d/hm-session-vars.sh";

    home.sessionVariables = {
      QT_QPA_PLATFORM = "wayland;xcb";
      GDK_BACKEND = "wayland,x11,*";
      SDL_VIDEODRIVER = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";

      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";
    };

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      systemd.enable = false;

      package = null;
      portalPackage = null;

      settings = {
        config = {
          input = {
            kb_layout = "us";
            kb_variant = "altgr-intl";
          }
          // lib.optionalAttrs (config.modules.solas.isLoaded or false) {
            touchpad = {
              natural_scroll = true;
            };
          }
          // lib.optionalAttrs (config.modules.azazel.isLoaded or false) {
            accel_profile = "flat";
          };

          misc = {
            middle_click_paste = false;
            mouse_move_enables_dpms = false;
            key_press_enables_dpms = true;
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
          };

          general = {
            gaps_in = 5;
            gaps_out = 10;
            border_size = 1;
            col = {
              inactive_border = "rgba(00000000)";
            };
            layout = "dwindle";
          };

          decoration = {
            rounding = 12;
            active_opacity = 1.0;
            inactive_opacity = 1.0;
            shadow = {
              enabled = true;
              range = 30;
              render_power = 5;
              offset = "0 5";
            };
          };

          dwindle = {
            force_split = 2;
            preserve_split = true;
          };
        }
        // lib.optionalAttrs (config.modules.solas.isLoaded or false) {
          gestures = {
            workspace_swipe_invert = true;
          };
        }
        // lib.optionalAttrs (config.modules.azazel.isLoaded or false) {
          cursor = {
            no_hardware_cursors = true;
          };
        };

        gesture =
          [ ]
          ++ lib.optionals (config.modules.solas.isLoaded or false) [
            {
              fingers = 3;
              direction = "horizontal";
              action = "workspace";
            }
          ];

        workspace = [
          {
            _args = [
              1
              { persistent = true; }
            ];
          }
          {
            _args = [
              2
              { persistent = true; }
            ];
          }
          {
            _args = [
              3
              { persistent = true; }
            ];
          }
        ]
        ++ lib.optionals (config.modules.azazel.isLoaded or false) [
          {
            _args = [
              4
              { persistent = true; }
            ];
          }
          {
            _args = [
              5
              { persistent = true; }
            ];
          }
        ];

        source = [
          "${config.home.homeDirectory}/.config/hypr/dms/colors.lua"
          "${config.home.homeDirectory}/.config/hypr/dms/layout.lua"
          "${config.home.homeDirectory}/.config/hypr/dms/outputs.lua"
          "${config.home.homeDirectory}/.config/hypr/dms/cursor.lua"
        ];
      };
    };
  };
}