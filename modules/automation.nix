{ ... }:
{
  # Enable automatic Optimization of nix store size
  nix.optimise =
  {
    automatic = true;
    dates = [ "daily" ];
  };

  # Enable automatic Garbage Collector 
    nix.gc =
    { 
      automatic = true; 
      dates = "daily";
      options = "--delete-older-than 7d";
    }; 
    systemd.timers."nix-gc.timer".timerConfig =
    {  
      OnCalendar = "daily"; 
      Persistent = true;  
    };
   
  # Enable automaticUpgrade
  system.autoUpgrade =
  {
    enable = true;
    dates = "weekly";
  };
}
