{ inputs, config, lib, username, ... }:
{
  services.displayManager.defaultSession = "hyprland-uwsm";
  services.displayManager.dms-greeter = {
    enable = true;
    configHome = "/home/${username}";

    compositor = {
      name = "hyprland";
      customConfig = ''
        env = XCURSOR_THEME,Bibata-Modern-Classic
        env = XCURSOR_SIZE,24

        misc:disable_hyprland_logo = true
        misc:disable_splash_rendering = true
        misc:force_default_wallpaper = 0
        misc:background_color = rgb(000000)
      '';
    };
  };

  services.accounts-daemon.enable = true;

  users.users.${username} = {
    extraGroups = [ "greeter" ];
  };

  home-manager.users.${username} = {
    imports = [
      inputs.dms.homeModules.dank-material-shell
      inputs.dms-plugin-registry.nixosModules.default 
      inputs.danksearch.homeModules.dsearch
    ];

    xdg.autostart.enable = true;

    programs.dank-material-shell = {
      enable = true;
      systemd = {
        enable = true;
        restartIfChanged = true;
      };

      # Core features
      enableSystemMonitoring = true;
      enableDynamicTheming = true;
      enableVPN = true;
      enableAudioWavelength = false;
      enableCalendarEvents = true;

      managePluginSettings = true;

      plugins = {
        calculator.enable = true;
        dankKDEConnect.enable = true;
        simpleAudioControl.enable = true;
      };

      settings = {
        # Clipboard
        clipboardSettings = {
          disabled = false;
          disableHistory = false;
          maxHistory = 25;
          maxEntrySize = 5242880;
          autoClearDays = 1;
          clearAtStartup = true;

        };

        # Notifications
        notificationPopupPosition = 3;
        notificationHistoryMaxCount = 20;
        notificationHistoryMaxAgeDays = 1;

        # Application launcher
        sortAppsAlphabetically = true;
        dankLauncherV2Size = "medium";
        launcherLogoMode = "os";

        # USWM
        launchPrefix = "uwsm-app -- ";

        # Lock screen
        loginctlLockIntegration = true;
        lockScreenPowerOffMonitorsOnLock = true;

        # Matugen
        currentThemeName = "dynamic";
        currentThemeCategory = "dynamic";
        matugenScheme = "scheme-fidelity";
        widgetBackgroundColor = "sth";
        widgetColorMode = "default";

        popupTransparency = 0.35;

        animationSpeed = 0;
        syncComponentAnimationSpeeds = false;
        popoutAnimationSpeed = 0;
        modalAnimationSpeed = 0;

        modalDarkenBackground = false;

        # Fonts
        fontFamily = config.stylix.fonts.sansSerif.name;
        monoFontFamily = config.stylix.fonts.monospace.name;
        fontScale = 1;
        fontWeight = 400;

        # Power menu
        powerMenuActions = [
          "reboot"
          "poweroff"
        ]
        ++ lib.optionals (config.modules.solas.isLoaded or false) [
          "suspend"
        ];
        powerMenuDefaultAction = "poweroff";
        
        barConfigs =
        []
        ++ lib.optionals (config.modules.azazel.isLoaded or false)[
          {
            id = "default";
            name = "Main Bar";
            enabled = true;
            visible = true;

            position = 0;
            bottomGap = -5;
            innerPadding = 5;
            spacing = 0;
            transparency = 0;

            screenPreferences = [ "all" ];

            borderEnabled = false;
            widgetOutlineEnabled = true;
            widgetOutlineColor = "primary";
            widgetOutlineThickness = 1;
            widgetOutlineOpacity = 0.30;

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
                id = "runningApps";
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
        ]
        ++ lib.optionals (config.modules.solas.isLoaded or false) [
          {
            id = "default";
            name = "Main Bar";
            enabled = true;
            visible = true;

            position = 0;
            bottomGap = -5;
            innerPadding = 5;
            spacing = 0;
            transparency = 0;

            screenPreferences = [ "all" ];

            borderEnabled = false;
            widgetOutlineEnabled = true;
            widgetOutlineColor = "primary";
            widgetOutlineThickness = 1;
            widgetOutlineOpacity = 0.35;

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
                id = "simpleAudioControl";
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
      }
      // lib.optionalAttrs (config.modules.azazel.isLoaded or false) {
        # Displays
        hyprlandOutputSettings = {
          "desc:LG Electronics LG TV SSCR2 0x01010101" = {
            bitdepth = 10;
            vrrFullscreenOnly = true;
          };
        };
      };
    };

    # DankSearch - FuzzyFinder
    programs.dsearch = {
      enable = true;
    };
  };
}
