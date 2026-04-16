{ pkgs, ... }:
{
  programs.kdeconnect = {
    enable = true;
    package = pkgs.valent;
  };

  systemd.user.services.valent = {
    description = "Valent (KDE Connect Implementation)";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.valent}/bin/valent --gapplication-service";
      Restart = "on-failure";
    };
  };
}
