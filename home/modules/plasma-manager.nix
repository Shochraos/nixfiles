{ config, lib, isAzazel, isBelphegor, ... }:
{
  #TODO refactor into its own folder plasma-manager with plasma.nix and modules
  programs.plasma = {
      enable = true;
      overrideConfig = true;

      panels = [
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
                ];
                hidden = [
                  "org.kde.plasma.mediacontroller"
                  "org.kde.plasma.battery"
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

      input =
      {
          mice =
          []
          ++ lib.optionals isAzazel
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
        };

        shortcuts =
        {
          kwin = 
          {
            "Switch One Desktop to the Left" = ["Ctrl+T" "Meta+Ctrl+Left"];
            "Switch One Desktop to the Right" = ["Ctrl+W" "Meta+Ctrl+Right"];
          };

          mediacontrol =
          {
            mediavolumedown = "F11";
            mediavolumeup = "F12";
          };
        };
        
        hotkeys.commands = lib.mkMerge
        [
          {
            Ghostty = 
            {
              command = "ghostty --gtk-single-instance=true";
              key = "Meta + T";
            };
            Dolphin = 
            {
              command = "dolphin %u";
              key = "Meta + F";
            };
          }
          (lib.mkIf isAzazel
            {
              GameChat-Chat = 
              {
                command = "${config.home.homeDirectory}/Scripts/GameChat/gamechat_chat.sh";
                key = "XF86AudioLowerVolume";
              };
              GameChat-Game =
              {
                command = "${config.home.homeDirectory}/Scripts/GameChat/gamechat_game.sh";
                key = "XF86AudioRaiseVolume";
              };
              GameChat-Reset =
              {
                command = "${config.home.homeDirectory}/Scripts/GameChat/gamechat_reset.sh";
                key = "Ctrl + Shift + M";
              };
            })
        ];

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

        window-rules =
        []
        ++ lib.optionals isAzazel
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

        kscreenlocker =
        {
          autoLock = true;
          timeout = 5;
          passwordRequired = true;
          passwordRequiredDelay = 5;
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

        powerdevil = lib.mkMerge
        [
          {}
          (lib.mkIf isAzazel
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
          })
        ];

        session =
        {
          sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
        };

      #TODO Volume widget should show virtual Audio Outputs, not possible currently
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
};
}