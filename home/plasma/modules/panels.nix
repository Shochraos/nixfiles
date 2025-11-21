{ lib, isAzazel, isBelphegor, ... }:
{
  programs.plasma =
  {
    panels = 
    [
      {
        location = "bottom";
        floating = false;
        height = 44;
        hiding = "normalpanel";
        opacity = "translucent";
    
        widgets =
        [
          "org.kde.plasma.kickoff"
          {
            iconTasks = {
              launchers = [];
            };
          }
          "org.kde.plasma.marginsseparator"
          {
            systemTray.items = {
              shown = [
                "org.kde.plasma.networkmanagement"
                "org.kde.plasma.bluetooth"
                "org.kde.plasma.volume"
              ]
              ++ lib.optionals isBelphegor
              [
                "org.kde.plasma.battery"
              ];
              hidden = [
                "org.kde.plasma.mediacontroller"
                "org.kde.plasma.brightness"
                "org.kde.plasma.power-management"
                "plasmashell_microphone"
                "jellyfin-mpv-shim"
                #Discord
                "chrome_status_icon_1"
                "steam"
                "Nextcloud"
              ]
              ++ lib.optionals isAzazel
              [
                "org.kde.plasma.battery"
              ];
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
}