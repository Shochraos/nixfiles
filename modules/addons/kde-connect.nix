{
  aspects.kde-connect =
    { pkgs, username, ... }:
    {
      programs.kdeconnect = {
        enable = true;
        package = pkgs.valent;
      };

      home-manager.users.${username} = {
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
    };
}
