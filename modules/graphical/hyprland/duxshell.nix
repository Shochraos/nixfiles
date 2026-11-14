{
  inputs,
  config,
  lib,
  ...
}:
let
  barScreens =
    outputs:
    let
      primaryOutputs = builtins.attrNames (lib.filterAttrs (_: output: output.primary) outputs);
    in
    if primaryOutputs == [ ] then [ "all" ] else primaryOutputs;

  quickshellIpcReconnectOverlay = _final: prev: {
    quickshell = prev.quickshell.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ config.assets.quickshellIpcReconnectPatch ];
    });
  };
in
{
  den.aspects.duxshell =
    { ... }:
    {
      nixos =
        { config, ... }:
        {
          nixpkgs.overlays = [ quickshellIpcReconnectOverlay ];

          services.displayManager.defaultSession = "hyprland-uwsm";
          services.displayManager.dux-greeter = {
            enable = true;
            configHome = config.users.users.shochraos.home;

            compositor = {
              name = "hyprland";
              customConfig = ''
                hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
                hl.env("XCURSOR_SIZE", "24")

                hl.config({
                  misc = {
                    disable_hyprland_logo = true,
                    disable_splash_rendering = true,
                    force_default_wallpaper = 0,
                    background_color = "rgb(000000)",
                  },
                })
              '';
            };
          };

          programs.dux-files.enable = true;

          xdg.mime.defaultApplications."inode/directory" = "dev.duxlabs.files.desktop";

          services.accounts-daemon.enable = true;

          security.pam.services.greetd.enableGnomeKeyring = true;

          users.users.shochraos = {
            extraGroups = [ "greeter" ];
          };
        };

      provides.to-users.homeManager =
        {
          config,
          lib,
          osConfig,
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
            followInterfaceStyle = false;
            transparency = 0;
            widgetFollowInterfaceStyle = false;
            widgetTransparency = 1;

            popupGapsAuto = false;
            popupGapsManual = 6;

            screenPreferences = barScreens osConfig.host.outputs;

            borderEnabled = false;
            widgetOutlineEnabled = false;
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

          services.udiskie.settings.program_options.file_manager =
            lib.getExe osConfig.programs.dux-files.package;

          xdg.configFile = {
            "hyprland-mimeapps.list".text = lib.generators.toINI { } {
              "Default Applications"."inode/directory" = "dev.duxlabs.files.desktop;";
            };

            "dfiles/ui-settings.json" = {
              force = true;
              text = builtins.toJSON {
                confirmTrash = true;
                searchHidden = true;
                showGamesSidebar = false;
                showHidden = true;
                showNetworkSidebar = false;
                startupFolder = "home";
              };
            };

            "dfiles/bookmarks.json" = {
              force = true;
              text = builtins.toJSON {
                version = 2;
                bookmarks = map (bookmark: bookmark // { icon = ""; }) [
                  {
                    path = "recent:///";
                    label = "recent";
                  }
                  {
                    path = config.home.homeDirectory;
                    label = config.home.username;
                  }
                  {
                    path = "${config.home.homeDirectory}/Desktop";
                    label = "Desktop";
                  }
                  {
                    path = "${config.home.homeDirectory}/Documents";
                    label = "Documents";
                  }
                  {
                    path = "${config.home.homeDirectory}/Downloads";
                    label = "Downloads";
                  }
                  {
                    path = "${config.home.homeDirectory}/Music";
                    label = "Music";
                  }
                  {
                    path = "${config.home.homeDirectory}/Pictures";
                    label = "Pictures";
                  }
                  {
                    path = "${config.home.homeDirectory}/Videos";
                    label = "Videos";
                  }
                  {
                    path = "/mnt/astaroth/appdata";
                    label = "Astaroth/Appdata";
                  }
                  {
                    path = "/mnt/astaroth/projects";
                    label = "Astaroth/Projects";
                  }
                  {
                    path = "/mnt/astaroth/misc";
                    label = "Astaroth/Misc";
                  }
                  {
                    path = "trash:///";
                    label = "trash";
                  }
                ];
              };
            };
          };

          xdg.autostart.enable = true;

          programs.bash.shellAliases = {
            copy = "dms cl copy";
            paste = "dms cl paste";
          };

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
              dankTodoman.enable = true;
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
            // builtins.mapAttrs (
              _: plugin: if plugin ? src then plugin // { src = lib.mkForce plugin.src; } else plugin
            ) osConfig.host.dms.plugins;

            settings = {
              clipboardSettings = {
                disabled = false;
                disableHistory = false;
                maxHistory = 25;
                maxEntrySize = 5242880;
                autoClearDays = 1;
                clearAtStartup = true;
              };

              soundsEnabled = true;
              muteSoundsWhenMediaPlaying = false;
              audioVisualizerEnabled = false;

              notificationFocusedMonitor = true;
              notificationPopupPosition = 3;
              notificationHistoryMaxCount = 20;
              notificationHistoryMaxAgeDays = 1;

              hyprlandLayoutRadiusOverride = 14;
              hyprlandLayoutBorderSize = 1;
              hyprlandResizeOnBorder = false;

              sortAppsAlphabetically = true;
              appDrawerSectionViewModes = {
                apps = "list";
              };
              dankLauncherV2Size = "medium";

              launchPrefix = "uwsm-app -- ";

              acLockTimeout = 600;
              batteryLockTimeout = 300;
              lockBeforeSuspend = true;
              loginctlLockIntegration = true;
              lockScreenPowerOffMonitorsOnLock = false;

              currentThemeName = "dynamic";
              currentThemeCategory = "dynamic";
              matugenScheme = "scheme-rainbow";
              matugenSourceMode = "colorful";
              widgetBackgroundColor = "s";
              widgetColorMode = "default";

              popupTransparency = 1;

              blurEnabled = true;
              blurForegroundLayers = false;
              blurLayerOutlineOpacity = 0;
              blurBorderEnabled = false;
              blurBorderOpacity = 0;

              animationSpeed = 1;
              syncComponentAnimationSpeeds = false;
              animationVariant = 1;
              motionEffect = 2;
              popoutAnimationSpeed = 2;
              modalAnimationSpeed = 2;
              springBounce = 2;
              notificationAnimationSpeed = 2;

              modalDarkenBackground = true;

              m3ElevationEnabled = false;
              modalElevationEnabled = false;
              popoutElevationEnabled = false;
              barElevationEnabled = false;

              cornerRadius = 14;
              hyprlandLayoutGapsOverride = -2;

              iconThemeDark = osConfig.stylix.icons.dark;

              controlCenterShowMicPercent = false;

              controlCenterWidgets = [
                {
                  id = "user";
                  enabled = true;
                  w = 5;
                  h = 1;
                }
                {
                  id = "settings";
                  enabled = true;
                  w = 1;
                  h = 1;
                  small = true;
                }
                {
                  id = "lock";
                  enabled = true;
                  w = 1;
                  h = 1;
                  small = true;
                }
                {
                  id = "power";
                  enabled = true;
                  w = 1;
                  h = 1;
                  small = true;
                }
                {
                  id = "volumeSlider";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "brightnessSlider";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "wifi";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "bluetooth";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "audioOutput";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "audioInput";
                  enabled = true;
                  width = 50;
                }
                {
                  id =
                    if osConfig.host.dms.plugins.duxMirror.enable or false then
                      "plugin_duxMirror"
                    else
                      "builtin_display_profiles";
                  enabled = true;
                  width = 50;
                }
                {
                  id = "builtin_vpn";
                  enabled = true;
                  width = 50;
                }
              ];

              osdVolumeEnabled = false;
              osdMediaVolumeEnabled = false;
              osdAlwaysShowValue = true;
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
