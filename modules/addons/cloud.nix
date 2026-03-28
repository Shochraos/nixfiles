{ pkgs, username, ...}:
{
  home-manager.users.${username} =
  {
    home.packages = with pkgs; 
    [     
      nextcloud-client
      feishin 
    ];
    
    xdg.autostart = 
    {
      entries = 
      [
        "${pkgs.nextcloud-client}/share/applications/com.nextcloud.desktopclient.nextcloud.desktop"
      ];
    };
    
    programs.vdirsyncer.enable = true;
    services.vdirsyncer.enable = true;
    programs.khal = 
    {
     enable = true;
     settings = 
     {
       default.default_calendar = "personal";
     };
    };
  
    accounts.calendar =
    {
      basePath = ".local/share/calendars";
      accounts = 
      {
        nextcloud = 
        {
          primary = false;
          khal.enable = true;
          khal.type = "discover";
          
          vdirsyncer.enable = true;
          vdirsyncer.collections = [ "personal" "work" ]; 
          
          remote = {
            type = "caldav";
            url = "https://cloud.freunds.me/remote.php/dav/calendars/Shochraos/";
            userName = "Shochraos";
            passwordCommand = [ "cat" "/home/${username}/nixfiles/local/nextcloud_cal_pass" ];
          };
          
          local = {
            type = "filesystem";
            fileExt = ".ics";
          };
        };
        };  
      };
  };
}