{
  den.aspects.network =
    { host, user, ... }:
    {
      nixos =
        {
          config,
          lib,
          ...
        }:
        let
          ssh = config.host.ssh;
          sshEnabled = ssh.authorizedKeys != [ ];
        in
        {
          networking.networkmanager.enable = true;

          networking.hostName = host.name;
          networking.firewall.enable = true;

          services.openssh = {
            enable = sshEnabled;
            openFirewall = false;
            authorizedKeysInHomedir = false;

            settings = {
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;
              PermitRootLogin = "no";
              AllowUsers = [ user.name ];
              MaxAuthTries = 3;
              LoginGraceTime = 20;
            };
          };

          users.users.${user.name}.openssh.authorizedKeys.keys = ssh.authorizedKeys;

          networking.firewall.interfaces = lib.mkIf sshEnabled (
            lib.genAttrs
              (map (
                pattern:
                if config.networking.firewall.backend == "iptables" then
                  lib.replaceStrings [ "*" ] [ "+" ] pattern
                else
                  pattern
              ) ssh.firewallInterfaces)
              (_: {
                allowedTCPPorts = [ 22 ];
              })
          );
        };
    };
}
