{
  den.aspects.printing =
    { user, ... }:
    {
      nixos =
        { pkgs, ... }:
        {
          services = {
            printing.enable = true;
            avahi = {
              enable = true;
              nssmdns4 = true;
            };
          };

          hardware.sane.enable = true;

          users.groups.lp.members = [ user.name ];
          users.groups.scanner.members = [ user.name ];

          environment.systemPackages = with pkgs; [
            simple-scan
          ];
        };
    };
}
