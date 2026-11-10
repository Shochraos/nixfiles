{
  den.aspects.remote-mounts =
    { user, ... }:
    {
      nixos =
        {
          config,
          lib,
          ...
        }:
        let
          shares = [
            "appdata"
            "backups"
            "data"
            "misc"
            "projects"
          ];
        in
        {
          assertions = [
            {
              assertion = !config.sops.useSystemdActivation;
              message = "Astaroth SMB mount drop-ins require SOPS installation during activation, before systemd loads mount units.";
            }
          ];

          sops.secrets = {
            "astaroth/smb-username" = { };
            "astaroth/smb-password" = { };
            "network/home-domain" = { };
          };

          sops.templates = {
            "astaroth-smb-credentials" = {
              owner = "root";
              group = "root";
              mode = "0400";
              content = ''
                username=${config.sops.placeholder."astaroth/smb-username"}
                password=${config.sops.placeholder."astaroth/smb-password"}
              '';
            };
          }
          // builtins.listToAttrs (
            map (
              share:
              lib.nameValuePair "astaroth-smb-${share}" {
                path = "/run/systemd/system/mnt-astaroth-${share}.mount.d/50-hostname.conf";
                owner = "root";
                group = "root";
                mode = "0400";
                content = ''
                  [Mount]
                  What=//astaroth.${config.sops.placeholder."network/home-domain"}/${share}
                '';
              }
            ) shares
          );

          fileSystems = builtins.listToAttrs (
            map (
              share:
              lib.nameValuePair "/mnt/astaroth/${share}" {
                device = "//astaroth/${share}";
                fsType = "cifs";
                options = [
                  "_netdev"
                  "nodev"
                  "nofail"
                  "nosuid"
                  "noexec"
                  "x-systemd.automount"
                  "x-systemd.idle-timeout=5min"
                  "x-systemd.mount-timeout=30s"
                  "credentials=${config.sops.templates."astaroth-smb-credentials".path}"
                  "uid=${user.name}"
                  "gid=${config.users.users.${user.name}.group}"
                  "file_mode=0600"
                  "dir_mode=0700"
                  "vers=3.1.1"
                  "seal"
                  "cache=strict"
                ];
              }
            ) shares
          );
        };
    };
}
