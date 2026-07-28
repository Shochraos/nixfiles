{
  den.aspects.remote-mounts.nixos =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        rclone
        rsync
      ];
      sops.secrets."astaroth/ip" = { };

      sops.templates."rclone-mnt.conf".content = ''
        [astaroth]
        type = sftp
        host = ${config.sops.placeholder."astaroth/ip"}
        user = root
        key_file = ${config.host.sshKey}
      '';

      fileSystems = lib.listToAttrs (
        map
          (
            share:
            lib.nameValuePair "/mnt/astaroth/${share}" {
              device = "astaroth:/mnt/user/${share}";
              fsType = "rclone";
              options = [
                "nodev"
                "nofail"
                "allow_other"
                "args2env"
                "config=${config.sops.templates."rclone-mnt.conf".path}"
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
}
