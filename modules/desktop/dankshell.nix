{ inputs, ... }:
{
  den.aspects.dankshell =
    { user, ... }:
    {
      nixos =
        { config, ... }:
        let
          pluginSettings = {
            calculator.enabled = true;
            dankKDEConnect.enabled = true;
            simpleAudioControl.enabled = true;
            claudeUsage.enabled = true;
            #discordVoice = {
            #  enabled = true;
            #  maxBarAvatars = 10;
            #};

            khalCalendar = {
              enabled = true;
              calendarFilter = "";
              vdirBasePath = "/home/${user.name}/.local/share/calendars/nextcloud";

              lookAheadDays = 7;
              refreshInterval = 5;

              showLocation = true;
              showCalendarName = true;

              notificationsEnabled = true;
              notifyMinutes = 15;
            };

            tasks = {
              enabled = true;
              caldavUsername = "Shochraos";
              caldavCalendar = "Personal";
              caldavCalendars = "Work";
              refreshInterval = "5";
              caldavSSLVerify = true;
              caldavURL = "@DMS_CALDAV_URL@";
              caldavPassword = "@DMS_CALDAV_PASS@";
            };
          };
        in
        {
          services.displayManager.defaultSession = "hyprland-uwsm";
          services.displayManager.dms-greeter = {
            enable = true;
            configHome = "/home/${user.name}";

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

          users.users.${user.name} = {
            extraGroups = [ "greeter" ];
          };

          sops.templates."dms-plugin-settings.json" = {
            owner = user.name;
            content =
              builtins.replaceStrings
                [ "@DMS_CALDAV_URL@" "@DMS_CALDAV_PASS@" ]
                [
                  config.sops.placeholder."calendar/nextcloud-url"
                  config.sops.placeholder."calendar/nextcloud-pass"
                ]
                (builtins.toJSON pluginSettings);
          };
        };

      provides.to-users.homeManager =
        {
          config,
          osConfig,
          pkgs,
          ...
        }:
        let
          barDefaults = {
            id = "default";
            name = "Main Bar";
            enabled = true;
            visible = true;

            position = 0;
            bottomGap = 0;
            innerPadding = 5;
            spacing = 0;
            transparency = 0;

            popupGapsAuto = false;
            popupGapsManual = 6;

            screenPreferences = [ "all" ];

            borderEnabled = false;
            widgetOutlineEnabled = true;
            widgetOutlineColor = "primary";
            widgetOutlineThickness = 1;
            widgetOutlineOpacity = 0.35;
          };
        in
        {
          imports = [
            inputs.dms.homeModules.dank-material-shell
            inputs.dms-plugin-registry.nixosModules.default
            inputs.danksearch.homeModules.dsearch
          ];

          home.packages = [
            # Claude Usage
            pkgs.jq
            # DiscordVoice and Tasks (caldav)
            (pkgs.python3.withPackages (
              ps: with ps; [
                caldav
                httpx
                urllib3
              ]
            ))
          ];

          xdg.autostart.enable = true;

          programs.dank-material-shell = {
            enable = true;
            systemd = {
              enable = true;
              restartIfChanged = true;
            };

            enableSystemMonitoring = true;
            enableDynamicTheming = true;
            enableVPN = true;
            enableAudioWavelength = false;
            enableCalendarEvents = true;

            managePluginSettings = false;

            plugins = {
              calculator.enable = true;
              dankKDEConnect.enable = true;
              simpleAudioControl.enable = true;
              claudeUsage.enable = true;
              #discordVoice.enable = true;
              tasks.enable = true;
              khalCalendar.enable = true;
            };

            settings = {
              clipboardSettings = {
                disabled = false;
                disableHistory = false;
                maxHistory = 25;
                maxEntrySize = 5242880;
                autoClearDays = 1;
                clearAtStartup = true;
              };

              soundsEnabled = false;

              notificationPopupPosition = 3;
              notificationHistoryMaxCount = 20;
              notificationHistoryMaxAgeDays = 1;

              hyprlandLayoutRadiusOverride = 12;
              hyprlandLayoutBorderSize = 1;
              hyprlandResizeOnBorder = false;

              sortAppsAlphabetically = true;
              dankLauncherV2Size = "medium";
              launcherLogoMode = "os";

              launchPrefix = "uwsm-app -- ";

              loginctlLockIntegration = true;
              lockScreenPowerOffMonitorsOnLock = false;

              currentThemeName = "dynamic";
              currentThemeCategory = "dynamic";
              matugenScheme = "scheme-fidelity";
              widgetBackgroundColor = "sth";
              widgetColorMode = "default";

              popupTransparency = 0.5;

              animationSpeed = 0;
              syncComponentAnimationSpeeds = false;
              popoutAnimationSpeed = 0;
              modalAnimationSpeed = 0;

              modalDarkenBackground = false;

              m3ElevationEnabled = false;
              modalElevationEnabled = false;
              popoutElevationEnabled = false;
              barElevationEnabled = false;

              cornerRadius = 16;
              hyprlandLayoutGapsOverride = -2;

              iconThemeDark = osConfig.stylix.icons.dark;

              controlCenterShowMicPercent = false;
              osdPowerProfileEnabled = false;

              fontFamily = osConfig.stylix.fonts.sansSerif.name;
              monoFontFamily = osConfig.stylix.fonts.monospace.name;
              fontScale = 1;
              fontWeight = 400;

              powerMenuActions = [
                "reboot"
                "poweroff"
              ]
              ++ osConfig.host.dms.powerMenuActions;
              powerMenuDefaultAction = "poweroff";

              barConfigs = map (bar: barDefaults // bar) osConfig.host.dms.barConfigs;

              hyprlandOutputSettings = osConfig.host.dms.hyprlandOutputSettings;
            };
          };

          xdg.configFile."DankMaterialShell/plugin_settings.json".source =
            config.lib.file.mkOutOfStoreSymlink
              osConfig.sops.templates."dms-plugin-settings.json".path;

          programs.dsearch = {
            enable = true;
          };
        };
    };
}
