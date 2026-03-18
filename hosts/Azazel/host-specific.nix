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
  
  home-manager.users.${username} = 
  {
    home.packages = with pkgs; 
    [          
      feather
      electrum
    ];
    
    programs.ghostty =
    {
        settings =
        { 
          window-height = 50;
          window-width  = 150;
        };
    };
    
    programs.plasma = 
    {
      kscreenlocker =
      {
        autoLock = false;
        passwordRequired = false;
      };
      
      window-rules =
      [
        {
          description = "Discord";
          match =
          {
            window-class =
            {
              type = "exact";
              value = "discord";
              match-whole = false;
            };
          };
          apply =
          {
            desktops = "Desktop_2";
            position = { value = "0,0"; };
            size = { value = "1920,2116"; };
            noborder = { value = true; };
            ignoregeometry = { apply = "force"; value = true; };
          };
        }
        {
          description = "Spotify";
          match =
          {
            window-class =
            {
              type = "exact";
              value = "spotify";
              match-whole = false;
            };
          };
          apply =
          {
            desktops = "Desktop_2";
            position = { value = "1920,0"; };
            size = { value = "1920,2116"; };
            noborder = { value = true; };
            ignoregeometry = { apply = "force"; value = true; };
          };
        }
        {
          description = "Feishin";
          match =
          {
            window-class =
            {
              type = "exact";
              value = "feishin";
              match-whole = false;
            };
          };
          apply =
          {
            desktops = "Desktop_2";
            position = { value = "1920,0"; };
            size = { value = "1920,2116"; };
            ignoregeometry = { apply = "force"; value = true; };
          };
        }
        {
          description = "Zen-Browser";
          match =
          {
            window-class =
            {
              type = "exact";
              value = "zen-beta";
              match-whole = false;
            };
          };
          apply =
          {
            desktops = "Desktop_3";
            position = { value = "0,0"; };
          };
        }
        {
          description = "Steam";
          match =
          {
            window-class =
            {
              type = "exact";
              value = "steam";
              match-whole = false;
            };
            title =
            {
              type = "exact";
              value = "Steam";
            };
          };
          apply =
          {
            desktops = "Desktop_3";
            position = { value = "1920,0"; };
            size = { value = "1920,2116"; };
            ignoregeometry = { apply = "force"; value = true; };
          };
        }
        {
          description = "Steam Big Picture";
          match =
          {
            window-class =
            {
              type = "exact";
              value = "steam";
              match-whole = false;
            };
            title =
            {
              type = "exact";
              value = "Steam Big Picture Mode";
            };
          };
          apply =
          {
            desktops = "Desktop_3";
            position = { value = "1920,0"; };
            size = { value = "1920,2116"; };
            noborder = { value = true; };
            ignoregeometry = { apply = "force"; value = true; };
          };
        }
        {
          description = "Steam Games";
          match =
          {
            window-class =
            {
              type = "regex";
              value = "^steam_.*$";
              match-whole = false;
            };
          };
          apply =
          {
            desktops = "Desktop_1";
          };
        }
        {
          description = "Ghostty";
          match =
          {
            window-class =
            {
              type = "exact";
              value = "com.mitchellh.ghostty";
              match-whole = false;
            };
          };
          apply =
          {
            position = { value = "1178,459"; };
          };
        }
        {
          description = "MPV";
          match = {
            window-class = {
              type = "exact";
              value = "mpv";
              match-whole = false;
            };
          };
          apply = {
            desktops = "Desktop_1";
          };
        }
      ];
      
      panels = 
      [
        {     
          widgets =
          [
            {
              systemTray.items = 
              {
                hidden = [ "org.kde.plasma.battery" ];
              };
            }
            {
              digitalClock = {
                calendar.firstDayOfWeek = "sunday";
                time.format = "24h";
              };
            }
          ];
        }
      ];
    };
  };
}