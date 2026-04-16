{ inputs, username, ... }:
{
  services.displayManager.defaultSession = "hyprland-uwsm";
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
    
    xdg.autostart.enable = true;
    
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
        calculator.enable = true;
        dankKDEConnect.enable = true;
        simpleAudioControl.enable = true;
      };
      
      settings = 
      { 
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
      };
    };
    
    # DankSearch - FuzzyFinder
    programs.dsearch = 
    {
      enable = true;
    };
  };
}