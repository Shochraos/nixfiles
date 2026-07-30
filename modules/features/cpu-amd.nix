{
  den.aspects.cpu-amd =
    { user, ... }:
    {
      nixos =
        { lib, pkgs, ... }:
        let
          chgrp = lib.getExe' pkgs.coreutils "chgrp";
          chmod = lib.getExe' pkgs.coreutils "chmod";
        in
        {
          users.groups.power_c.members = [ user.name ];

          services.udev.extraRules = ''SUBSYSTEM=="powercap", KERNEL=="intel-rapl:0", RUN+="${chgrp} power_c /sys/%p/energy_uj", RUN+="${chmod} g+r /sys/%p/energy_uj"'';
        };
    };
}
