{ pkgs, username, ... }:
{
  environment.systemPackages = with pkgs; [ wakeonlan ];
  
  systemd.services.wol-lgtv = 
  {
    description = "WoL LGTV";
    
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "display-manager.service" ];
    wantedBy = [ "graphical.target" ];
    
    serviceConfig = 
    {
      Type = "oneshot";
      ExecStart = "${pkgs.wakeonlan}/bin/wakeonlan wakeonlan -i 192.168.30.6 60:45:e8:1e:b5:40"; 
    };
  };
  
  services.xserver.xkb =
  {
    layout = "de";
    variant = "";
  };
  console.keyMap = "de";
  
  home-manager.users.${username} = 
  {
    home.packages = with pkgs; 
    [          
      feather
      electrum
    ];
    
    wayland.windowManager.hyprland = 
    {
        settings = 
        {       
          input = 
          {
            kb_layout = "de"; 
            kb_variant = "nodeadkeys";
             
            accel_profile = "flat";
          };
          
          cursor = 
          {
            no_hardware_cursors = true;
          };
        };
    };
    
    programs.ghostty =
    {
        settings =
        { 
          window-height = 50;
          window-width  = 150;
        };
    };
  };
}