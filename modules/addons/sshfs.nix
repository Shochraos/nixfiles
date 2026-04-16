{
  pkgs,
  lib,
  username,
  systemname,
  ...
}:
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
    key_file = /home/${username}/.ssh/${lib.toLower systemname}
  '';

  fileSystems."/mnt/astaroth/appdata" = {
    device = "astaroth:/mnt/user/appdata";
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      "config=/etc/rclone-mnt.conf"
    ];
  };

  fileSystems."/mnt/astaroth/backups" = {
    device = "astaroth:/mnt/user/backups";
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      "config=/etc/rclone-mnt.conf"
    ];
  };

  fileSystems."/mnt/astaroth/data" = {
    device = "astaroth:/mnt/user/data";
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      "config=/etc/rclone-mnt.conf"
    ];
  };

  fileSystems."/mnt/astaroth/misc" = {
    device = "astaroth:/mnt/user/misc";
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      "config=/etc/rclone-mnt.conf"
    ];
  };
}
