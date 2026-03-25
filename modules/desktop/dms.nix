{ inputs, config, username, ... }:
{
  services.displayManager.dms-greeter = 
  {
    enable = true;
    compositor.name = "hyprland";
    configHome = "/home/${username}";
  };
  
  users.users.${username} = 
  { 
    extraGroups = [ "greeter" ]; 
  };
  
  home-manager.users.${username} = 
  {
    imports = 
    [ 
      inputs.dms.homeModules.dank-material-shell
      inputs.dms-plugin-registry.modules.default 
      inputs.danksearch.homeModules.dsearch
    ];
    
    programs.dank-material-shell = 
    {
      enable = true;
      systemd = 
      {
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
      
      plugins = 
      {
        wallpaperBing.enable = true;
        dankKDEConnect.enable = true;
      };
      
      settings = 
      { 
        # Matugen
        currentThemeName = "dynamic";
        currentThemeCategory = "dynamic";
        matugenScheme = "scheme-fidelity";
        
        # Fonts
        fontFamily = config.stylix.fonts.sansSerif.name;
        monoFontFamily = config.stylix.fonts.monospace.name;
        fontScale = 1;
        fontWeight = 400;
        
        # Displays
        hyprlandOutputSettings = 
        {
          "desc:LG Electronics LG TV SSCR2 0x01010101" = 
          {
            bitdepth = 10;
            vrrFullscreenOnly = true;
          };
        };
        
        # Clipboard
        clipboardSettings = 
        {
          disabled = false;
          disableHistory = false;
          maxHistory = 25;
          maxEntrySize = 5242880;
          autoClearDays = 1;
          clearAtStartup = true;

        };
        
        # Notifications
        notificationPopupPosition = 3;
        notificationHistoryMaxAgeDays = 3;
        
        # Spotlight search
        sortAppsAlphabetically = true;
        dankLauncherV2Size = "medium";
        launcherLogoMode = "os";
        
        # USWM
        launchPrefix = "uwsm-app -- ";
        
        # Top bar
        barConfigs = 
        [
          {
            id = "default";
            name = "Main Bar";
            
            enabled = true;
            position = 0;
            screenPreferences = [ "all" ];
            
            spacing = 0;
            innerPadding = 5;
            bottomGap = -5;
            transparency = 0;
            visible = true;
            
            leftWidgets = [ "launcherButton" "workspaceSwitcher" "focusedWindow" ];
            centerWidgets = [ "music" "clock" "weather" ];
            rightWidgets =
            [ 
              { id = "wallpaperBing"; enabled = false; }
              { id = "dankKDEConnect"; enabled = true; }
              { id = "systemTray"; enabled = true; }
              { id = "clipboard"; enabled = true; }
              { id = "cpuUsage"; enabled = true; }
              { id = "memUsage"; enabled = true; }
              { id = "notificationButton"; enabled = true; }
              { id = "battery"; enabled = true; }
              { id = "controlCenterButton"; enabled = true; }
            ];
          }
        ];
        
        # Lock screen
        loginctlLockIntegration = true;
        lockScreenPowerOffMonitorsOnLock = true;
      
        # Power menu
        powerMenuActions = [ "reboot" "poweroff" "lock" "restart" ];
        powerMenuDefaultAction = "poweroff";
      };
    };
    
    programs.dsearch = 
    {
      enable = true;
    };
  };
}