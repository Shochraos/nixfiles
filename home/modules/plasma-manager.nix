{ pkgs, ... }:
{
  programs.plasma = {
      enable = true;
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
              name = "Keychron  Keychron Link";
              enable = false;
            }
            {
              name = "Razer Razer Basilisk V3 Pro Keyboard";
              enable = false;
            }
            {
              name = "Razer Razer Basilisk V3 Pro Mouse";
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
          kwin."Switch One Desktop to the Left" = ["Ctrl+T" "Meta+Ctrl+Left"];
          kwin."Switch One Desktop to the Right" = ["Ctrl+W" "Meta+Ctrl+Right"];

          mediacontrol.mediavolumedown = "F11";
          mediacontrol.mediavolumeup = "F12";

          "services/net.local.gamechat_chat.sh.desktop"._launch = "Volume Down";
          "services/net.local.gamechat_game.sh.desktop"._launch = "Volume Up";
          "services/net.local.gamechat_reset.sh.desktop"._launch = "Ctrl+Shift+D";
          "services/org.kde.dolphin.desktop"._launch = "Meta+F";
          "services/com.mitchellh.ghostty.desktop"._launch = "Meta+T";
        };

        defaultApplications =
        {
          webBrowser = "zen-browser";
          textEditor = "kwrite";
          terminal = "ghostty";
          musicPlayer = "mpv";
          videoPlayer = "mpv";
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

          translucency.enable = true;

          desktopSwitching =
          {
            navigationWrapping = true;
            animation = "slide";
          };
        };

        virtualDesktops =
        {
          names = [ "Desktop_1" "Desktop_2" "Desktop_3" ];
          number = 3;
          rows = 1;
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
          wallpaper = "../../assets/themes/org.kde.plasma.citygrow.zip";
        };

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
  };
}