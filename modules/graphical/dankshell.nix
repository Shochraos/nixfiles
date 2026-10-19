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
    if builtins.length primaryOutputs > 1 then
      throw "dankshell: at most one host.outputs entry may set primary = true, got ${toString (builtins.length primaryOutputs)}"
    else if primaryOutputs == [ ] then
      [ "all" ]
    else
      primaryOutputs;

  quickshellIpcReconnectOverlay = _final: prev: {
    quickshell = prev.quickshell.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ config.assets.quickshellIpcReconnectPatch ];
    });
  };
in
{
  den.aspects.dankshell =
    { user, ... }:
    {
      nixos =
        { config, ... }:
        {
          nixpkgs.overlays = [ quickshellIpcReconnectOverlay ];

          services.displayManager.defaultSession = "hyprland-uwsm";
          services.displayManager.dms-greeter = {
            enable = true;
            configHome = config.users.users.${user.name}.home;

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

          services.accounts-daemon.enable = true;

          security.pam.services.greetd.enableGnomeKeyring = true;

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

          home.packages = [
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

              hyprlandLayoutRadiusOverride = 12;
              hyprlandLayoutBorderSize = 1;
              hyprlandResizeOnBorder = false;

              sortAppsAlphabetically = true;
              appDrawerSectionViewModes = {
                apps = "list";
              };
              dankLauncherV2Size = "medium";
              launcherLogoMode = "os";
              launcherLogoColorOverride = "primary";

              launchPrefix = "uwsm-app -- ";

              loginctlLockIntegration = true;
              lockScreenPowerOffMonitorsOnLock = false;

              currentThemeName = "dynamic";
              currentThemeCategory = "dynamic";
              matugenScheme = "scheme-rainbow";
              matugenSourceMode = "colorful";
              widgetBackgroundColor = "sc";
              widgetColorMode = "default";

              popupTransparency = 1;

              blurEnabled = true;
              blurForegroundLayers = false;
              blurLayerOutlineOpacity = 0;
              blurBorderEnabled = false;
              blurBorderOpacity = 0;

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

              controlCenterWidgets = [
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
                  id = "builtin_display_profiles";
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
