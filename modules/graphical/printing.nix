{
  den.aspects.printing = _: {
    nixos =
      { pkgs, ... }:
      {
        services = {
          printing.enable = true;
          avahi = {
            enable = true;
            nssmdns4 = true;
            openFirewall = true;
          };
        };

        hardware.sane.enable = true;

        users.groups.lp.members = [ "shochraos" ];
        users.groups.scanner.members = [ "shochraos" ];

        environment.systemPackages = with pkgs; [
          simple-scan
        ];
      };
  };
}
