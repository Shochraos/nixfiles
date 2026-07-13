{
  aspects.nixos.wireguard =
    { config, ... }:
    {
      sops.secrets."wireguard/private-key" = { };

      sops.templates."wireguard.env".content = ''
        WG_PRIVATE_KEY=${config.sops.placeholder."wireguard/private-key"}
      '';

      networking.networkmanager.ensureProfiles = {
        environmentFiles = [ config.sops.templates."wireguard.env".path ];

        profiles.wg0 = {
          connection = {
            id = "wg0";
            type = "wireguard";
            interface-name = "wg0";
            autoconnect = false;
          };

          wireguard.private-key = "$WG_PRIVATE_KEY";

          "wireguard-peer.SERVER_PUBLIC_KEY" = {
            endpoint = "vpn.example.com:51820";
            allowed-ips = "0.0.0.0/0;";
            persistent-keepalive = "25";
          };

          ipv4 = {
            method = "manual";
            address1 = "10.0.0.2/24";
          };

          ipv6.method = "disabled";
        };
      };
    };
}
