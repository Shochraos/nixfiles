{ inputs, pkgs, username, lib, ... }:
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
        { from = 1714; to = 8081; }
      ];
      allowedUDPPortRanges =
      [
        { from = 1714; to = 1764; }
      ];
    };
    
  home-manager.users.${username} = 
  {
    imports = [ inputs.plasma-manager.homeModules.plasma-manager ];
    
    programs.plasma = 
    {
      enable = true;
      overrideConfig = true;
      
      startup.desktopScript."panels".preCommands = lib.mkForce 
      ''
        sleep 3
        [ -f /home/${username}/.config/plasma-org.kde.plasma.desktop-appletsrc ] && rm /home/${username}/.config/plasma-org.kde.plasma.desktop-appletsrc        
      '';
      
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
              iconTasks = 
              {
                launchers = [];
              };
            }
            "org.kde.plasma.marginsseparator"
            {
              systemTray.items = 
              {
                shown = 
                [
                  "org.kde.plasma.networkmanagement"
                  "org.kde.plasma.bluetooth"
                  "org.kde.plasma.volume"
                ];
                hidden = 
                [
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
              digitalClock = 
              {
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
            idleTimeout = null;
            idleTimeoutWhenLocked = null;
          };
        };
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
      };
      
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