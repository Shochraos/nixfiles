{
  den.aspects.network =
    { host, ... }:
    {
      nixos = {
        networking.networkmanager.enable = true;
        networking.hostName = host.name;
        networking.firewall.enable = true;
      };
      security.pki.caCertificateBlacklist = [
        "Comodo AAA Services root"
        "emSign ECC Root CA - G3"
        "emSign Root CA - C1"
        "emSign ECC Root CA - C3"
      ];
    };
}
