{ ... }:
{
  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true;

  systemd.mounts = let commonMountOptions = {
    type = "nfs";
    mountConfig = {
      Options = "noatime";
    };
  };

  in

  [
    (commonMountOptions // {
      what = "192.168.10.2:/mnt/user/appdata";
      where = "/mnt/astaroth/appdata";
    })

    (commonMountOptions // {
      what = "192.168.10.2:/mnt/user/backups";
      where = "/mnt/astaroth/backups";
    })
    
    (commonMountOptions // {
      what = "192.168.10.2:/mnt/user/data";
      where = "/mnt/astaroth/data";
    })
    
    (commonMountOptions // {
      what = "192.168.10.2:/mnt/user/misc";
      where = "/mnt/astaroth/misc";
    })
  ];

  systemd.automounts = let commonAutoMountOptions = {
    wantedBy = [ "multi-user.target" ];
    automountConfig = {
      TimeoutIdleSec = "600";
    };
  };
  in
  [
    (commonAutoMountOptions // { where = "/mnt/astaroth/appdata"; })
    (commonAutoMountOptions // { where = "/mnt/astaroth/backups"; })
    (commonAutoMountOptions // { where = "/mnt/astaroth/data"; })
    (commonAutoMountOptions // { where = "/mnt/astaroth/misc"; })
  ];
}