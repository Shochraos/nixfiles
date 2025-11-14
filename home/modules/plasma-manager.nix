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
            repeatRate = 50;
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
          names = [ "Desktop1" "Desktop2" "Desktop3" ];
          number = 3;
          rows = 1;
        };

        window-rules =
        [
          {
            description = "Spotify";
            match =
            {
              window-class =
              {
                value = "Spotify";
                match-whole = true;
                type = "exact";
              };
              desktops =
              {
                value = "Desktop1";
                type = "exact";
              };
            };
            apply =
            {
              position = { value = "1920,0"; };
              size = { value = "1920,2116"; };
              noborder = { value = true; };
              ignoregeometry = { value = true; };
            };
          }
          {
            description = "Zen-Browser";
            match =
            {
              window-class =
              {
                value = "zen-beta";
                match-whole = true;
                type = "exact";
              };
              desktops =
              {
                value = "Desktop2";
                type = "exact";
              };
            };
            apply =
            {
              position = { value = "0,0"; };
              noborder = { value = false; };
              ignoregeometry = { value = false; };
            };
          }
          {
            description = "Steam";
            match =
            {
              window-class =
              {
                value = "steam";
                match-whole = true;
                type = "exact";
              };
              desktops =
              {
                value = "Desktop2";
                type = "exact";
              };
            };
            apply =
            {
              position = { value = "1920,0"; };
              size = { value = "1920,1080"; };
              noborder = { value = true; };
            };
          }
          {
            description = "Ghostty";
            match =
            {
              window-class =
              {
                value = "com.mitchellh.ghostty";
                match-whole = true;
                type = "exact";
              };
              desktops =
              {
                value = "Desktop3";
                type = "exact";
              };
            };
            apply =
            {
              position = { value = "1178,459"; };
              size = { value = "800,600"; };
              noborder = { value = true; };
            };
          }
          {
            description = "Discord";
            match =
            {
              window-class =
              {
                value = "discord";
                match-whole = true;
                type = "exact";
              };
              desktops =
              {
                value = "Desktop1";
                type = "exact";
              };
            };
            apply =
            {
              position = { value = "0,0"; };
              size = { value = "1920,2116"; };
              noborder = { value = true; };
              ignoregeometry = { value = true; };
            };
          }
          {
            description = "MPV";
            match = {
              window-class = {
                value = "mpv";
                match-whole = true;
                type = "exact";
              };
              desktops = {
                value = "Desktop1";
                type = "exact";
              };
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

        #TODO noch nicht fertig
        powerdevil =
        {
          AC =
          {
            autoSuspend.action = "nothing";
            dimDisplay.enable = false;
          };
        };
  };
}