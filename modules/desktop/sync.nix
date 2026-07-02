{
  aspects.home.sync =
    {
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      passFile = "${inputs.nixfiles-private}/nextcloud_cal_pass";
    in
    lib.warnIf (!builtins.pathExists passFile)
      "sync: nextcloud_cal_pass missing in nixfiles-private, calendar sync will fail to authenticate"
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

              vdirsyncer.enable = true;
              vdirsyncer.collections = [
                "personal"
                "work"
                "stundenplan-hs-fulda"
                "dozentenplan-hs-fulda"
                "feiertage"
              ];

              remote = {
                type = "caldav";
                url = "https://cloud.freunds.me/remote.php/dav/calendars/Shochraos/";
                userName = "Shochraos";
                passwordCommand = [
                  "cat"
                  passFile
                ];
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
