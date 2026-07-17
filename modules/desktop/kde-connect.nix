{
  den.aspects.kde-connect.nixos =
    { pkgs, ... }:
    {
      programs.kdeconnect = {
        enable = true;
        package = pkgs.valent;
      };
    };

  den.aspects.kde-connect.provides.to-users.homeManager =
    { pkgs, ... }:
    {
      systemd.user.services.valent = {
        Unit = {
          Description = "Valent (KDE Connect Implementation)";
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.valent}/bin/valent --gapplication-service";
          Restart = "on-failure";
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
