{ inputs, config, ... }:
let
  inherit (config) assets;
in
{
  den.aspects.mic-mute.provides.to-users.homeManager =
    { lib, pkgs, ... }:
    let
      mic-mute = pkgs.writeShellApplication {
        name = "mic-mute";
        runtimeInputs = [
          inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.wireplumber
        ];
        text = builtins.readFile assets.micMuteScript;
      };
    in
    {
      systemd.user.services.micmute-led = {
        Unit = {
          Description = "Sync mic mute status with keyboard LED";
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          Type = "simple";
          ExecStart = lib.getExe mic-mute;
          Restart = "always";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
