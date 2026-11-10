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
        {
          sops.secrets = {
            "astaroth/smb-username" = { };
            "astaroth/smb-password" = { };
          };

          sops.templates."astaroth-smb-credentials" = {
            owner = "root";
            group = "root";
            mode = "0400";
            content = ''
              username=${config.sops.placeholder."astaroth/smb-username"}
              password=${config.sops.placeholder."astaroth/smb-password"}
            '';
          };

          fileSystems = builtins.listToAttrs (
            map
              (
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
              )
              [
                "appdata"
                "backups"
                "data"
                "misc"
                "projects"
              ]
          );
        };
    };
}
