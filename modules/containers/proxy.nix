{ ... }:
let
  containerName = "proxy";
  containerDir = "/var/lib/containers/proxy";
  containerUser = "containerUser";
in
{
  aspects.nixos.${containerName} = {
    systemd.tmpfiles.settings."10-${containerName}".${containerDir}.d = {
      user = containerUser;
      group = containerUser;
      mode = "0750";
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    # testing
    networking.hosts = {
      "127.0.0.1" = [ "test.local" "npm.local" ];
    };
  };

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
          volumes = [ "${containerDir}:/config" ];
          environments = {
            USER_ID = "0";
            GROUP_ID = "0";
            UMASK = "0000";
            DISABLE_IPV6 = "1";
          };
          publishPorts = [ "80:8080" "443:4443" ];
        };
        serviceConfig.TimeoutStartSec = "60";
      };
    };
}
