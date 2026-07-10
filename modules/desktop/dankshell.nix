{
  aspects.nixos.dankshell =
    { username, ... }:
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
    };

  aspects.home.dankshell =
    {
      inputs,
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

      # Claude Usage and DiscordVoice
      home.packages = [ 
        pkgs.jq 
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
        enableAudioWavelength = false;
        enableCalendarEvents = true;

        managePluginSettings = true;

        plugins = {
          calculator.enable = true;
          dankKDEConnect.enable = true;
          simpleAudioControl.enable = true;
          claudeUsage.enable = true;
          tasks.enable = true;
          discordVoice.enable = true;
          
          #dcalUpcoming.enable = true;
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

      programs.dsearch = {
        enable = true;
      };
    };
}
