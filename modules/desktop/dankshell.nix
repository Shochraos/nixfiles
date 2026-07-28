{ inputs, ... }:
{
  den.aspects.dankshell =
    { user, ... }:
    {
      nixos =
        { config, ... }:
        {
          services.displayManager.defaultSession = "hyprland-uwsm";
          services.displayManager.dms-greeter = {
            enable = true;
            configHome = config.users.users.${user.name}.home;

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
        };

      provides.to-users.homeManager =
        {
          config,
          lib,
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
            inputs.dms-plugin-registry.homeModules.default
            inputs.danksearch.homeModules.dsearch
          ];

          home.packages = [
            # Claude Usage
            pkgs.jq
            # DiscordVoice
            pkgs.python3
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
            enableAudioWavelength = true;
            enableCalendarEvents = true;

            plugins = {
              calculator.enable = true;
              dankKDEConnect.enable = true;
              simpleAudioControl.enable = true;
              claudeUsage.enable = true;
              dankTodoman.enable = true;
              discordVoice = {
                enable = true;
                settings.maxBarAvatars = 10;
              };
              khalCalendar = {
                enable = true;
                settings = {
                  calendarFilter = "";
                  vdirBasePath = "${config.home.homeDirectory}/.local/share/calendars/nextcloud";

                  lookAheadDays = 7;
                  refreshInterval = 5;

                  showLocation = true;
                  showCalendarName = true;

                  notificationsEnabled = true;
                  notifyMinutes = 15;
                };
              };
            }
            // osConfig.host.dms.plugins;

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
              audioVisualizerEnabled = false;

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

              blurEnabled = true;

              animationSpeed = 4;
              customAnimationDuration = 325;
              syncComponentAnimationSpeeds = true;
              animationVariant = 1;
              motionEffect = 1;

              modalDarkenBackground = true;

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

              hyprlandOutputSettings = builtins.mapAttrs (
                _: output:
                lib.optionalAttrs (output.bitdepth != null) { inherit (output) bitdepth; }
                // lib.optionalAttrs output.vrrFullscreenOnly { vrrFullscreenOnly = true; }
                // lib.optionalAttrs output.hdr { supportsHdr = true; }
                // lib.optionalAttrs output.wideColor { supportsWideColor = true; }
              ) osConfig.host.outputs;
            };
          };

          programs.dsearch = {
            enable = true;
          };
        };
    };
}
