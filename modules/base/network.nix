{ lib, ... }:
{
  den.aspects.network =
    { host, ... }:
    {
      nixos = {
        networking.hostName = host.name;
        networking.firewall.enable = true;
        networking.networkmanager.enable = true;

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
