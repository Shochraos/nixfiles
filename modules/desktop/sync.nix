{
  aspects.nixos.sync =
    { username, ... }:
    {
      sops.secrets = {
        "calendar/nextcloud-pass".owner = username;
        "calendar/nextcloud-url".owner = username;
        "calendar/uni-url".owner = username;
      };
    };

  aspects.home.sync =
    {
      osConfig,
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        nextcloud-client
        feishin
      ];

      xdg.autostart = {
        entries = [
          "${pkgs.nextcloud-client}/share/applications/com.nextcloud.desktopclient.nextcloud.desktop"
        ];
      };

      programs.vdirsyncer.enable = true;
      services.vdirsyncer.enable = true;
      programs.khal = {
        enable = true;
        settings = {
          default.default_calendar = "personal";
        };
      };

      accounts.calendar = {
        basePath = ".local/share/calendars";
        accounts = {
          nextcloud = {
            primary = false;
            khal.enable = true;
            khal.type = "discover";

            vdirsyncer = {
              enable = true;
              collections = [
                "personal"
                "work"
                "feiertage"
              ];
              urlCommand = [
                "cat"
                osConfig.sops.secrets."calendar/nextcloud-url".path
              ];
            };

            remote = {
              type = "caldav";
              userName = "Shochraos";
              passwordCommand = [
                "cat"
                osConfig.sops.secrets."calendar/nextcloud-pass".path
              ];
            };

            local = {
              type = "filesystem";
              fileExt = ".ics";
            };
          };

          uni = {
            primary = false;
            khal.enable = true;
            khal.readOnly = true;

            vdirsyncer = {
              enable = true;
              urlCommand = [
                "cat"
                osConfig.sops.secrets."calendar/uni-url".path
              ];
            };

            remote.type = "http";

            local = {
              type = "filesystem";
              fileExt = ".ics";
            };
          };
        };
      };
    };
}
