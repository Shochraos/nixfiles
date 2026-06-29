{ ... }:
let
  containerName = "immich";
  containerDir = "/mnt/containers/immich";
in
{
  aspects.nixos.${containerName} =
    { config, ... }:
    let
      inherit (config.virtualisation.quadlet) networks pods;
      volumeDirs = [ "apps" "config" "data" "logs" "postgres" "valkey" ];
    in
    {
      systemd.tmpfiles.settings."10-${containerName}" = builtins.listToAttrs (
        map (d: {
          name = "${containerDir}/${d}";
          value.d = {
            user = "700";
            group = "700";
            mode = "0750";
          };
        }) volumeDirs
      );

      virtualisation.quadlet.pods.immichStack.podConfig = {
        networks = [ networks.internal.ref ];
        networkAliases = [ "immich" ];
      };

      virtualisation.quadlet.containers = {
        immich = {
          containerConfig = {
            image = "ghcr.io/imagegenius/immich:latest";
            pod = pods.immichStack.ref;

            volumes = [
              "${containerDir}:/config"
              #Testing, set to real data storage later
              "${containerDir}/data:/photos"
            ];

            environments = { 
              PUID = "700"; 
              GUID = "700";

              SERVER_PORT = "8080";

              DB_HOSTNAME = "localhost";
              DB_USERNAME = "test";
              DB_PASSWORD = "test";
              DB_DATABASE_NAME = "db";
              DB_PORT = "5432";

              REDIS_HOSTNAME = "localhost";
              REDIS_PASSWORD = "";
              REDIS_PORT = "6379";
            };
          };
          serviceConfig.TimeoutStartSec = "60";
        };

        postgres-im = {
          containerConfig = {
            image = "ghcr.io/immich-app/postgres:16-vectorchord0.3.0-pgvectors0.3.0";
            pod = pods.immichStack.ref;

            volumes = [
              "${containerDir}/postgres:/var/lib/postgresql/data"
            ];

            user = "700:700";

            environments = {
              POSTGRES_USER = "test";
              POSTGRES_PASSWORD = "test";
              POSTGRES_DB = "db";
            };
          };
          serviceConfig.TimeoutStartSec = "60";
        };

        valkey-im = {
          containerConfig = {
            image = "docker.io/valkey/valkey";
            pod = pods.immichStack.ref;

            volumes = [
              "${containerDir}/valkey:/data"
            ];

            user = "700:700";
            notify = true;
            exec = "valkey-server --supervised systemd";
            environments = {
              VALKEY_EXTRA_FLAGS = "--appendonly yes --auto-aof-rewrite-percentage 100 --auto-aof-rewrite-min-size 64mb";
            };
          };
          serviceConfig.TimeoutStartSec = "60";
        };
      };

    };
}
