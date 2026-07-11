{
  aspects.nixos.hyprland =
    { pkgs, ... }:
    {
      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      services.power-profiles-daemon.enable = true;

      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };

      services.gnome.gnome-keyring.enable = true;
      services.gvfs.enable = true;

      environment.systemPackages = with pkgs; [
        nautilus
        gnome-text-editor
        loupe
        evince
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
    };

  aspects.home.hyprland =
    {
      lib,
      config,
      osConfig,
      ...
    }:
    let
      lua = lib.generators.mkLuaInline;
    in
    {
      xdg.configFile."uwsm/env".source =
        "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

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
          config = lib.recursiveUpdate {
            input = lib.recursiveUpdate {
              kb_layout = "us";
              kb_variant = "altgr-intl";
            } osConfig.host.hyprland.input;

            misc = {
              middle_click_paste = false;
              mouse_move_enables_dpms = false;
              key_press_enables_dpms = true;
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
            };

            general = {
              gaps_in = 5;
              gaps_out = 5;
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
              dim_around = 0.66;
              blur = {
                enabled = true;
                size = 3;
                passes = 2;

                ignore_opacity = true;
                new_optimizations = true;
                xray = false;

                noise = 0.02;
                contrast = 1.1;
                vibrancy = 0.2;
                vibrancy_darkness = 0.3;
              };
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
          } osConfig.host.hyprland.settings;

          gesture = osConfig.host.hyprland.gestures;

          workspace_rule = [
            {
              workspace = "1";
              persistent = true;
            }
            {
              workspace = "2";
              persistent = true;
            }
            {
              workspace = "3";
              persistent = true;
            }
          ]
          ++ osConfig.host.hyprland.workspaceRules;
          colors = {
            _var = lua "require('dms.colors')";
          };
          outputs = {
            _var = lua "require('dms.outputs')";
          };
        };
      };
    };
}
