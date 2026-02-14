{ pkgs, username, ... }:
{
  services.xserver.enable = false;

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  
  environment.systemPackages = with pkgs;
  [
    kdePackages.kdeconnect-kde
    kdePackages.kwallet-pam
    kdePackages.skanpage
    kdePackages.kcalc
    kdePackages.partitionmanager
    kdePackages.isoimagewriter
  ];

  environment.plasma6.excludePackages = (with pkgs;
  [
    kdePackages.elisa
    kdePackages.khelpcenter
  ]);
  
  networking.firewall =
    {
      enable = true;
      allowedTCPPortRanges =
      [
        { from = 1714; to = 8081; } # KDE Connect
      ];
      allowedUDPPortRanges =
      [
        { from = 1714; to = 1764; } # KDE Connect
      ];
    };
    
  home-manager.users.${username} = 
  {
    programs.plasma = 
    {
      enable = true;
      overrideConfig = true;
      
      configFile =
      {
        "kdeglobals".General =
        {
          TerminalApplication = "ghostty";
        };
        "kdeglobals"."KFileDialog Settings" =
        {
          "Show hidden files" = false;
          "View Style" = "DetailTree";
        };
        "dolphinrc"."General" =
        {
          RememberOpenedTabs = false;
        };
        "dolphinrc"."DetailsMode" =
        {
          PreviewSize = 32;
        };
      };
      
      input =
      {
        mice =
        [
          {
            name = "Razer Razer Basilisk V3 Pro";
            vendorId = "1532";
            productId = "00ab";
            enable = true;
            acceleration = null;
            accelerationProfile = "none";
            scrollSpeed = 1;
            naturalScroll = false;
            middleButtonEmulation = false;
          }
          {
            name = "Keychron  Keychron Link ";
            vendorId = "3434";
            productId = "d030";
            enable = false;
          }
          {
            name = "Razer Razer Basilisk V3 Pro Keyboard";
            vendorId = "1532";
            productId = "00ab";
            enable = false;
          }
          {
            name = "Razer Razer Basilisk V3 Pro Mouse";
            vendorId = "1532";
            productId = "00ab";
            enable = false;
          }
        ];
  
        keyboard =
        {
          repeatDelay = 400;
          repeatRate = 40;
        };
  
        touchpads =
        [{
          name = "DualSense Wireless Controller Touchpad";
          vendorId = "054c";
          productId = "0ce6";
          enable = false;
        }];
      };
      
      windows =
      {
        allowWindowsToRememberPositions = false;
      };
  
      kwin.effects =
      {
        blur =
        {
          enable = true;
          strength = 15;
          noiseStrength = 6;
        };
  
        translucency.enable = false;
  
        desktopSwitching =
        {
          navigationWrapping = true;
          animation = "slide";
        };
      };
  
      kwin =
      {
        virtualDesktops =
        {
          names = [ "Desktop_1" "Desktop_2" "Desktop_3" ];
          number = 3;
          rows = 1;
        };
      };
      
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
      
      powerdevil =
      {
        AC =
        {
          autoSuspend.action = "nothing";
          dimDisplay.enable = false;
          powerButtonAction = "showLogoutScreen";

          turnOffDisplay =
          {
            idleTimeout = 36000;
            idleTimeoutWhenLocked = "immediately";
          };
        };
      };
      
      kscreenlocker =
      {
        autoLock = true;
        timeout = 5;
        passwordRequired = true;
        passwordRequiredDelay = 5;
      };
          
      session =
      {
        sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
      };
      
      shortcuts =
      {
        kwin = 
        {
          "Switch One Desktop to the Left" = ["Meta+Ctrl+Left"];
          "Switch One Desktop to the Right" = ["Meta+Ctrl+Right"];
        };
    
        mediacontrol =
        {
          mediavolumedown = "F11";
          mediavolumeup = "F12";
        };
        "services/org.kde.dolphin.desktop"._launch = "Meta+F";
        "services/com.mitchellh.ghostty.desktop"._launch = "Meta+T";         
        "services/gamechat_chat.desktop"._launch = "Volume Down";
        "services/gamechat_game.desktop"._launch = "Volume Up";
        "services/gamechat_reset.desktop"._launch = "Ctrl+Shift+D";
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
              value = "Spotify";
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
      
      workspace =
      {
        enableMiddleClickPaste = false;
  
        lookAndFeel = "com.github.vinceliuice.Orchis-dark";
        theme = "Unity-Plasma";
        colorScheme = "MateriaDark";
        iconTheme = "Tela circle dark";
        soundTheme = "Ocean";
        wallpaperPictureOfTheDay.provider = "bing";
      };
    };
  };
}