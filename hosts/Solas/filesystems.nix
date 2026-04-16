{ ... }:
{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/f9880bef-0450-49c6-a537-40d11cb91550";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1C11-16D2";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/a23ee2d4-d8cd-4e89-9083-a4a93148b8a5"; }
  ];
}
