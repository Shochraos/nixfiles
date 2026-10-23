{
  den.aspects.sync =
    {
      user,
      host,
      ...
    }:
    {
      nixos =
        { lib, ... }:
        let
          passKey = "calendar/nextcloud-pass/${lib.toLower host.name}";

          todomanSphinxOverlay = _final: prev: {
            todoman = prev.todoman.overrideAttrs (_old: {
              preInstallSphinx = ''
                rm -rf .sphinx/man/man/_static
              '';
            });
          };
        in
        {
          nixpkgs.overlays = [ todomanSphinxOverlay ];

          sops.secrets = {
            ${passKey}.owner = user.name;
            "calendar/nextcloud-url".owner = user.name;
            "calendar/uni-url".owner = user.name;
          };
        };

      provides.to-users.homeManager =
        {
          osConfig,
          pkgs,
          lib,
          ...
        }:
        let
          passKey = "calendar/nextcloud-pass/${lib.toLower host.name}";
          desktopEntry = "com.nextcloud.desktopclient.nextcloud.desktop";

          nextcloudAutostart = pkgs.runCommandLocal "nextcloud-autostart.desktop" { } ''
            cp ${pkgs.nextcloud-client}/share/applications/${desktopEntry} $out
            chmod u+w $out
            substituteInPlace $out \
              --replace-fail 'Exec=nextcloud %u' 'Exec=nextcloud --background %u'
          '';
        in
        {
          home.packages = with pkgs; [
            nextcloud-client
            feishin
          ];

          xdg.configFile."autostart/${desktopEntry}".source = nextcloudAutostart;

          programs.vdirsyncer.enable = true;
          services.vdirsyncer.enable = true;

          programs.todoman = {
            enable = true;
            glob = "nextcloud/[pw]*";
            extraConfig = ''
              date_format = "%Y-%m-%d"
              time_format = "%H:%M"
              dt_separator = " "
              default_list = "personal"
              default_due = 0
              humanize = True
              startable = True
            '';
          };
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
                  conflictResolution = "local wins";
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
                    osConfig.sops.secrets.${passKey}.path
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
