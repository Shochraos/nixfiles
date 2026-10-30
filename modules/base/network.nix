{
  den.aspects.network =
    { host, user, ... }:
    {
      nixos =
        { config, lib, ... }:
        let
          ssh = config.host.ssh;
        in
        {
          networking.networkmanager.enable = true;
          systemd.services.NetworkManager-wait-online.enable = false;
          networking.hostName = host.name;
          networking.firewall.enable = true;

          services.openssh = {
            enable = true;
            openFirewall = false;

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

          networking.firewall.interfaces =
            lib.genAttrs (map (pattern: lib.replaceStrings [ "*" ] [ "+" ] pattern) ssh.firewallInterfaces)
              (_: {
                allowedTCPPorts = [ 22 ];
              });
        };

      security.pki.caCertificateBlacklist = [
        "Comodo AAA Services root"
        "emSign ECC Root CA - G3"
        "emSign Root CA - C1"
        "emSign ECC Root CA - C3"
      ];
    };
}
