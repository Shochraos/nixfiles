{
  config,
  pkgs,
  username,
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
    # Gnome utils
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

  home-manager.users.${username} = {
    xdg.configFile."uwsm/env".source = "${
      config.home-manager.users.${username}.home.sessionVariablesPackage
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
      systemd.enable = false;

      package = null;
      portalPackage = null;

      settings = {
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
          "col.inactive_border" = "rgba(00000000)";

          layout = "dwindle";
        };

        decoration = {
          rounding = 12;

          active_opacity = 1.0;
          inactive_opacity = 1.0;

          blur = {
              enabled = true;
              size = 2;
              passes = 4;

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
            render_power = 3;
            offset = "0 5";
          };
        };

        exec-once = [ ];

        layerrule = [
          #Blur
          "blur on, match:namespace ^(dms.*)$"
          "ignore_alpha 0, match:namespace ^(dms.*)$"

          #Animations
          "no_anim on, match:namespace ^(dms:bar)$"
          "animation slide top, match:namespace ^(dms:(app-launcher|control-center|clipboard-popout|battery|vpn|dash|notification-center-popout|process-list-popout|popout|plugins:.*|plugins:plugin))$"
          "animation popin 80%, match:namespace ^(dms:(clipboard|file-browser|settings|spotlight|bluetooth-pairing|color-picker|hyprkeybinds|network-info|network-info-wired|notification-center-modal|polkit|power-menu|process-list-modal|wifi-password|confirm-modal|modal))$"
        ];

        windowrule = [
          # System ui
          "match:class ^(xdg-desktop-portal-gtk)$, float on"
          "match:class ^(org.quickshell)$, float on"
          "match:class ^(valent)$, float on"

          "match:class ^(Discord)$, float on"
          "match:class ^(com.nextcloud.desktopclient.nextcloud)$, float on"
        ];

        dwindle = {
          force_split = 2;
          preserve_split = true;
        };

        bezier = [
          "curveWindow, 0.61, 1, 0.88, 1"
          "curveWorkspace, 0.25, 1, 0.5, 1"
          "curveMenu, 0.05, 0.9, 0.1, 1.05"
        ];

        animation = [
          "windows, 1, 2.5, curveWindow, slide"
          "workspaces, 1, 2.5, curveWorkspace, slidevert"
          "layers, 1, 2.5, curveMenu, popin 80%"
        ];

        source = [
          "~/.config/hypr/dms/colors.conf"
          "~/.config/hypr/dms/layout.conf"
          "~/.config/hypr/dms/outputs.conf"
          "~/.config/hypr/dms/cursor.conf"
        ];

        "$mod" = "SUPER";
        bind = [
          "$mod, Return, exec, ghostty"
          "$mod, F, exec, nautilus"
          "$mod, T, exec, gnome-text-editor"
          "$mod, Q, killactive"
          "$mod CTRL, F, fullscreen, 0"
          "$mod ALT, F, togglefloating"

          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"

          "$mod SHIFT, left, movewindow, l"
          "$mod SHIFT, right, movewindow, r"
          "$mod SHIFT, up, movewindow, u"
          "$mod SHIFT, down, movewindow, d"

          "$mod CTRL, left, workspace, m-1"
          "$mod CTRL, right, workspace, m+1"

          "$mod CTRL SHIFT, left, movetoworkspace, -1"
          "$mod CTRL SHIFT, right, movetoworkspace, +1"

          # DMS binds
          "$mod, L, exec, dms ipc call lock lock"

          ", PRINT, exec, dms screenshot --no-file"
          "$mod, PRINT, exec, dms screenshot"

          "$mod, Space, exec, dms ipc call spotlight toggle"
          "$mod, V, exec, dms ipc call clipboard toggle"
          "$mod, M, exec, dms ipc call processlist focusOrToggle"
          "$mod, N, exec, dms ipc call notifications toggle"
          "$mod, TAB, exec, dms ipc call hypr toggleOverview"
        ];
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        bindr = [
          # Discord
          ", code:199, sendshortcut, CTRL SHIFT, M, class:^(discord)$"
          ", code:200, sendshortcut, CTRL SHIFT, D, class:^(discord)$"

          # Spotify
          ", code:191, exec, playerctl --player=spotify previous"
          ", code:192, exec, playerctl --player=spotify play-pause"
          ", code:193, exec, playerctl --player=spotify next"
        ];
        binde = [
          # Spotify
          ", code:201, exec, playerctl --player=spotify volume 0.05-"
          ", code:202, exec, playerctl --player=spotify volume 0.05+"
        ];
      };
    };
  };
}
