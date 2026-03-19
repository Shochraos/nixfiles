{ inputs, username, ... }:
{
  services.displayManager.dms-greeter = 
  {
    enable = true;
    compositor.name = "hyprland";
    configHome = "/home/${username}";
  };
  
  home-manager.users.${username} = 
  {
    imports = [ inputs.dms.homeModules.dank-material-shell ];
    
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
      enableVPN = true; 
      enableDynamicTheming = false;
      enableAudioWavelength = true;
      enableCalendarEvents = true; 
      
      settings = 
      {
        dynamicTheming = false;
        
        # Lock screen
        lockScreenPowerOffMonitorsOnLock = true;
      };
    };
  };
}