{ username, ... }:
{
  nix = 
  {
    settings.experimental-features = [ "nix-command" "flakes"];
    settings.download-buffer-size = 524288000;
    
    optimise =
    {
      automatic = true;
      dates = [ "daily" ];
    };
    
    gc = 
    {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
  };
  
  systemd.timers."nix-gc.timer".timerConfig =
  {
    OnCalendar = "daily";
    Persistent = true;
  };
  
  nixpkgs.config.allowUnfree = true;
  
  system.stateVersion = "25.05";
  
  home-manager.users.${username} = 
  {
    home.stateVersion = "25.05";
  };
}