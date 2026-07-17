{
  den.aspects.remote-mounts =
    { host, user, ... }:
    {
      nixos =
        { pkgs, lib, ... }:
        {
          environment.systemPackages = with pkgs; [
            rclone
            rsync
          ];
          environment.etc."rclone-mnt.conf".text = ''
            [astaroth]
            type = sftp
            host = 192.168.10.2
            user = root
            key_file = /home/${user.name}/.ssh/${lib.toLower host.name}
          '';

          fileSystems = lib.listToAttrs (
            map
              (share:
                lib.nameValuePair "/mnt/astaroth/${share}" {
                  device = "astaroth:/mnt/user/${share}";
                  fsType = "rclone";
                  options = [
                    "nodev"
                    "nofail"
                    "allow_other"
                    "args2env"
                    "config=/etc/rclone-mnt.conf"
                  ];
                }
              )
              [
                "appdata"
                "backups"
                "data"
                "misc"
              ]
          );
        };
    };
}
