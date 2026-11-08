{ lib, ... }:
{
  den.aspects.network =
    { host, ... }:
    {
      nixos = {
        networking.hostName = host.name;
        networking.firewall.enable = true;
        networking.networkmanager.enable = true;

        services.resolved.enable = lib.mkDefault true;
        services.timesyncd = {
          enable = true;
          servers = [
            "162.159.200.1"
            "162.159.200.123"
            "2606:4700:f1::1"
            "2606:4700:f1::123"
          ];
          fallbackServers = [ ];
        };

        services.openssh = {
          openFirewall = lib.mkDefault false;
          authorizedKeysInHomedir = false;
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = "no";
            MaxAuthTries = 3;
            LoginGraceTime = 20;
          };
        };
      };

      provides.to-users.nixos =
        { user, ... }:
        {
          users.users.${user.name}.extraGroups = [ "networkmanager" ];
        };
    };
}
