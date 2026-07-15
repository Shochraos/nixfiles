{
  den.aspects.mic-mute.provides.to-users.homeManager =
    { pkgs, ... }:
    let
      mic-mute = pkgs.writeShellScript "mic-mute.sh" (builtins.readFile ../../assets/scripts/mic-mute.sh);
    in
    {
      systemd.user.services.micmute-led = {
        Unit = {
          Description = "Sync mic mute status with keyboard LED";
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          Type = "simple";
          ExecStart = "${mic-mute}";
          Restart = "always";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
