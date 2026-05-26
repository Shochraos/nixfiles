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

          shadow = {
            enabled = true;
            range = 30;
            render_power = 5;

            offset = "0 5";
          };
        };

        exec-once = [ ];

        layerrule = [
          "match:class ^(dms)$, no_anim on"
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
          "easeOutSine, 0.61, 1, 0.88, 1"
          "easeInOutSine, 0.37, 0, 0.63, 1"
        ];

        animation = [
          "windows, 1, 2, easeOutSine, slide"
          "workspaces, 1, 2, easeInOutSine, slidevert"
        ];

        source = [
          "~/.config/hypr/dms/colors.conf"
          "~/.config/hypr/dms/layout.conf"
          "~/.config/hypr/dms/outputs.conf"
          "~/.config/hypr/dms/cursor.conf"
        ];
      };
    };
  };
}
