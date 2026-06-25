{ ... }:
let
  containerName = "nextcloud";
  containerDir = "/var/lib/containers/nextcloud";
in
{
  aspects.nixos.${containerName} =
    { config, ... }:
    let
      inherit (config.virtualisation.quadlet) networks pods;
      volumeDirs = [ "html" "apps" "config" "data" "logs" "postgres" "redis" ];
    in
    {
      systemd.tmpfiles.settings."10-${containerName}" = builtins.listToAttrs (
        map (d: {
          name = "${containerDir}/${d}";
          value.d = {
            user = "root";
            group = "root";
            mode = "0750";
          };
        }) volumeDirs
      );

      virtualisation.quadlet.pods.nextcloudStack.podConfig = {
        networks = [ networks.internal.ref ];
        networkAliases = [ "nextcloud" ];
      };

      virtualisation.quadlet.containers = {
        nextcloud = {
          containerConfig = {
            image = "docker.io/library/nextcloud:latest";
            pod = pods.nextcloudStack.ref;

            volumes = [
              "${containerDir}/html:/var/www/html"
              "${containerDir}/apps:/var/www/html/custom_apps"
              "${containerDir}/config:/var/www/html/config"
              #Testing, set to real data storage later
              "${containerDir}/data:/data"
              "${containerDir}/logs:/var/log"
            ];
          };
          serviceConfig.TimeoutStartSec = "60";
        };

        postgres = {
          containerConfig = {
            image = "docker.io/library/postgres:15";
            pod = pods.nextcloudStack.ref;

            volumes = [
              "${containerDir}/postgres:/var/lib/postgresql/data"
            ];

            environments = {
              POSTGRES_USER = "test";
              POSTGRES_PASSWORD = "test";
              POSTGRES_DB = "db";
            };
          };
          serviceConfig.TimeoutStartSec = "60";
        };

        redis = {
          containerConfig = {
            image = "docker.io/bitnami/redis:latest";
            pod = pods.nextcloudStack.ref;

            volumes = [
              "${containerDir}/redis:/bitnami/redis:idmap=uids=0-1001-1"
            ];

            environments = {
              ALLOW_EMPTY_PASSWORD = "no";
              REDIS_PASSWORD = "test";
              REDIS_EXTRA_FLAGS = "--auto-aof-rewrite-percentage 100 --auto-aof-rewrite-min-size 64mb";
            };
          };
          serviceConfig.TimeoutStartSec = "60";
        };
      };

    };
}
