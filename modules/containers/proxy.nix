{ ... }:
let
  containerName = "proxy";
  containerDir = "/mnt/containers/proxy";
in
{
  aspects.nixos.${containerName} =
    { config, ... }:
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      systemd.tmpfiles.settings."10-${containerName}".${containerDir}.d = {
        user = "root";
        group = "root";
        mode = "0750";
      };

      networking.firewall.allowedTCPPorts = [ 80 443 ];

      # testing
      networking.hosts = {
        "127.0.0.1" = [ "npm.local" "cloud.local" "immich.local" ];
      };

      virtualisation.quadlet.containers.nginx = {
        containerConfig = {
          image = "jlesage/nginx-proxy-manager:latest";
          networks = [ networks.internal.ref ];
          volumes = [ "${containerDir}:/config:U" ];
          environments = {
            USER_ID = "0";
            GROUP_ID = "0";
            DISABLE_IPV6 = "1";
          };
          publishPorts = [ "80:8080" "81:8181" "443:4443" ];
        };
        serviceConfig.TimeoutStartSec = "60";
      };
    };
}
