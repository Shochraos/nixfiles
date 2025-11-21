{ lib, isAzazel, ...}:
{
  programs.plasma = 
  {
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
  };
}