{
  den.aspects.sync =
    { user, ... }:
    {
      nixos = {
        sops.secrets = {
          "calendar/nextcloud-pass".owner = user.name;
          "calendar/nextcloud-url".owner = user.name;
          "calendar/uni-url".owner = user.name;
        };
      };

      provides.to-users.homeManager =
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
            locale = {
              dateformat = "%Y-%m-%d";
              timeformat = "%H:%M";
              datetimeformat = "%Y-%m-%d %H:%M";
              longdateformat = "%Y-%m-%d";
              longdatetimeformat = "%Y-%m-%d %H:%M";
            };
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
                    "lecturer-timetable"
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
    };
}
