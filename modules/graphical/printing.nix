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
              openFirewall = false;
            };
          };

          hardware.sane.enable = true;

          host.network.homeOnlyPorts = {
            tcp.ports = [
              631
              6566
            ];
            udp.ports = [
              631
              5353
            ];
          };

          users.groups.lp.members = [ user.name ];
          users.groups.scanner.members = [ user.name ];

          environment.systemPackages = with pkgs; [
            simple-scan
          ];
        };
    };
}
