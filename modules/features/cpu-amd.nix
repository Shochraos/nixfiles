{
  den.aspects.cpu-amd =
    { user, ... }:
    {
      nixos =
        { pkgs, ... }:
        {
          users.groups.power_c = { };
          users.groups.power_c.members = [ user.name ];

          services.udev.extraRules = ''SUBSYSTEM=="powercap", KERNEL=="intel-rapl:0", RUN+="${pkgs.coreutils}/bin/chgrp power_c /sys/%p/energy_uj", RUN+="${pkgs.coreutils}/bin/chmod g+r /sys/%p/energy_uj"'';
        };
    };
}
