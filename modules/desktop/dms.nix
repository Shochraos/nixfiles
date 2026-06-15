{
  aspects.dms =
    {
      inputs,
      config,
      username,
      ...
    }:
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
            ++ config.host.dms.powerMenuExtraActions;
            powerMenuDefaultAction = "poweroff";

            # Bars (host-specific layout, see hosts/<name>/host-specific.nix)
            barConfigs = config.host.dms.barConfigs;

            # Displays (host-specific, default {} = no overrides)
            hyprlandOutputSettings = config.host.dms.hyprlandOutputSettings;
          };
        };

        # DankSearch - FuzzyFinder
        programs.dsearch = {
          enable = true;
        };
      };
    };
}
