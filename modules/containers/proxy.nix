{ ... }:
let
  containerName = "proxy";
  containerDir = "/var/lib/containers/proxy";
in
{
  aspects.containers.${containerName} =
    { config, ... }:
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      virtualisation.quadlet.containers.nginx = {
        containerConfig = {
          image = "jlesage/nginx-proxy-manager:latest";
          networks = [ networks.internal.ref ];
          volumes = [ "${containerDir}/config:/config" ];
          environments = {
            USER_ID = "0";
            GROUP_ID = "0";
            UMASK = "0000";
            DISABLE_IPV6 = "1";
          };
          publishPorts = [ "80:8080" "81:8181" "443:4443" ];
        };
        serviceConfig.TimeoutStartSec = "60";
      };
    };
}
